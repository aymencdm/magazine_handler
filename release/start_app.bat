@echo off
echo ==========================================
echo      Magazine Application Launcher
echo ==========================================
echo.

echo [1/2] Starting Backend Server...
cd magazine_backend
if not exist venv (
    echo Error: Virtual environment not found!
    echo Please run install.bat first.
    pause
    exit /b
)
call venv\Scripts\activate
start /min "Magazine Backend Server" python manage.py runserver

echo Waiting for server to initialize...
timeout /t 5 /nobreak >nul

echo.
echo [2/2] Launching Application...
cd ..\magazine_app
start magazine_app.exe

echo.
echo App launched! Do not close the backend server window.
timeout /t 3 >nul
exit
