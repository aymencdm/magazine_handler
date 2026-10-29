# School Electronics Magazine Tracking System - Setup Guide

## Overview
A complete full-stack application for tracking electronics materials borrowing in a school environment, featuring:
- **Backend**: Django REST API with SQLite database
- **Frontend**: Flutter Windows desktop application
- **Features**: Student management, materials inventory, borrowing transactions, PDF generation with signatures

---

## Backend Setup (Django)

### Prerequisites
- Python 3.13+ installed
- pip package manager

### Installation Steps

1. **Navigate to backend directory**
   ```bash
   cd magazine_backend
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run migrations** (already completed)
   ```bash
   python manage.py migrate
   ```

4. **Create superuser for admin access**
   ```bash
   python manage.py createsuperuser
   ```
   Follow prompts to set username, email, and password.

5. **Start the development server**
   ```bash
   python manage.py runserver
   ```
   Server will run at `http://localhost:8000`

6. **Access admin panel**
   - URL: `http://localhost:8000/admin`
   - Login with superuser credentials
   - Add initial categories and materials

### API Endpoints

Base URL: `http://localhost:8000/api/`

#### Categories
- `GET /categories/` - List all categories
- `POST /categories/` - Create category
- `PUT /categories/{id}/` - Update category
- `DELETE /categories/{id}/` - Delete category

#### Materials
- `GET /materials/` - List all materials
- `POST /materials/` - Create material
- `PUT /materials/{id}/` - Update material
- `DELETE /materials/{id}/` - Delete material
- `GET /materials/by_category/?category_id={id}` - Filter by category

#### Students
- `GET /students/` - List all students
- `POST /students/` - Create student
- `PUT /students/{id}/` - Update student
- `DELETE /students/{id}/` - Delete student
- `POST /students/import_csv/` - Import from CSV
- `POST /students/import_excel/` - Import from Excel

#### Transactions
- `GET /transactions/` - List all transactions
- `POST /transactions/` - Create transaction
- `GET /transactions/{id}/` - Get transaction details
- `POST /transactions/{id}/generate_pdf/` - Generate PDF
- `POST /transactions/{id}/add_signature/` - Add signature
- `GET /transactions/{id}/export_pdf/` - Download PDF
- `POST /transactions/{id}/return_items/` - Return items

---

## Frontend Setup (Flutter Desktop)

### Prerequisites
- Flutter SDK 3.38+ installed
- Windows development environment configured

### Installation Steps

1. **Navigate to frontend directory**
   ```bash
   cd magazine_app
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Windows desktop is enabled**
   ```bash
   flutter config --enable-windows-desktop
   ```

4. **Run the application**
   ```bash
   flutter run -d windows
   ```

### Application Features

#### Dashboard
- Overview statistics
- Total students, materials, transactions
- Low stock alerts
- Quick access to all modules

#### Students Management
- Add, edit, delete students
- View student details and transaction history
- Import students from CSV/Excel

#### Materials Management
- Add, edit, delete materials
- Categorize materials
- Track total and available quantities
- Low stock indicators

#### Transactions
- Create new borrowing transactions
- Select student and materials
- Automatic inventory updates
- Generate PDF borrowing forms
- Add digital signatures
- Return items tracking
- View transaction history

---

## Usage Workflow

### 1. Initial Setup
1. Start Django backend server
2. Access admin panel and create categories (e.g., Sensors, ICs, Tools)
3. Add materials to each category
4. Add students to the system

### 2. Creating a Borrowing Transaction
1. Open Flutter app
2. Navigate to "Transactions"
3. Click "New Transaction"
4. Select student
5. Add materials with quantities
6. System validates available inventory
7. Save transaction (inventory automatically updated)

### 3. Generating PDF
1. Open transaction details
2. Click "Generate PDF"
3. PDF created with student info and borrowed items
4. Click "Add Signature" to capture student signature
5. Export or share PDF

### 4. Returning Items
1. Open transaction
2. Click "Return Items"
3. Enter quantities returned for each item
4. Inventory automatically updated
5. Transaction status updates (Partially Returned / Returned)

---

## Project Structure

### Backend (`magazine_backend/`)
```
magazine_backend/
├── manage.py
├── requirements.txt
├── db.sqlite3
├── magazine_project/
│   ├── settings.py      # Django configuration
│   ├── urls.py          # URL routing
│   └── wsgi.py
└── core/
    ├── models.py        # Database models
    ├── serializers.py   # DRF serializers
    ├── views.py         # API viewsets
    ├── urls.py          # API routes
    ├── admin.py         # Admin configuration
    ├── signals.py       # Inventory automation
    └── pdf_generator.py # PDF creation logic
```

### Frontend (`magazine_app/`)
```
magazine_app/
├── pubspec.yaml
├── lib/
│   ├── main.dart        # Main app with navigation
│   ├── models/
│   │   ├── category.dart
│   │   ├── material.dart
│   │   ├── student.dart
│   │   └── borrow_transaction.dart
│   └── services/
│       └── api_service.dart  # HTTP client
└── windows/             # Windows desktop config
```

---

## Key Features

### Automatic Inventory Management
- Materials' available quantity automatically decreases when borrowed
- Automatically increases when items are returned
- Implemented via Django signals

### PDF Generation
- Professional PDF forms with ReportLab
- Student information
- Borrowed materials table
- Signature section
- Notes/conditions field

### Data Import/Export
- Import students from CSV/Excel
- Export transaction reports
- Download PDF borrowing forms

### Validation
- Prevents borrowing more than available quantity
- Ensures data integrity
- Validates all form inputs

---

## Troubleshooting

### Backend Issues

**Django won't start**
- Ensure all dependencies installed: `pip install -r requirements.txt`
- Check Python version: `python --version` (should be 3.13+)
- Run migrations: `python manage.py migrate`

**CORS errors**
- Backend configured for `localhost:3000`
- Update `CORS_ALLOWED_ORIGINS` in `settings.py` if needed

### Frontend Issues

**Flutter dependencies fail**
- Run `flutter clean`
- Run `flutter pub get`
- Ensure Flutter SDK is up to date

**Can't connect to backend**
- Ensure Django server is running on `localhost:8000`
- Check `ApiService` base URL in `api_service.dart`

**Windows build fails**
- Ensure Windows desktop is enabled: `flutter config --enable-windows-desktop`
- Run `flutter doctor` to check setup

---

## Next Steps

### Enhancements
1. Add signature pad widget for in-app signature capture
2. Implement PDF preview functionality
3. Add search and filtering
4. Create reports and analytics
5. Add user authentication for multi-user support
6. Implement barcode scanning for materials
7. Add email notifications
8. Create mobile version (Android/iOS)

### Production Deployment
1. Switch to PostgreSQL database
2. Configure proper SECRET_KEY
3. Set DEBUG=False
4. Configure static files serving
5. Set up proper authentication
6. Add HTTPS support
7. Create installer for Flutter app

---

## Support

For issues or questions:
1. Check Django logs in terminal
2. Check Flutter console output
3. Verify API endpoints with Postman/browser
4. Review database in Django admin panel

---

## License

This project is created for educational purposes for school electronics magazine management.
#
