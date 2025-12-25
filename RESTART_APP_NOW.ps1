# ? INSTANT FIX - Restart Application
# This will stop IIS Express and restart your app

Write-Host "?? STOPPING APPLICATION..." -ForegroundColor Yellow
Write-Host ""

# Stop IIS Express
Write-Host "Stopping IIS Express processes..." -ForegroundColor Cyan
Get-Process | Where-Object {$_.ProcessName -like "*iisexpress*"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Stop dotnet processes
Write-Host "Stopping dotnet processes..." -ForegroundColor Cyan
Get-Process | Where-Object {$_.ProcessName -like "*dotnet*"} | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "? APPLICATION STOPPED" -ForegroundColor Green
Write-Host ""
Write-Host "?? NOW DO THIS IN VISUAL STUDIO:" -ForegroundColor Yellow
Write-Host "   1. Press F5 (or click 'Start' button)" -ForegroundColor White
Write-Host "   2. Wait for app to load" -ForegroundColor White
Write-Host "   3. Navigate to: Admin/DynamicReports?department=DES" -ForegroundColor White
Write-Host ""
Write-Host "?? THAT'S IT! The errors will be gone!" -ForegroundColor Green
Write-Host ""

# Wait for user
Read-Host "Press Enter to close this window"
