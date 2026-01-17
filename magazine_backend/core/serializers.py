from rest_framework import serializers
from .models import Category, Material, Student, BorrowTransaction, BorrowedItem, PDFRecord, Group


class CategorySerializer(serializers.ModelSerializer):
    materials_count = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'material_type', 'materials_count', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']

    def get_materials_count(self, obj):
        return obj.materials.count()


class MaterialSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    borrowed_quantity = serializers.ReadOnlyField()

    class Meta:
        model = Material
        fields = [
            'id', 'category', 'category_name', 'name', 'description', 
            'image', 'total_quantity', 'available_quantity', 'borrowed_quantity',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']

    def validate(self, data):
        """Ensure available quantity doesn't exceed total quantity"""
        total = data.get('total_quantity', 0)
        available = data.get('available_quantity', 0)
        
        if available > total:
            raise serializers.ValidationError(
                "Available quantity cannot exceed total quantity"
            )
        
        return data


class StudentSerializer(serializers.ModelSerializer):
    transactions_count = serializers.SerializerMethodField()

    class Meta:
        model = Student
        fields = [
            'id', 'full_name', 'phone_number', 'id_card_number', 
            'email', 'transactions_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']

    def get_transactions_count(self, obj):
        return obj.transactions.count()


class BorrowedItemSerializer(serializers.ModelSerializer):
    material_name = serializers.CharField(source='material.name', read_only=True)
    category_name = serializers.CharField(source='material.category.name', read_only=True)
    is_fully_returned = serializers.ReadOnlyField()

    class Meta:
        model = BorrowedItem
        fields = [
            'id', 'material', 'material_name', 'category_name',
            'quantity_borrowed', 'quantity_returned', 'is_fully_returned',
            'created_at'
        ]
        read_only_fields = ['created_at']

    def validate(self, data):
        """Validate borrowed quantity against available inventory"""
        material = data.get('material')
        quantity_borrowed = data.get('quantity_borrowed', 0)
        quantity_returned = data.get('quantity_returned', 0)

        # Check if we're creating a new item or updating
        if not self.instance:
            # Creating new borrowed item
            if quantity_borrowed > material.available_quantity:
                raise serializers.ValidationError({
                    'quantity_borrowed': f"Only {material.available_quantity} units available"
                })

        # Validate returned quantity
        if quantity_returned > quantity_borrowed:
            raise serializers.ValidationError({
                'quantity_returned': "Returned quantity cannot exceed borrowed quantity"
            })

        return data


class GroupSerializer(serializers.ModelSerializer):
    student_ids = serializers.PrimaryKeyRelatedField(
        many=True, 
        queryset=Student.objects.all(), 
        source='students',
        write_only=True
    )
    students = StudentSerializer(many=True, read_only=True)
    transactions_count = serializers.SerializerMethodField()

    class Meta:
        model = Group
        fields = ['id', 'name', 'students', 'student_ids', 'transactions_count', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']

    def get_transactions_count(self, obj):
        return obj.transactions.count()


class BorrowTransactionSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source='student.full_name', read_only=True)
    student_id_card = serializers.CharField(source='student.id_card_number', read_only=True)
    group_name = serializers.CharField(source='group.name', read_only=True)
    group_members = serializers.SerializerMethodField()
    borrowed_items = BorrowedItemSerializer(many=True, read_only=True)
    has_pdf = serializers.SerializerMethodField()

    class Meta:
        model = BorrowTransaction
        fields = [
            'id', 'student', 'student_name', 'student_id_card',
            'group', 'group_name', 'group_members',
            'borrow_date', 'expected_return_date', 'actual_return_date',
            'status', 'notes', 'borrowed_items', 'has_pdf',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at', 'status']

    def get_group_members(self, obj):
        if obj.group:
            return obj.group.students.values_list('full_name', flat=True)
        return []

    def get_has_pdf(self, obj):
        return hasattr(obj, 'pdf_record')


class BorrowTransactionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating transactions with borrowed items"""
    items = serializers.ListField(
        child=serializers.DictField(),
        write_only=True,
        help_text="List of items with material_id and quantity_borrowed"
    )

    class Meta:
        model = BorrowTransaction
        fields = [
            'student', 'group', 'borrow_date', 'expected_return_date', 
            'notes', 'items'
        ]

    def validate(self, data):
        """Ensure either student or group is provided, but not both (or prioritize group)"""
        if not data.get('student') and not data.get('group'):
            raise serializers.ValidationError("Either a Student or a Group is required.")
        return data

    def validate_items(self, items):
        """Validate all items have required fields and sufficient inventory"""
        if not items:
            raise serializers.ValidationError("At least one item is required")

        for item in items:
            if 'material_id' not in item or 'quantity_borrowed' not in item:
                raise serializers.ValidationError(
                    "Each item must have 'material_id' and 'quantity_borrowed'"
                )

            try:
                material = Material.objects.get(id=item['material_id'])
                quantity = int(item['quantity_borrowed'])
                
                if quantity <= 0:
                    raise serializers.ValidationError(
                        f"Quantity must be positive for {material.name}"
                    )
                
                if quantity > material.available_quantity:
                    raise serializers.ValidationError(
                        f"Only {material.available_quantity} units of {material.name} available"
                    )
            except Material.DoesNotExist:
                raise serializers.ValidationError(
                    f"Material with id {item['material_id']} does not exist"
                )
            except (ValueError, TypeError):
                raise serializers.ValidationError(
                    "quantity_borrowed must be a valid integer"
                )

        return items

    def create(self, validated_data):
        """Create transaction and borrowed items"""
        items_data = validated_data.pop('items')
        transaction = BorrowTransaction.objects.create(**validated_data)

        for item_data in items_data:
            BorrowedItem.objects.create(
                transaction=transaction,
                material_id=item_data['material_id'],
                quantity_borrowed=item_data['quantity_borrowed']
            )

        return transaction


class PDFRecordSerializer(serializers.ModelSerializer):
    transaction_details = BorrowTransactionSerializer(source='transaction', read_only=True)

    class Meta:
        model = PDFRecord
        fields = [
            'id', 'transaction', 'transaction_details', 'file_path',
            'is_signed', 'signature_image', 'signature_date',
            'generated_at', 'updated_at'
        ]
        read_only_fields = ['generated_at', 'updated_at']
