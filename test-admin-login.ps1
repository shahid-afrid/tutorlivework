# Test Admin Login Functionality
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TutorLiveMentor - Admin Login Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "1. Start your application" -ForegroundColor White
Write-Host "2. Wait for it to initialize" -ForegroundColor White
Write-Host "3. Open the admin login page" -ForegroundColor White
Write-Host "4. Show you the admin credentials" -ForegroundColor White
Write-Host ""

Write-Host "Starting application..." -ForegroundColor Yellow
Write-Host ""

# Start the application in background
$appProcess = Start-Process powershell -ArgumentList "-NoExit", "-Command", `
    "Write-Host '?? TutorLiveMentor Application' -ForegroundColor Green; " + `
    "Write-Host 'Running on: http://localhost:5000' -ForegroundColor Cyan; " + `
    "Write-Host ''; " + `
    "dotnet run" `
    -PassThru -WindowStyle Normal

Write-Host "Waiting for application to start (15 seconds)..." -ForegroundColor Yellow
Write-Host ""

# Wait for application to start
Start-Sleep -Seconds 15

Write-Host "==========================================" -ForegroundColor Green
Write-Host "APPLICATION READY!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Write-Host "?? Admin Login Credentials:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ?? Email:    cseds@rgmcet.edu.in" -ForegroundColor White
Write-Host "  ?? Password: 9059530688" -ForegroundColor White
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Write-Host "?? Opening admin login page in your browser..." -ForegroundColor Yellow
Write-Host ""

# Open admin login page
Start-Sleep -Seconds 2
Start-Process "http://localhost:5000/Admin/Login"

Write-Host "? Browser opened!" -ForegroundColor Green
Write-Host ""
Write-Host "?? INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. The login page should be open in your browser" -ForegroundColor White
Write-Host "2. Enter the credentials shown above" -ForegroundColor White
Write-Host "3. Click 'Login as Admin'" -ForegroundColor White
Write-Host "4. You should be redirected to the dashboard" -ForegroundColor White
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "?? If login fails, check the application window for errors" -ForegroundColor Yellow
Write-Host ""
Write-Host "?? To stop the application:" -ForegroundColor Yellow
Write-Host "   - Close the application window" -ForegroundColor White
Write-Host "   - Or press Ctrl+C in the application window" -ForegroundColor White
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit this window (app will keep running)..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
