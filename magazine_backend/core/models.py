from django.db import models
from django.core.validators import MinValueValidator
from django.utils import timezone


class Category(models.Model):
    """Material categories (e.g., Sensors, ICs, Tools, Power Components)"""
    MATERIAL_TYPE_CHOICES = [
        ('FABLAB', 'FabLab'),
        ('STCB', 'STCB Club'),
    ]
    
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    material_type = models.CharField(max_length=10, choices=MATERIAL_TYPE_CHOICES, default='FABLAB')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Categories"
        ordering = ['name']

    def __str__(self):
        return self.name


class Material(models.Model):
    """Individual materials with inventory tracking"""
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='materials')
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    image = models.ImageField(upload_to='materials/', blank=True, null=True)
    total_quantity = models.IntegerField(validators=[MinValueValidator(0)], default=0)
    available_quantity = models.IntegerField(validators=[MinValueValidator(0)], default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['category', 'name']
        unique_together = ['category', 'name']

    def __str__(self):
        return f"{self.name} ({self.category.name})"

    @property
    def borrowed_quantity(self):
        """Calculate currently borrowed quantity"""
        return self.total_quantity - self.available_quantity


class Student(models.Model):
    """Student information"""
    full_name = models.CharField(max_length=200)
    phone_number = models.CharField(max_length=20)
    id_card_number = models.CharField(max_length=50, unique=True)
    email = models.EmailField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['full_name']

    def __str__(self):
        return f"{self.full_name} ({self.id_card_number})"


class Group(models.Model):
    """Project groups containing one or more students"""
    name = models.CharField(max_length=200, unique=True)
    students = models.ManyToManyField(Student, related_name='groups')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class BorrowTransaction(models.Model):
    """Borrowing transaction record"""
    STATUS_CHOICES = [
        ('BORROWED', 'Borrowed'),
        ('RETURNED', 'Returned'),
        ('PARTIALLY_RETURNED', 'Partially Returned'),
    ]

    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name='transactions', null=True, blank=True)
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='transactions', null=True, blank=True)
    borrow_date = models.DateTimeField(default=timezone.now)
    expected_return_date = models.DateField(blank=True, null=True)
    actual_return_date = models.DateTimeField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='BORROWED')
    notes = models.TextField(blank=True, help_text="Additional notes or conditions")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-borrow_date']

    def __str__(self):
        name = self.group.name if self.group else (self.student.full_name if self.student else "Unknown")
        return f"{name} - {self.borrow_date.strftime('%Y-%m-%d')} ({self.status})"

    def update_status(self):
        """Update transaction status based on borrowed items"""
        items = self.borrowed_items.all()
        if not items.exists():
            return
        
        all_returned = all(item.quantity_returned >= item.quantity_borrowed for item in items)
        any_returned = any(item.quantity_returned > 0 for item in items)
        
        if all_returned:
            self.status = 'RETURNED'
            if not self.actual_return_date:
                self.actual_return_date = timezone.now()
        elif any_returned:
            self.status = 'PARTIALLY_RETURNED'
        else:
            self.status = 'BORROWED'
        
        self.save()


class BorrowedItem(models.Model):
    """Individual items in a borrowing transaction"""
    transaction = models.ForeignKey(BorrowTransaction, on_delete=models.CASCADE, related_name='borrowed_items')
    material = models.ForeignKey(Material, on_delete=models.CASCADE, related_name='borrowed_in')
    quantity_borrowed = models.IntegerField(validators=[MinValueValidator(1)])
    quantity_returned = models.IntegerField(validators=[MinValueValidator(0)], default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['transaction', 'material']

    def __str__(self):
        return f"{self.material.name} x{self.quantity_borrowed} (Returned: {self.quantity_returned})"

    @property
    def is_fully_returned(self):
        return self.quantity_returned >= self.quantity_borrowed


class PDFRecord(models.Model):
    """PDF document metadata and storage"""
    transaction = models.OneToOneField(BorrowTransaction, on_delete=models.CASCADE, related_name='pdf_record')
    file_path = models.CharField(max_length=500, help_text="Path to the PDF file")
    is_signed = models.BooleanField(default=False)
    signature_image = models.ImageField(upload_to='signatures/', blank=True, null=True)
    signature_date = models.DateTimeField(blank=True, null=True)
    generated_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-generated_at']

    def __str__(self):
        return f"PDF for {self.transaction} - {'Signed' if self.is_signed else 'Unsigned'}"
