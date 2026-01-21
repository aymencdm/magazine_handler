from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, Image
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from django.conf import settings
import os
from datetime import datetime


def generate_borrowing_pdf(transaction, output_path=None):
    """
    Generate a PDF borrowing form for a transaction
    
    Args:
        transaction: BorrowTransaction instance
        output_path: Optional custom output path
    
    Returns:
        str: Path to the generated PDF file
    """
    # Create output directory if it doesn't exist
    pdf_dir = os.path.join(settings.MEDIA_ROOT, 'pdfs')
    os.makedirs(pdf_dir, exist_ok=True)
    
    # Generate filename
    if not output_path:
        filename = f"borrowing_form_{transaction.id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        output_path = os.path.join(pdf_dir, filename)
    
    # Create PDF document
    doc = SimpleDocTemplate(output_path, pagesize=A4)
    story = []
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor('#1a237e'),
        spaceAfter=20,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=12,
        textColor=colors.HexColor('#283593'),
        spaceAfter=10,
        spaceBefore=10,
        fontName='Helvetica-Bold'
    )
    
    normal_style = ParagraphStyle(
        'CustomNormal',
        parent=styles['Normal'],
        fontSize=10,
        spaceAfter=4
    )
    
    # Title
    story.append(Paragraph("SCHOOL ELECTRONICS MAGAZINE", title_style))
    story.append(Paragraph("BORROWING FORM", title_style))
    story.append(Spacer(1, 0.2*inch))
    
    # Borrower Information
    if transaction.group:
        story.append(Paragraph(f"Group: {transaction.group.name}", heading_style))
        
        # Members Table
        members_data = [['#', 'Full Name', 'ID Card', 'Phone']]
        for idx, student in enumerate(transaction.group.students.all(), 1):
            members_data.append([
                str(idx),
                student.full_name,
                student.id_card_number,
                student.phone_number
            ])
            
        members_table = Table(members_data, colWidths=[0.4*inch, 2.6*inch, 1.5*inch, 1.5*inch])
        members_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#5c6bc0')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 10),
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ]))
        story.append(members_table)
        
    elif transaction.student:
        story.append(Paragraph("Student Information", heading_style))
        student_data = [
            ['Full Name:', transaction.student.full_name],
            ['Phone Number:', transaction.student.phone_number],
            ['ID Card Number:', transaction.student.id_card_number],
            ['Email:', transaction.student.email or 'N/A'],
        ]
        
        student_table = Table(student_data, colWidths=[1.5*inch, 4.5*inch])
        student_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#e8eaf6')),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
            ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ]))
        story.append(student_table)
    
    story.append(Spacer(1, 0.2*inch))
    
    # Transaction Information
    story.append(Paragraph("Transaction Details", heading_style))
    
    transaction_data = [
        ['Borrow Date:', transaction.borrow_date.strftime('%Y-%m-%d %H:%M')],
        ['Expected Return:', transaction.expected_return_date.strftime('%Y-%m-%d') if transaction.expected_return_date else 'Not specified'],
        ['Status:', transaction.get_status_display()],
        ['Transaction ID:', f"#{transaction.id}"],
    ]
    
    transaction_table = Table(transaction_data, colWidths=[1.5*inch, 4.5*inch])
    transaction_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#e8eaf6')),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
        ('ALIGN', (1, 0), (1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    
    story.append(transaction_table)
    story.append(Spacer(1, 0.3*inch))
    
    # Borrowed Materials
    story.append(Paragraph("Borrowed Materials", heading_style))
    
    # Table header
    materials_data = [['#', 'Material Name', 'Category', 'Qty Borrowed', 'Qty Returned']]
    
    # Add borrowed items
    for idx, item in enumerate(transaction.borrowed_items.all(), 1):
        materials_data.append([
            str(idx),
            item.material.name,
            item.material.category.name,
            str(item.quantity_borrowed),
            str(item.quantity_returned)
        ])
    
    materials_table = Table(materials_data, colWidths=[0.5*inch, 2.5*inch, 1.5*inch, 1*inch, 1*inch])
    materials_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#3f51b5')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 12),
        ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 1), (-1, -1), 10),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
    ]))
    
    story.append(materials_table)
    story.append(Spacer(1, 0.3*inch))
    
    # Notes/Conditions
    if transaction.notes:
        story.append(Paragraph("Notes/Conditions", heading_style))
        story.append(Paragraph(transaction.notes, normal_style))
        story.append(Spacer(1, 0.3*inch))
    
    # Signature Section
    story.append(Spacer(1, 0.5*inch))
    story.append(Paragraph("Student Signature", heading_style))
    
    signature_data = [
        ['Signature:', ''],
        ['', ''],
        ['Date:', '_' * 30],
    ]
    
    signature_table = Table(signature_data, colWidths=[1.5*inch, 4.5*inch])
    signature_table.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 11),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    
    story.append(signature_table)
    
    # Build PDF
    doc.build(story)
    
    # Return relative path for database storage
    relative_path = os.path.relpath(output_path, settings.MEDIA_ROOT)
    return relative_path


