from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from django.http import FileResponse, JsonResponse, HttpResponse
from django.conf import settings
from django.utils import timezone
from django.db import transaction
import os
import csv
import json
import openpyxl
import openpyxl
from io import BytesIO
import base64
from PIL import Image

from .models import Category, Material, Student, BorrowTransaction, BorrowedItem, PDFRecord, Group
from .serializers import (
    CategorySerializer, MaterialSerializer, StudentSerializer,
    BorrowTransactionSerializer, BorrowTransactionCreateSerializer,
    BorrowedItemSerializer, PDFRecordSerializer, GroupSerializer
)
from .pdf_generator import generate_borrowing_pdf, add_signature_to_pdf, generate_category_pdf, generate_all_categories_pdf


class CategoryViewSet(viewsets.ModelViewSet):
    """API endpoint for material categories"""
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        """Get categories filtered by material_type"""
        material_type = request.query_params.get('type')
        if material_type:
            categories = self.queryset.filter(material_type=material_type.upper())
            serializer = self.get_serializer(categories, many=True)
            return Response(serializer.data)
        return Response({'error': 'type parameter required (FABLAB or STCB)'}, status=400)

    @action(detail=True, methods=['post'])
    def generate_pdf(self, request, pk=None):
        """Generate PDF for a single category"""
        category = self.get_object()
        
        try:
            # Generate PDF
            pdf_path = generate_category_pdf(category)
            
            return Response({
                'message': 'PDF generated successfully',
                'pdf_path': pdf_path,
                'category_id': category.id,
                'category_name': category.name
            })
        
        except Exception as e:
            return Response({'error': str(e)}, status=500)

    @action(detail=True, methods=['get'])
    def export_pdf(self, request, pk=None):
        """Download PDF for a single category"""
        category = self.get_object()
        
        try:
            # Generate PDF on-the-fly
            pdf_path = generate_category_pdf(category)
            full_path = os.path.join(settings.MEDIA_ROOT, pdf_path)
            
            if not os.path.exists(full_path):
                return Response({'error': 'PDF file not found'}, status=404)
            
            return FileResponse(open(full_path, 'rb'), content_type='application/pdf')
        
        except Exception as e:
            return Response({'error': str(e)}, status=500)

    @action(detail=False, methods=['get'])
    def export_all_pdf(self, request):
        """Generate and download PDF for all categories"""
        try:
            # Generate PDF for all categories
            pdf_path = generate_all_categories_pdf()
            full_path = os.path.join(settings.MEDIA_ROOT, pdf_path)
            
            if not os.path.exists(full_path):
                return Response({'error': 'PDF file not found'}, status=404)
            
            return FileResponse(open(full_path, 'rb'), content_type='application/pdf')
        
        except Exception as e:
            return Response({'error': str(e)}, status=500)



class MaterialViewSet(viewsets.ModelViewSet):
    """API endpoint for materials"""
    queryset = Material.objects.select_related('category').all()
    serializer_class = MaterialSerializer

    @action(detail=False, methods=['get'])
    def by_category(self, request):
        """Get materials filtered by category"""
        category_id = request.query_params.get('category_id')
        if category_id:
            materials = self.queryset.filter(category_id=category_id)
            serializer = self.get_serializer(materials, many=True)
            return Response(serializer.data)
        return Response({'error': 'category_id parameter required'}, status=400)

    @action(detail=False, methods=['get'])
    def low_stock(self, request):
        """Get materials with low stock (available_quantity < 5)"""
        threshold = int(request.query_params.get('threshold', 5))
        materials = self.queryset.filter(available_quantity__lt=threshold)
        serializer = self.get_serializer(materials, many=True)
        return Response(serializer.data)


class GroupViewSet(viewsets.ModelViewSet):
    """API endpoint for project groups"""
    queryset = Group.objects.all().prefetch_related('students')
    serializer_class = GroupSerializer


