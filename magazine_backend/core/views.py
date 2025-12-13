from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.http import FileResponse
from django.conf import settings
from django.utils import timezone
import os
import csv
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
from .pdf_generator import generate_borrowing_pdf, add_signature_to_pdf


class CategoryViewSet(viewsets.ModelViewSet):
    """API endpoint for material categories"""
    queryset = Category.objects.all()
    serializer_class = CategorySerializer


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
