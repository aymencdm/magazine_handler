# QUICK FIX GUIDE - Flutter Connection Issues

## The Problem
You're seeing "error loading" messages in the Flutter app when trying to load students, materials, or transactions.

## The Solution

### Step 1: Restart Django Server (IMPORTANT!)
The CORS settings were just updated, so you MUST restart the Django server:

1. **Stop the current Django server** (press Ctrl+C in the terminal running it)
2. **Start it again**:
   ```bash
   cd magazine_backend
   python manage.py runserver
   ```

### Step 2: Test the Connection
Run the test script to verify the API is working:
```powershell
.\test_connection.ps1
```

### Step 3: Restart Flutter App
If the Flutter app is already running:
1. Stop it (press 'q' in the terminal or close the window)
2. Start it again:
   ```bash
   cd magazine_app
   flutter run -d windows
   ```

## What Was Fixed

1. **CORS Settings**: Changed from specific origins to allow all origins for local development
2. **Error Handling**: Added better error messages with timeouts
3. **Pagination Support**: Fixed to handle Django REST Framework's paginated responses
4. **Connection Timeouts**: Added 10-second timeout with helpful error messages

## Verify It's Working

After restarting both servers, you should see:
- ✅ Students page loads (shows the 1 student already in database)
- ✅ Materials page loads (empty or with data)
- ✅ Transactions page loads (empty or with data)
- ✅ Dashboard shows statistics

## If Still Not Working

1. **Check Django is running**:
   ```bash
   netstat -ano | findstr :8000
   ```
   Should show LISTENING on port 8000

2. **Check the Flutter console** for detailed error messages (now improved)

3. **Test API directly** in browser:
   - http://localhost:8000/api/students/
   - http://localhost:8000/api/materials/
   - http://localhost:8000/api/categories/

4. **Add test data** via Django admin:
   - http://localhost:8000/admin
   - Create superuser if needed: `python manage.py createsuperuser`
   - Add categories and materials

## Common Issues

**"Connection timeout"**: Django server not running
**"Cannot connect to server"**: Wrong URL or server not started
**"Server error 500"**: Check Django terminal for error details
**Empty lists**: No data in database yet (this is normal for first run)
