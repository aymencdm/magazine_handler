# Magazine Handler - Codebase Overview

> A school electronics inventory management system with material borrowing tracking.

## Project Structure

```
magazine_handler/
├── magazine_backend/     # Django REST API backend
│   ├── core/             # Main Django app
│   │   ├── models.py     # Database models
│   │   ├── views.py      # API ViewSets and endpoints
│   │   ├── serializers.py# DRF serializers
│   │   ├── urls.py       # API URL routing
│   │   ├── admin.py      # Django admin configuration
│   │   ├── signals.py    # Django signals (inventory updates)
│   │   └── pdf_generator.py # PDF report generation
│   ├── magazine_project/ # Django project settings
│   ├── db.sqlite3        # SQLite database
│   └── requirements.txt  # Python dependencies
│
├── magazine_app/         # Flutter desktop app (Windows)
│   ├── lib/
│   │   ├── main.dart     # App entry point, navigation
│   │   ├── models/       # Data models (Dart classes)
│   │   ├── screens/      # UI screens
│   │   └── services/     # API service (HTTP client)
│   └── pubspec.yaml      # Flutter dependencies
│
└── release/              # Release build files
```

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Backend | Django 5.0 + Django REST Framework 3.14 |
| Frontend | Flutter (Windows desktop) |
| Database | SQLite |
| PDF Generation | ReportLab (backend), pdf/printing (frontend) |

---

## Backend Models (core/models.py)

### Category
Material categories with type distinction (FabLab/STCB Club). **Supports nested subcategories.**

| Field | Type | Notes |
|-------|------|-------|
| `name` | CharField(100) | unique per parent |
| `description` | TextField | optional |
| `material_type` | CharField | 'FABLAB' or 'STCB' |
| `parent` | ForeignKey(self) | nullable, enables subcategories |
| `created_at` | DateTimeField | auto |
| `updated_at` | DateTimeField | auto |

**Relationships:** Has many `Material`, has many `subcategories` (self-referential)

---

### Material
Individual inventory items with quantity tracking.

| Field | Type | Notes |
|-------|------|-------|
| `category` | ForeignKey(Category) | CASCADE delete |
| `name` | CharField(200) | unique per category |
| `description` | TextField | optional |
| `image` | ImageField | optional |
| `total_quantity` | IntegerField | minimum 0 |
| `available_quantity` | IntegerField | minimum 0 |
| `created_at` | DateTimeField | auto |
| `updated_at` | DateTimeField | auto |

**Properties:**
- `borrowed_quantity` = total - available

---

### Student
Registered students who can borrow materials.

| Field | Type | Notes |
|-------|------|-------|
| `full_name` | CharField(200) | |
| `phone_number` | CharField(20) | |
| `id_card_number` | CharField(50) | unique identifier |
| `email` | EmailField | optional |

---

### Group
Project groups containing multiple students.

| Field | Type | Notes |
|-------|------|-------|
| `name` | CharField(200) | unique |
| `students` | ManyToManyField(Student) | |

---

### BorrowTransaction
Material borrowing records.

| Field | Type | Notes |
|-------|------|-------|
| `group` | ForeignKey(Group) | nullable |
| `student` | ForeignKey(Student) | nullable |
| `borrow_date` | DateTimeField | default now |
| `expected_return_date` | DateField | optional |
| `actual_return_date` | DateTimeField | optional |
| `status` | CharField | 'BORROWED', 'RETURNED', 'PARTIALLY_RETURNED' |
| `notes` | TextField | optional |

**Methods:**
- `update_status()` - Auto-updates status based on returned items

---

### BorrowedItem
Individual items within a transaction.

| Field | Type | Notes |
|-------|------|-------|
| `transaction` | ForeignKey(BorrowTransaction) | |
| `material` | ForeignKey(Material) | |
| `quantity_borrowed` | IntegerField | minimum 1 |
| `quantity_returned` | IntegerField | default 0 |

**Properties:**
- `is_fully_returned` - True if returned >= borrowed

---

### PDFRecord
PDF document metadata.

| Field | Type | Notes |
|-------|------|-------|
| `transaction` | OneToOneField(BorrowTransaction) | |
| `file_path` | CharField(500) | |
| `is_signed` | BooleanField | |
| `signature_image` | ImageField | optional |
| `signature_date` | DateTimeField | optional |

