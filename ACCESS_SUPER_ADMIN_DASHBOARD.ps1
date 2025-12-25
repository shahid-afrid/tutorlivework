# ============================================
# SUPER ADMIN DASHBOARD - QUICK ACCESS GUIDE
# ============================================

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " SUPER ADMIN DASHBOARD ACCESS" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if migration is applied
Write-Host "Step 1: Checking database..." -ForegroundColor Green
$migrationCheck = dotnet ef migrations list 2>&1 | Select-String "AddSuperAdminMultiDepartmentSupport"

if ($migrationCheck) {
    Write-Host "? Super Admin migration found!" -ForegroundColor Green
} else {
    Write-Host "? Migration not found. Run: dotnet ef database update" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Starting application..." -ForegroundColor Green
Write-Host ""

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " SUPER ADMIN LOGIN CREDENTIALS" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Login URL:" -ForegroundColor White
Write-Host "  https://localhost:5001/SuperAdmin/Login" -ForegroundColor Cyan
Write-Host "  OR" -ForegroundColor Gray
Write-Host "  http://localhost:5000/SuperAdmin/Login" -ForegroundColor Cyan
Write-Host ""
Write-Host "Credentials:" -ForegroundColor White
Write-Host "  Email:    " -NoNewline -ForegroundColor White
Write-Host "superadmin@rgmcet.edu.in" -ForegroundColor Yellow
Write-Host "  Password: " -NoNewline -ForegroundColor White
Write-Host "Super@123" -ForegroundColor Yellow
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "After Login, you will see:" -ForegroundColor Green
Write-Host "  • System Statistics (6 cards)" -ForegroundColor White
Write-Host "  • All 6 Departments (CSEDS, CSE, ECE, MECH, CIVIL, EEE)" -ForegroundColor White
Write-Host "  • Recent Activity Feed" -ForegroundColor White
Write-Host "  • Navigation to Manage Departments & Admins" -ForegroundColor White
Write-Host ""

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " TROUBLESHOOTING" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If you can't see the login page:" -ForegroundColor White
Write-Host "  1. Make sure the application is running (dotnet run)" -ForegroundColor Gray
Write-Host "  2. Check the URL is correct" -ForegroundColor Gray
Write-Host "  3. Try both HTTP and HTTPS" -ForegroundColor Gray
Write-Host ""
Write-Host "If login fails:" -ForegroundColor White
Write-Host "  1. Verify database is updated (dotnet ef database update)" -ForegroundColor Gray
Write-Host "  2. Check credentials exactly as shown above" -ForegroundColor Gray
Write-Host "  3. Check browser console for errors (F12)" -ForegroundColor Gray
Write-Host ""
Write-Host "If dashboard shows errors:" -ForegroundColor White
Write-Host "  1. Check that departments are seeded" -ForegroundColor Gray
Write-Host "  2. Verify SuperAdmin account exists in database" -ForegroundColor Gray
Write-Host "  3. Check application logs in terminal" -ForegroundColor Gray
Write-Host ""

# Ask if user wants to start the app
Write-Host "====================================" -ForegroundColor Cyan
$response = Read-Host "Do you want to start the application now? (Y/N)"

if ($response -eq "Y" -or $response -eq "y") {
    Write-Host ""
    Write-Host "Starting application..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop the application" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opening browser in 5 seconds..." -ForegroundColor Cyan
    
    # Start the application in background
    Start-Process powershell -ArgumentList "cd '$PWD'; dotnet run" -NoNewWindow
    
    # Wait and open browser
    Start-Sleep -Seconds 5
    Start-Process "https://localhost:5001/SuperAdmin/Login"
    
    Write-Host ""
    Write-Host "? Browser opened to Super Admin login page!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Use credentials:" -ForegroundColor White
    Write-Host "  Email: superadmin@rgmcet.edu.in" -ForegroundColor Yellow
    Write-Host "  Password: Super@123" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "To start manually, run:" -ForegroundColor White
    Write-Host "  dotnet run" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then navigate to:" -ForegroundColor White
    Write-Host "  https://localhost:5001/SuperAdmin/Login" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " QUICK REFERENCE" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Super Admin Routes:" -ForegroundColor White
Write-Host "  /SuperAdmin/Login          - Login page" -ForegroundColor Gray
Write-Host "  /SuperAdmin/Dashboard      - Main dashboard" -ForegroundColor Gray
Write-Host "  /SuperAdmin/ManageDepartments - Department management" -ForegroundColor Gray
Write-Host "  /SuperAdmin/ManageAdmins   - Admin management" -ForegroundColor Gray
Write-Host "  /SuperAdmin/AuditLogs      - Activity logs" -ForegroundColor Gray
Write-Host "  /SuperAdmin/Logout         - Logout" -ForegroundColor Gray
Write-Host ""

Write-Host "Need help? Check these files:" -ForegroundColor White
Write-Host "  SUPER_ADMIN_PHASE_1_ERRORS_FIXED.md" -ForegroundColor Gray
Write-Host "  SUPER_ADMIN_PHASE_2_STEP_1_COMPLETE.md" -ForegroundColor Gray
Write-Host ""

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
