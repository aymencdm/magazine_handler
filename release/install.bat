@echo off
echo ==========================================
echo      Magazine Application Installer
echo ==========================================
echo.
echo [1/4] Setting up Python virtual environment...
cd magazine_backend
python -m venv venv
call venv\Scripts\activate

echo.
echo [2/4] Installing dependencies...
pip install -r requirements.txt

echo.
echo [3/4] Setting up database...
python manage.py migrate

echo.
echo [4/4] Creating admin user (optional)...
echo You can create a superuser now if you want to access the admin panel.
set /p create_admin="Create admin user? (y/n): "
if /i "%create_admin%"=="y" (
    python manage.py createsuperuser
)

echo.
echo ==========================================
echo        Installation Complete!
echo ==========================================
echo.
echo You can now use 'start_app.bat' to launch the application.
pause