def add_signature_to_pdf(pdf_record, signature_image_path):
    """
    Add a signature image to an existing PDF
    
    Args:
        pdf_record: PDFRecord instance
        signature_image_path: Path to the signature image
    
    Returns:
        str: Path to the updated PDF file
    """
    # This is a simplified version - in production, you might want to use
    # PyPDF2 or similar to overlay the signature on the existing PDF
    # For now, we'll regenerate the PDF with the signature
    
    transaction = pdf_record.transaction
    
    # Generate new PDF path
    pdf_dir = os.path.join(settings.MEDIA_ROOT, 'pdfs')
    filename = f"borrowing_form_{transaction.id}_signed_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    output_path = os.path.join(pdf_dir, filename)
    
    # Regenerate PDF (in a real implementation, you'd overlay the signature)
    relative_path = generate_borrowing_pdf(transaction, output_path)
    
    return relative_path


def _add_category_to_story(category, story, styles, heading_style, indent_level=0):
    """
    Helper to recursively add a category and its subcategories to the PDF story
    """
    # Indentation for the heading
    indent = "  " * (indent_level * 2)
    
    # Category Header
    story.append(Paragraph(f"{indent}{category.name}", heading_style))
    if category.description:
        story.append(Paragraph(f"{indent}{category.description}", styles['Normal']))
    
    materials = category.materials.all()
    
    if materials:
        materials_data = [['#', 'Material Name', 'Description', 'Total', 'Available', 'Borrowed']]
        
        for idx, material in enumerate(materials, 1):
            borrowed = material.total_quantity - material.available_quantity
            materials_data.append([
                str(idx),
                material.name,
                material.description[:25] + '...' if len(material.description) > 25 else material.description,
                str(material.total_quantity),
                str(material.available_quantity),
                str(borrowed)
            ])
        
        # Adjust column widths slightly for nesting if needed, or keep standard
        materials_table = Table(materials_data, colWidths=[0.3*inch, 1.6*inch, 1.8*inch, 0.7*inch, 0.8*inch, 0.8*inch])
        
        # Determine background color based on level
        header_colors = ['#3f51b5', '#5c6bc0', '#7986cb', '#9fa8da']
        header_color = header_colors[min(indent_level, len(header_colors)-1)]
        
        materials_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor(header_color)),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (0, -1), 'CENTER'),
            ('ALIGN', (3, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 9),
            ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 1), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f5f5f5')]),
            ('LEFTPADDING', (0, 0), (-1, -1), 6 + (indent_level * 5)),
        ]))
        
        story.append(materials_table)
    else:
        if not category.subcategories.exists():
            story.append(Paragraph(f"{indent}No materials in this category.", styles['Italic']))
    
    story.append(Spacer(1, 0.15*inch))
    
    # Recursively add subcategories
    for subcategory in category.subcategories.all():
        _add_category_to_story(subcategory, story, styles, heading_style, indent_level + 1)


