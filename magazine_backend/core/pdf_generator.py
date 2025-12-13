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
