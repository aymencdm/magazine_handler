# Quick Start - Adding Data to the System

## Step 1: Add Categories (Required First!)

Materials need categories, so you must add categories first via Django admin:

1. **Open Django Admin**: http://localhost:8000/admin
2. **Login** with your superuser credentials (if you haven't created one, see below)
3. **Click "Categories"** under CORE section
4. **Click "Add Category"** button
5. **Add categories** like:
   - Sensors
   - ICs (Integrated Circuits)
   - Tools
   - Power Components
   - Microcontrollers
   - Resistors & Capacitors

### Create Superuser (if needed)
```bash
cd magazine_backend
python manage.py createsuperuser
```
Follow the prompts to set username, email, and password.

## Step 2: Add Materials (via Flutter App)

Now you can add materials in the Flutter app:

1. **Open Flutter app** (should be running)
2. **Click "Materials"** in the left navigation
3. **Click "Add Material"** button
4. **Fill in the form**:
   - Select Category (from dropdown)
   - Enter Material Name (e.g., "Arduino Uno R3")
   - Enter Description (e.g., "Microcontroller board based on ATmega328P")
   - Enter Total Quantity (e.g., 20)
   - Enter Available Quantity (e.g., 20)
5. **Click "Add"**

The material will appear in the grid immediately!

## Step 3: Add Students

1. **Click "Students"** in navigation
2. **Click "Add Student"**
3. **Fill in**:
   - Full Name
   - Phone Number
   - ID Card Number
   - Email (optional)
4. **Click "Add"**

## Step 4: Create Transactions

1. **Click "Transactions"**
2. **Click "New Transaction"** (coming soon - needs implementation)
3. Select student and materials
4. Generate PDF and add signature

## Current Status

✅ **Working:**
- Students: Add, view, list
- Materials: Add, view, list (after categories added)
- Categories: Add via Django admin
- Connection: Fixed and working

⏳ **Coming Soon:**
- Transaction creation dialog
- PDF generation and signature
- Edit/delete functionality

## Troubleshooting

**"Please add categories first"**: You need to add categories via Django admin first (see Step 1)

**Can't login to admin**: Create superuser with `python manage.py createsuperuser`

**Materials not showing**: Check if they were created successfully, refresh the page