def generate_category_pdf(category, output_path=None):
    """
    Generate a PDF inventory report for a single category and all its nested subcategories
    """
    # Create output directory if it doesn't exist
    pdf_dir = os.path.join(settings.MEDIA_ROOT, 'categories_pdfs')
    os.makedirs(pdf_dir, exist_ok=True)
    
    # Generate filename
    if not output_path:
        filename = f"category_{category.id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        output_path = os.path.join(pdf_dir, filename)
    
    # Create PDF document
    doc = SimpleDocTemplate(output_path, pagesize=A4)
    story = []
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor('#1a237e'),
        spaceAfter=20,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#283593'),
        spaceAfter=10,
        spaceBefore=10,
        fontName='Helvetica-Bold'
    )
    
    # Title
    story.append(Paragraph("INVENTORY REPORT", title_style))
    story.append(Spacer(1, 0.2*inch))
    
    # Category Information
    story.append(Paragraph(f"Base Category: {category.name}", heading_style))
    story.append(Paragraph(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}", styles['Normal']))
    story.append(Spacer(1, 0.3*inch))
    
    # Recursive category content
    _add_category_to_story(category, story, styles, heading_style, indent_level=0)
    
    # Summary calculation (needs to be recursive for all children)
    def count_recursive(cat):
        mats = list(cat.materials.all())
        total = sum(m.total_quantity for m in mats)
        avail = sum(m.available_quantity for m in mats)
        count = len(mats)
        
        for sub in cat.subcategories.all():
            s_count, s_total, s_avail = count_recursive(sub)
            count += s_count
            total += s_total
            avail += s_avail
        return count, total, avail

    total_items, total_qty_val, available_qty_val = count_recursive(category)
    borrowed_qty_val = total_qty_val - available_qty_val
    
    story.append(Spacer(1, 0.3*inch))
    story.append(Paragraph("Total Summary (Including Subcategories)", heading_style))
    
    summary_data = [
        ['Total Items:', str(total_items)],
        ['Total Quantity:', str(total_qty_val)],
        ['Available:', str(available_qty_val)],
        ['Currently Borrowed:', str(borrowed_qty_val)]
    ]
    
    summary_table = Table(summary_data, colWidths=[2*inch, 1.5*inch])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#e8eaf6')),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 10),
        ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(summary_table)
    
    # Build PDF
    doc.build(story)
    
    # Return relative path for database storage
    relative_path = os.path.relpath(output_path, settings.MEDIA_ROOT)
    return relative_path


def generate_all_categories_pdf(material_type=None, output_path=None):
    """
    Generate a PDF inventory report for all categories (optionally filtered by type)
    """
    from .models import Category, Material
    
    # Create output directory if it doesn't exist
    pdf_dir = os.path.join(settings.MEDIA_ROOT, 'categories_pdfs')
    os.makedirs(pdf_dir, exist_ok=True)
    
    # Generate filename
    if not output_path:
        type_prefix = f"{material_type.lower()}_" if material_type else ""
        filename = f"all_{type_prefix}categories_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        output_path = os.path.join(pdf_dir, filename)
    
    # Create PDF document
    doc = SimpleDocTemplate(output_path, pagesize=A4)
    story = []
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_text = "COMPLETE INVENTORY REPORT"
    if material_type:
        title_text = f"{material_type.upper()} INVENTORY REPORT"
        
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=20,
        textColor=colors.HexColor('#1a237e'),
        spaceAfter=20,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'CategoryHeading',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#283593'),
        spaceAfter=10,
        spaceBefore=15,
        fontName='Helvetica-Bold'
    )
    
    # Title
    story.append(Paragraph(title_text, title_style))
    story.append(Paragraph(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}", styles['Normal']))
    story.append(Spacer(1, 0.3*inch))
    
    # Get top-level categories
    filters = {'parent__isnull': True}
    if material_type:
        filters['material_type'] = material_type.upper()
        
    top_categories = Category.objects.filter(**filters).prefetch_related('materials', 'subcategories')
    
    if not top_categories:
        story.append(Paragraph("No categories found.", styles['Normal']))
    else:
        for category in top_categories:
            _add_category_to_story(category, story, styles, heading_style, indent_level=0)
            story.append(Spacer(1, 0.3*inch))
            story.append(Paragraph("-" * 80, styles['Normal']))
        
        # Overall Summary
        story.append(Spacer(1, 0.3*inch))
        story.append(Paragraph("Inventory Summary", heading_style))
        
        materials_filters = {}
        if material_type:
            materials_filters['category__material_type'] = material_type.upper()
            
        all_materials = Material.objects.filter(**materials_filters)
        
        total_categories = Category.objects.filter(material_type=material_type.upper() if material_type else None).count() if material_type else Category.objects.count()
        total_materials = all_materials.count()
        total_qty = sum(m.total_quantity for m in all_materials)
        available_qty = sum(m.available_quantity for m in all_materials)
        borrowed_qty = total_qty - available_qty
        
        summary_data = [
            ['Total Categories:', str(total_categories)],
            ['Total Materials:', str(total_materials)],
            ['Total Quantity:', str(total_qty)],
            ['Available:', str(available_qty)],
            ['Currently Borrowed:', str(borrowed_qty)]
        ]
        
        summary_table = Table(summary_data, colWidths=[2.5*inch, 1.5*inch])
        summary_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#e8eaf6')),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 11),
            ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
            ('TOPPADDING', (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ]))
        story.append(summary_table)
    
    # Build PDF
    doc.build(story)
    
    # Return relative path
    relative_path = os.path.relpath(output_path, settings.MEDIA_ROOT)
    return relative_path
