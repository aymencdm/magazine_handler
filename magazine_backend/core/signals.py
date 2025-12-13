from django.db.models.signals import post_save, post_delete, pre_save
from django.dispatch import receiver
from .models import BorrowedItem, Material


@receiver(post_save, sender=BorrowedItem)
def update_inventory_on_borrow(sender, instance, created, **kwargs):
    """Update material inventory when items are borrowed or returned"""
    material = instance.material
    
    if created:
        # New borrowing - decrease available quantity
        material.available_quantity -= instance.quantity_borrowed
        material.save()
    else:
        # Returning items - increase available quantity
        # Calculate the change in returned quantity
        old_instance = BorrowedItem.objects.filter(pk=instance.pk).first()
        if old_instance:
            returned_diff = instance.quantity_returned - old_instance.quantity_returned
            if returned_diff > 0:
                material.available_quantity += returned_diff
                material.save()
    
    # Update transaction status
    instance.transaction.update_status()


@receiver(pre_save, sender=BorrowedItem)
def store_old_values(sender, instance, **kwargs):
    """Store old values before save for comparison"""
    if instance.pk:
        try:
            instance._old_instance = BorrowedItem.objects.get(pk=instance.pk)
        except BorrowedItem.DoesNotExist:
            instance._old_instance = None


@receiver(post_save, sender=BorrowedItem)
def update_inventory_on_return(sender, instance, created, **kwargs):
    """Update inventory when items are returned"""
    if not created and hasattr(instance, '_old_instance') and instance._old_instance:
        old_returned = instance._old_instance.quantity_returned
        new_returned = instance.quantity_returned
        
        if new_returned > old_returned:
            # Items were returned
            returned_diff = new_returned - old_returned
            material = instance.material
            material.available_quantity += returned_diff
            material.save()
            
            # Update transaction status
            instance.transaction.update_status()


@receiver(post_delete, sender=BorrowedItem)
def restore_inventory_on_delete(sender, instance, **kwargs):
    """Restore inventory if a borrowed item record is deleted"""
    material = instance.material
    unreturned_quantity = instance.quantity_borrowed - instance.quantity_returned
    material.available_quantity += unreturned_quantity
    material.save()
