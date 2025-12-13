# Test Django API Connection
Write-Host "Testing Django API Connection..." -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8000/api"

# Test if server is running
try {
    Write-Host "1. Testing server connection..." -ForegroundColor Yellow
    $response = Invoke-WebRequest -Uri "$baseUrl/students/" -Method GET -TimeoutSec 5
    Write-Host "   ✓ Server is running!" -ForegroundColor Green
    Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "2. Testing response data..." -ForegroundColor Yellow
    $data = $response.Content | ConvertFrom-Json
    if ($data.results) {
        Write-Host "   ✓ Found $($data.count) students" -ForegroundColor Green
    } else {
        Write-Host "   ✓ API responding (no pagination)" -ForegroundColor Green
    }
    Write-Host ""
    
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "API is working correctly!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run the Flutter app:" -ForegroundColor White
    Write-Host "  cd magazine_app" -ForegroundColor Gray
    Write-Host "  flutter run -d windows" -ForegroundColor Gray
    
} catch {
    Write-Host "   ✗ Cannot connect to server!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the Django server:" -ForegroundColor Yellow
    Write-Host "  cd magazine_backend" -ForegroundColor Gray
    Write-Host "  python manage.py runserver" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