class StudentViewSet(viewsets.ModelViewSet):
    """API endpoint for students"""
    queryset = Student.objects.all()
    serializer_class = StudentSerializer

    @action(detail=False, methods=['post'])
    def import_csv(self, request):
        """Import students from CSV file"""
        if 'file' not in request.FILES:
            return Response({'error': 'No file provided'}, status=400)

        file = request.FILES['file']
        
        try:
            # Read CSV file
            decoded_file = file.read().decode('utf-8').splitlines()
            reader = csv.DictReader(decoded_file)
            
            created_count = 0
            errors = []
            
            for row in reader:
                try:
                    Student.objects.create(
                        full_name=row.get('full_name', ''),
                        phone_number=row.get('phone_number', ''),
                        id_card_number=row.get('id_card_number', ''),
                        email=row.get('email', '')
                    )
                    created_count += 1
                except Exception as e:
                    errors.append(f"Row {reader.line_num}: {str(e)}")
            
            return Response({
                'created': created_count,
                'errors': errors
            })
        
        except Exception as e:
            return Response({'error': str(e)}, status=400)

    @action(detail=False, methods=['post'])
    def import_excel(self, request):
        """Import students from Excel file"""
        if 'file' not in request.FILES:
            return Response({'error': 'No file provided'}, status=400)

        file = request.FILES['file']
        
        try:
            workbook = openpyxl.load_workbook(file)
            sheet = workbook.active
            
            created_count = 0
            errors = []
            
            # Skip header row
            for idx, row in enumerate(sheet.iter_rows(min_row=2, values_only=True), start=2):
                try:
                    if row[0]:  # Check if full_name exists
                        Student.objects.create(
                            full_name=row[0] or '',
                            phone_number=row[1] or '',
                            id_card_number=row[2] or '',
                            email=row[3] or '' if len(row) > 3 else ''
                        )
                        created_count += 1
                except Exception as e:
                    errors.append(f"Row {idx}: {str(e)}")
            
            return Response({
                'created': created_count,
                'errors': errors
            })
        
        except Exception as e:
            return Response({'error': str(e)}, status=400)


