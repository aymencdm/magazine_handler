# Quick Start Script for School Electronics Magazine System
# Run this script to start both backend and frontend

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "School Electronics Magazine System" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Start Django Backend
Write-Host "Starting Django Backend Server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\magazine_backend'; python manage.py runserver"

Write-Host "Backend server starting on http://localhost:8000" -ForegroundColor Green
Write-Host ""

# Wait a moment for backend to start
Start-Sleep -Seconds 3

# Start Flutter Frontend
Write-Host "Starting Flutter Desktop App..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\magazine_app'; flutter run -d windows"

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "System Starting!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend: http://localhost:8000" -ForegroundColor White
Write-Host "Admin Panel: http://localhost:8000/admin" -ForegroundColor White
Write-Host "API: http://localhost:8000/api/" -ForegroundColor White
Write-Host ""
Write-Host "Flutter app will open in a new window..." -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit this window..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
