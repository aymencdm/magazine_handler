from django.db.models.signals import post_save, post_delete, pre_save
from django.dispatch import receiver
from .models import BorrowedItem, Material


@receiver(pre_save, sender=BorrowedItem)
def store_old_borrowed_item(sender, instance, **kwargs):
    """Store the old state of the borrowed item before saving"""
    if instance.pk:
        try:
            instance._old_instance = BorrowedItem.objects.get(pk=instance.pk)
        except BorrowedItem.DoesNotExist:
            instance._old_instance = None
    else:
        instance._old_instance = None


@receiver(post_save, sender=BorrowedItem)
def handle_borrowed_item_save(sender, instance, created, **kwargs):
    """Update material inventory and transaction status on save"""
    material = instance.material
    
    if created:
        # New item: Decrease inventory by total borrowed
        material.available_quantity -= instance.quantity_borrowed
        material.save()
        print(f"DEBUG [Signal]: New item {instance.id}. Inventory decreased by {instance.quantity_borrowed}", flush=True)
    else:
        # Existing item: Check for changes in quantity_borrowed or quantity_returned
        old = getattr(instance, '_old_instance', None)
        if old:
            # 1. Handle changes in quantity_borrowed (though rare)
            borrowed_diff = instance.quantity_borrowed - old.quantity_borrowed
            if borrowed_diff != 0:
                material.available_quantity -= borrowed_diff
                material.save()
                print(f"DEBUG [Signal]: Borrowed qty changed. Inventory adjusted by {-borrowed_diff}", flush=True)

            # 2. Handle changes in quantity_returned
            returned_diff = instance.quantity_returned - old.quantity_returned
            if returned_diff != 0:
                material.available_quantity += returned_diff
                material.save()
                print(f"DEBUG [Signal]: Returned qty changed. Inventory increased by {returned_diff}", flush=True)

    # ALWAYS update the transaction status
    if instance.transaction:
        instance.transaction.update_status()
        print(f"DEBUG [Signal]: Updated status for Transaction {instance.transaction.id}", flush=True)


@receiver(post_delete, sender=BorrowedItem)
def handle_borrowed_item_delete(sender, instance, **kwargs):
    """Restore inventory when a borrowed item is deleted"""
    material = instance.material
    # Restore any items that were borrowed but NOT returned
    remaining = instance.quantity_borrowed - instance.quantity_returned
    if remaining > 0:
        material.available_quantity += remaining
        material.save()
        print(f"DEBUG [Signal]: Item deleted. Restored {remaining} to inventory.", flush=True)
    
    # Update status for the transaction (in case it still exists)
    if instance.transaction:
        try:
            instance.transaction.update_status()
        except Exception:
            pass