---

## Backend API Endpoints (core/urls.py)

Base URL: `http://localhost:8000/api/`

| Endpoint | ViewSet | Key Actions |
|----------|---------|-------------|
| `/categories/` | CategoryViewSet | CRUD, `top_level/`, `{id}/subcategories/`, `by_type/`, PDF exports |
| `/materials/` | MaterialViewSet | CRUD, `by_category/`, `low_stock/` |
| `/students/` | StudentViewSet | CRUD, `import_csv/`, `import_excel/` |
| `/groups/` | GroupViewSet | CRUD |
| `/transactions/` | BorrowTransactionViewSet | CRUD, `generate_pdf/`, `add_signature/`, `export_pdf/`, `return_items/` |
| `/pdfs/` | PDFRecordViewSet | Read-only |
| `/database/export/` | Function view | Export all data as JSON |
| `/database/import/` | Function view | Import data from JSON |

---

## Frontend Structure (magazine_app/lib/)

### Models (models/)

| File | Class | Maps to Backend |
|------|-------|-----------------|
| `category.dart` | Category | Category model |
| `material.dart` | Material | Material model |
| `student.dart` | Student | Student model |
| `group.dart` | Group | Group model |
| `borrow_transaction.dart` | BorrowTransaction, BorrowedItem | BorrowTransaction, BorrowedItem |

Each model has `fromJson()` and `toJson()` methods for API serialization.

---

### Screens (screens/)

| File | Purpose |
|------|---------|
| `dashboard_screen.dart` | Overview/stats dashboard |
| `fablab_screen.dart` | FabLab materials (type='FABLAB') |
| `stcb_screen.dart` | STCB Club materials (type='STCB') |
| `categories_screen.dart` | All categories management |
| `category_detail_screen.dart` | Materials within a category |
| `materials_screen.dart` | All materials view |
| `students_screen.dart` | Student management |
| `groups_screen.dart` | Group management |
| `transactions_screen.dart` | Borrowing transactions |
| `settings_screen.dart` | App settings, database export/import |
| `pdf_settings_screen.dart` | PDF configuration |

---

### Services (services/)

| File | Class | Purpose |
|------|-------|---------|
| `api_service.dart` | ApiService | HTTP client for all API calls |

**Key methods:**
- `getCategories()`, `getTopLevelCategories()`, `getSubcategories()`, `createCategory()`, `updateCategory()`, `deleteCategory()`
- `getMaterials()`, `getMaterialsByCategory()`, `createMaterial()`, etc.
- `getStudents()`, `getGroups()`, `getTransactions()`
- `createTransaction()`, `returnItems()`
- `generatePdf()`, `downloadPdf()`, `addSignature()`
- `exportDatabase()`, `importDatabase()`

---

## How the App Works

1. **Navigation:** `main.dart` uses a NavigationRail with 7 sections: Dashboard, FabLab, STCB Club, Students, Groups, Transactions, Settings

2. **Material Flow:**
   - Materials belong to Categories (which have types: FABLAB or STCB)
   - Students/Groups can borrow materials via BorrowTransactions
   - BorrowedItems track quantities within each transaction
   - Returning items updates `quantity_returned` and auto-updates transaction status

3. **Inventory Updates:**
   - Signals in `signals.py` auto-update `available_quantity` when BorrowedItems change
   - Borrowing decreases available, returning increases available

4. **PDF Generation:**
   - Backend generates PDFs using ReportLab
   - Category PDFs list all materials with quantities
   - Transaction PDFs are borrowing receipts with optional signature

---

## Running the App

### Backend
```bash
cd magazine_backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
# Runs at http://localhost:8000
```

### Frontend
```bash
cd magazine_app
flutter pub get
flutter run -d windows
```

---

## Key Files for Common Tasks

| Task | Files to Modify |
|------|-----------------|
| Add new model field | `models.py` → `serializers.py` → `views.py` → Flutter model → `api_service.dart` → screens |
| Add new API endpoint | `views.py` → `urls.py` → `api_service.dart` → screens |
| Modify UI | `screens/*.dart` |
| Change database schema | `models.py` then run `python manage.py makemigrations && python manage.py migrate` |
| Add new screen | Create `screens/new_screen.dart`, add to `main.dart` navigation |