class BorrowTransactionViewSet(viewsets.ModelViewSet):
    """API endpoint for borrow transactions"""
    queryset = BorrowTransaction.objects.select_related('student').prefetch_related('borrowed_items__material__category').all()
    
    def get_serializer_class(self):
        if self.action == 'create':
            return BorrowTransactionCreateSerializer
        return BorrowTransactionSerializer

    @action(detail=True, methods=['post'])
    def generate_pdf(self, request, pk=None):
        """Generate PDF for a transaction"""
        transaction = self.get_object()
        
        try:
            # Generate PDF
            pdf_path = generate_borrowing_pdf(transaction)
            
            # Create or update PDF record
            pdf_record, created = PDFRecord.objects.update_or_create(
                transaction=transaction,
                defaults={'file_path': pdf_path}
            )
            
            serializer = PDFRecordSerializer(pdf_record)
            return Response(serializer.data)
        
        except Exception as e:
            return Response({'error': str(e)}, status=500)

    @action(detail=True, methods=['post'])
    def add_signature(self, request, pk=None):
        """Add signature to PDF"""
        transaction = self.get_object()
        
        if not hasattr(transaction, 'pdf_record'):
            return Response({'error': 'PDF not generated yet'}, status=400)
        
        # Get signature image from request
        signature_data = request.data.get('signature')
        if not signature_data:
            return Response({'error': 'No signature provided'}, status=400)
        
        try:
            # Save signature image
            signature_dir = os.path.join(settings.MEDIA_ROOT, 'signatures')
            os.makedirs(signature_dir, exist_ok=True)
            
            # Decode base64 image if provided
            if signature_data.startswith('data:image'):
                # Extract base64 data
                format, imgstr = signature_data.split(';base64,')
                ext = format.split('/')[-1]
                
                signature_filename = f"signature_{transaction.id}_{timezone.now().strftime('%Y%m%d_%H%M%S')}.{ext}"
                signature_path = os.path.join(signature_dir, signature_filename)
                
                # Decode and save
                img_data = base64.b64decode(imgstr)
                with open(signature_path, 'wb') as f:
                    f.write(img_data)
                
                # Update PDF record
                pdf_record = transaction.pdf_record
                pdf_record.signature_image = os.path.relpath(signature_path, settings.MEDIA_ROOT)
                pdf_record.is_signed = True
                pdf_record.signature_date = timezone.now()
                pdf_record.save()
                
                serializer = PDFRecordSerializer(pdf_record)
                return Response(serializer.data)
            
            else:
                return Response({'error': 'Invalid signature format'}, status=400)
        
        except Exception as e:
            return Response({'error': str(e)}, status=500)

    @action(detail=True, methods=['get'])
    def export_pdf(self, request, pk=None):
        """Download PDF file"""
        transaction = self.get_object()
        
        if not hasattr(transaction, 'pdf_record'):
            return Response({'error': 'PDF not generated yet'}, status=400)
        
        pdf_path = os.path.join(settings.MEDIA_ROOT, transaction.pdf_record.file_path)
        
        if not os.path.exists(pdf_path):
            return Response({'error': 'PDF file not found'}, status=404)
        
        return FileResponse(open(pdf_path, 'rb'), content_type='application/pdf')

    @action(detail=True, methods=['post'])
    def return_items(self, request, pk=None):
        """Mark items as returned"""
        transaction = self.get_object()
        items_data = request.data.get('items', [])
        
        if not items_data:
            return Response({'error': 'No items provided'}, status=400)
        
        try:
            for item_data in items_data:
                item_id = item_data.get('id')
                quantity_returned = item_data.get('quantity_returned')
                
                if item_id and quantity_returned is not None:
                    borrowed_item = BorrowedItem.objects.get(id=item_id, transaction=transaction)
                    borrowed_item.quantity_returned = quantity_returned
                    borrowed_item.save()
            
            # Refresh transaction
            transaction.refresh_from_db()
            serializer = self.get_serializer(transaction)
            return Response(serializer.data)
        
        except BorrowedItem.DoesNotExist:
            return Response({'error': 'Borrowed item not found'}, status=404)
        except Exception as e:
            return Response({'error': str(e)}, status=500)


class PDFRecordViewSet(viewsets.ReadOnlyModelViewSet):
    """API endpoint for PDF records (read-only)"""
    queryset = PDFRecord.objects.select_related('transaction__student').all()
    serializer_class = PDFRecordSerializer


