from django.contrib import admin
from .models import Category, Material, Student, BorrowTransaction, BorrowedItem, PDFRecord


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'parent', 'material_type', 'description', 'created_at']
    list_filter = ['material_type', 'parent']
    search_fields = ['name']
    raw_id_fields = ['parent']


@admin.register(Material)
class MaterialAdmin(admin.ModelAdmin):
    list_display = ['name', 'category', 'total_quantity', 'available_quantity', 'borrowed_quantity']
    list_filter = ['category']
    search_fields = ['name', 'description']
    readonly_fields = ['borrowed_quantity']


@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ['full_name', 'id_card_number', 'phone_number', 'email']
    search_fields = ['full_name', 'id_card_number', 'phone_number']


class BorrowedItemInline(admin.TabularInline):
    model = BorrowedItem
    extra = 1
    readonly_fields = ['created_at']


@admin.register(BorrowTransaction)
class BorrowTransactionAdmin(admin.ModelAdmin):
    list_display = ['id', 'student', 'borrow_date', 'status', 'expected_return_date']
    list_filter = ['status', 'borrow_date']
    search_fields = ['student__full_name', 'student__id_card_number']
    readonly_fields = ['created_at', 'updated_at']
    inlines = [BorrowedItemInline]


@admin.register(PDFRecord)
class PDFRecordAdmin(admin.ModelAdmin):
    list_display = ['transaction', 'is_signed', 'signature_date', 'generated_at']
    list_filter = ['is_signed', 'generated_at']
    readonly_fields = ['generated_at', 'updated_at']
