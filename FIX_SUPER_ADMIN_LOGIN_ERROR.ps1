# ============================================
# QUICK FIX - SUPER ADMIN LOGIN ERROR
# ============================================

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " FIXING SUPER ADMIN LOGIN ERROR" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Error: Cannot insert NULL into AuditLogs.IpAddress" -ForegroundColor Red
Write-Host "Fix: Making nullable fields in AuditLogs table" -ForegroundColor Green
Write-Host ""

Write-Host "Step 1: Stopping application (if running)..." -ForegroundColor Green
try {
    Stop-Process -Name "dotnet" -Force -ErrorAction SilentlyContinue
    Write-Host "? Application stopped" -ForegroundColor Green
} catch {
    Write-Host "? No running application found" -ForegroundColor Gray
}
Write-Host ""

Write-Host "Step 2: Applying database fix..." -ForegroundColor Green
try {
    # Run the SQL fix script
    $sqlScript = Get-Content "FIX_AUDIT_LOGS_NULL_ERROR.sql" -Raw
    
    # Get connection string from appsettings
    $appsettings = Get-Content "appsettings.json" | ConvertFrom-Json
    $connectionString = $appsettings.ConnectionStrings.DefaultConnection
    
    # Execute using sqlcmd if available
    if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
        Write-Host "Using sqlcmd to execute fix..." -ForegroundColor Cyan
        $sqlScript | sqlcmd -S "(localdb)\MSSQLLocalDB" -d "WorkingDb"
        Write-Host "? Database fix applied!" -ForegroundColor Green
    } else {
        Write-Host "sqlcmd not found. Please run FIX_AUDIT_LOGS_NULL_ERROR.sql manually" -ForegroundColor Yellow
        Write-Host "OR use SQL Server Management Studio" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Note: Run FIX_AUDIT_LOGS_NULL_ERROR.sql in SQL Server Management Studio" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "Step 3: Starting application..." -ForegroundColor Green
Write-Host "Run: dotnet run" -ForegroundColor Cyan
Write-Host ""

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " AFTER FIX IS APPLIED" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Start application:" -ForegroundColor White
Write-Host "   dotnet run" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Navigate to:" -ForegroundColor White
Write-Host "   https://localhost:5001/SuperAdmin/Login" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Login with:" -ForegroundColor White
Write-Host "   Email:    superadmin@rgmcet.edu.in" -ForegroundColor Yellow
Write-Host "   Password: Super@123" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. You should see the dashboard!" -ForegroundColor Green
Write-Host ""

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " WHAT WAS FIXED" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Issue:" -ForegroundColor Red
Write-Host "  - AuditLogs.IpAddress didn't allow NULL" -ForegroundColor White
Write-Host "  - Other fields also had NULL constraints" -ForegroundColor White
Write-Host ""
Write-Host "Solution:" -ForegroundColor Green
Write-Host "  - Made all optional fields nullable" -ForegroundColor White
Write-Host "  - Added default values:" -ForegroundColor White
Write-Host "    • IpAddress = '127.0.0.1'" -ForegroundColor Gray
Write-Host "    • ActionPerformedBy = 'System'" -ForegroundColor Gray
Write-Host "    • EntityType = ''" -ForegroundColor Gray
Write-Host "    • Status = 'Success'" -ForegroundColor Gray
Write-Host ""

Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