@api_view(['GET'])
def export_database(request):
    """Export all database data as JSON"""
    try:
        data = {
            'categories': [],
            'materials': [],
            'students': [],
            'groups': [],
            'transactions': [],
            'borrowed_items': [],
        }
        
        # Export categories
        for cat in Category.objects.all():
            data['categories'].append({
                'id': cat.id,
                'name': cat.name,
                'description': cat.description,
                'material_type': cat.material_type,
            })
        
        # Export materials
        for mat in Material.objects.all():
            data['materials'].append({
                'id': mat.id,
                'category_id': mat.category_id,
                'name': mat.name,
                'description': mat.description,
                'total_quantity': mat.total_quantity,
                'available_quantity': mat.available_quantity,
            })
        
        # Export students
        for student in Student.objects.all():
            data['students'].append({
                'id': student.id,
                'full_name': student.full_name,
                'phone_number': student.phone_number,
                'id_card_number': student.id_card_number,
                'email': student.email,
            })
        
        # Export groups
        for group in Group.objects.all():
            data['groups'].append({
                'id': group.id,
                'name': group.name,
                'student_ids': list(group.students.values_list('id', flat=True)),
            })
        
        # Export transactions
        for trans in BorrowTransaction.objects.all():
            data['transactions'].append({
                'id': trans.id,
                'group_id': trans.group_id,
                'student_id': trans.student_id,
                'borrow_date': trans.borrow_date.isoformat() if trans.borrow_date else None,
                'expected_return_date': trans.expected_return_date.isoformat() if trans.expected_return_date else None,
                'actual_return_date': trans.actual_return_date.isoformat() if trans.actual_return_date else None,
                'status': trans.status,
                'notes': trans.notes,
            })
        
        # Export borrowed items
        for item in BorrowedItem.objects.all():
            data['borrowed_items'].append({
                'id': item.id,
                'transaction_id': item.transaction_id,
                'material_id': item.material_id,
                'quantity_borrowed': item.quantity_borrowed,
                'quantity_returned': item.quantity_returned,
            })
        
        response = HttpResponse(
            json.dumps(data, indent=2),
            content_type='application/json'
        )
        response['Content-Disposition'] = 'attachment; filename="database_export.json"'
        return response
    
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(['POST'])
def import_database(request):
    """Import database data from JSON, merging with existing data"""
    if 'file' not in request.FILES:
        return Response({'error': 'No file provided'}, status=400)
    
    try:
        file = request.FILES['file']
        data = json.loads(file.read().decode('utf-8'))
        
        stats = {
            'categories_added': 0,
            'materials_added': 0,
            'materials_updated': 0,
            'students_added': 0,
            'groups_added': 0,
        }
        
        # Map old IDs to new IDs for foreign keys
        category_id_map = {}
        student_id_map = {}
        
        # Import categories (skip duplicates by name)
        for cat_data in data.get('categories', []):
            existing = Category.objects.filter(name=cat_data['name']).first()
            if existing:
                category_id_map[cat_data['id']] = existing.id
            else:
                new_cat = Category.objects.create(
                    name=cat_data['name'],
                    description=cat_data.get('description', ''),
                    material_type=cat_data.get('material_type', 'FABLAB'),
                )
                category_id_map[cat_data['id']] = new_cat.id
                stats['categories_added'] += 1
        
        # Import students (skip duplicates by id_card_number)
        for student_data in data.get('students', []):
            existing = Student.objects.filter(id_card_number=student_data['id_card_number']).first()
            if existing:
                student_id_map[student_data['id']] = existing.id
            else:
                new_student = Student.objects.create(
                    full_name=student_data['full_name'],
                    phone_number=student_data.get('phone_number', ''),
                    id_card_number=student_data['id_card_number'],
                    email=student_data.get('email', ''),
                )
                student_id_map[student_data['id']] = new_student.id
                stats['students_added'] += 1
        
        # Import materials (update quantities for existing, create new ones)
        for mat_data in data.get('materials', []):
            new_category_id = category_id_map.get(mat_data['category_id'])
            if new_category_id:
                existing = Material.objects.filter(
                    category_id=new_category_id,
                    name=mat_data['name']
                ).first()
                if existing:
                    # Update existing material quantities by adding imported values
                    existing.total_quantity += mat_data.get('total_quantity', 0)
                    existing.available_quantity += mat_data.get('available_quantity', 0)
                    existing.save()
                    stats['materials_updated'] += 1
                else:
                    Material.objects.create(
                        category_id=new_category_id,
                        name=mat_data['name'],
                        description=mat_data.get('description', ''),
                        total_quantity=mat_data.get('total_quantity', 0),
                        available_quantity=mat_data.get('available_quantity', 0),
                    )
                    stats['materials_added'] += 1
        
        # Import groups (skip duplicates by name)
        for group_data in data.get('groups', []):
            existing = Group.objects.filter(name=group_data['name']).first()
            if not existing:
                new_group = Group.objects.create(name=group_data['name'])
                # Add students to group using mapped IDs
                for old_student_id in group_data.get('student_ids', []):
                    new_student_id = student_id_map.get(old_student_id)
                    if new_student_id:
                        new_group.students.add(new_student_id)
                stats['groups_added'] += 1
        
        return Response({
            'message': 'Import completed successfully',
            'stats': stats
        })
    
    except json.JSONDecodeError:
        return Response({'error': 'Invalid JSON file'}, status=400)
    except Exception as e:
        return Response({'error': str(e)}, status=500)
