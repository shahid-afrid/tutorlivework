# STANDARDIZE ALL DEPARTMENT SCHEMAS TO MATCH CSEDS
# =====================================================
# This script will:
# 1. Drop and recreate all department tables with CSEDS schema
# 2. Verify schema consistency across all departments
# 3. Show detailed results
# =====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SCHEMA STANDARDIZATION SCRIPT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get connection string from appsettings.json
$appsettingsPath = "appsettings.json"
if (-not (Test-Path $appsettingsPath)) {
    Write-Host "ERROR: appsettings.json not found!" -ForegroundColor Red
    exit 1
}

$appsettings = Get-Content $appsettingsPath | ConvertFrom-Json
$connectionString = $appsettings.ConnectionStrings.DefaultConnection

Write-Host "Connection String Found: Yes" -ForegroundColor Green
Write-Host "Database: Working5Db" -ForegroundColor Green
Write-Host ""

# Ask for confirmation
Write-Host "??  WARNING: This will DROP and RECREATE tables for departments:" -ForegroundColor Yellow
Write-Host "   - DES (Design)" -ForegroundColor Yellow
Write-Host "   - IT (Information Technology)" -ForegroundColor Yellow
Write-Host "   - ECE (Electronics and Communication)" -ForegroundColor Yellow
Write-Host "   - MECH (Mechanical Engineering)" -ForegroundColor Yellow
Write-Host ""
Write-Host "All tables will use the EXACT SAME schema as CSEDS" -ForegroundColor Yellow
Write-Host ""

$confirmation = Read-Host "Are you sure you want to continue? (YES/NO)"
if ($confirmation -ne "YES") {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 1: Standardizing Schemas" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Run standardization script
$standardizeScript = "Migrations/STANDARDIZE_ALL_DEPT_SCHEMAS_TO_CSEDS.sql"
if (-not (Test-Path $standardizeScript)) {
    Write-Host "ERROR: Migration script not found: $standardizeScript" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Executing standardization script..." -ForegroundColor Yellow
    sqlcmd -S localhost -d Working5Db -E -i $standardizeScript -b
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "? Schema standardization completed successfully!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "? Schema standardization failed!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Failed to execute standardization script" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "STEP 2: Verifying Schema Consistency" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Run verification script
$verifyScript = "Migrations/VERIFY_SCHEMA_CONSISTENCY.sql"
if (-not (Test-Path $verifyScript)) {
    Write-Host "ERROR: Verification script not found: $verifyScript" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Executing verification script..." -ForegroundColor Yellow
    sqlcmd -S localhost -d Working5Db -E -i $verifyScript -b
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "? Verification completed successfully!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "? Verification failed!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: Failed to execute verification script" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SCHEMA STANDARDIZATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "What was done:" -ForegroundColor White
Write-Host "? All department tables now have IDENTICAL schema to CSEDS" -ForegroundColor Green
Write-Host "? All 5 tables per department created:" -ForegroundColor Green
Write-Host "  - Faculty_{DEPT}" -ForegroundColor Gray
Write-Host "  - Students_{DEPT}" -ForegroundColor Gray
Write-Host "  - Subjects_{DEPT}" -ForegroundColor Gray
Write-Host "  - AssignedSubjects_{DEPT}" -ForegroundColor Gray
Write-Host "  - StudentEnrollments_{DEPT}" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "1. Run data migration: .\RUN_DATA_MIGRATION_ALL_DEPTS.ps1" -ForegroundColor Yellow
Write-Host "2. Test the application" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
