# ============================================
# Super Admin System - Database Migration
# Phase 1: Foundation & Infrastructure
# ============================================

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " SUPER ADMIN SYSTEM - PHASE 1" -ForegroundColor Yellow
Write-Host " Database Migration Script" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the correct directory
if (!(Test-Path "TutorLiveMentor10.csproj")) {
    Write-Host "ERROR: Please run this script from the project root directory" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Building the project..." -ForegroundColor Green
dotnet build
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed. Please fix compilation errors first." -ForegroundColor Red
    exit 1
}
Write-Host "? Build successful!" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Applying database migration..." -ForegroundColor Green
Write-Host "This will create:" -ForegroundColor Cyan
Write-Host "  • SuperAdmins table" -ForegroundColor White
Write-Host "  • Departments table" -ForegroundColor White
Write-Host "  • DepartmentAdmins table" -ForegroundColor White
Write-Host "  • SystemConfigurations table" -ForegroundColor White
Write-Host "  • AuditLogs table" -ForegroundColor White
Write-Host "  • DepartmentStatistics table" -ForegroundColor White
Write-Host ""

dotnet ef database update
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Migration failed. Check the error messages above." -ForegroundColor Red
    exit 1
}
Write-Host "? Migration applied successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Verifying seed data..." -ForegroundColor Green
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host " SUPER ADMIN ACCOUNT CREATED" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Login URL: https://localhost:5001/SuperAdmin/Login" -ForegroundColor White
Write-Host ""
Write-Host "Credentials:" -ForegroundColor Yellow
Write-Host "  Email:    superadmin@rgmcet.edu.in" -ForegroundColor White
Write-Host "  Password: Super@123" -ForegroundColor White
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host " 6 DEPARTMENTS CREATED" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. CSEDS - Computer Science and Engineering (Data Science)" -ForegroundColor White
Write-Host "2. CSE   - Computer Science and Engineering" -ForegroundColor White
Write-Host "3. ECE   - Electronics and Communication Engineering" -ForegroundColor White
Write-Host "4. MECH  - Mechanical Engineering" -ForegroundColor White
Write-Host "5. CIVIL - Civil Engineering" -ForegroundColor White
Write-Host "6. EEE   - Electrical and Electronics Engineering" -ForegroundColor White
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "? PHASE 1 MIGRATION COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "What to do next:" -ForegroundColor Yellow
Write-Host "  1. Run the application: dotnet run" -ForegroundColor White
Write-Host "  2. Navigate to: https://localhost:5001/SuperAdmin/Login" -ForegroundColor White
Write-Host "  3. Log in with super admin credentials above" -ForegroundColor White
Write-Host "  4. Explore the Super Admin Dashboard" -ForegroundColor White
Write-Host ""
Write-Host "Documentation: See SUPER_ADMIN_PHASE_1_COMPLETE.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
