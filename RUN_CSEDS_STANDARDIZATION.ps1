# =====================================================
# Execute Complete CSEDS Standardization Migration
# =====================================================
# This script runs the SQL migration to standardize
# all CSE(DS) variations to "CSEDS" in the database
# =====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "COMPLETE CSEDS STANDARDIZATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the connection string from appsettings.json
$appSettingsPath = "appsettings.json"

if (-not (Test-Path $appSettingsPath)) {
    Write-Host "ERROR: appsettings.json not found!" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory." -ForegroundColor Yellow
    exit 1
}

$appSettings = Get-Content $appSettingsPath -Raw | ConvertFrom-Json
$connectionString = $appSettings.ConnectionStrings.DefaultConnection

if ([string]::IsNullOrWhiteSpace($connectionString)) {
    Write-Host "ERROR: Connection string not found in appsettings.json!" -ForegroundColor Red
    exit 1
}

Write-Host "Connection string loaded successfully" -ForegroundColor Green
Write-Host ""

# SQL Migration file path
$sqlFilePath = "Migrations\COMPLETE_CSEDS_STANDARDIZATION.sql"

if (-not (Test-Path $sqlFilePath)) {
    Write-Host "ERROR: SQL migration file not found at: $sqlFilePath" -ForegroundColor Red
    exit 1
}

Write-Host "SQL migration file found: $sqlFilePath" -ForegroundColor Green
Write-Host ""

# Read the SQL script
$sqlScript = Get-Content $sqlFilePath -Raw

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "IMPORTANT: Before Proceeding" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "1. Update ALL department variations to 'CSEDS'" -ForegroundColor White
Write-Host "2. Affect tables: Departments, Students, Faculties, Subjects, Admins, SubjectAssignments" -ForegroundColor White
Write-Host "3. Convert: CSE(DS), CSE (DS), CSDS, CSE-DS, etc. -> CSEDS" -ForegroundColor White
Write-Host ""
Write-Host "The changes will be committed automatically." -ForegroundColor Cyan
Write-Host ""

$confirmation = Read-Host "Do you want to proceed? (yes/no)"

if ($confirmation -ne "yes") {
    Write-Host ""
    Write-Host "Migration cancelled by user." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Executing SQL Migration..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Execute the SQL script using sqlcmd with correct database
    $output = sqlcmd -S "localhost" -d "Working5Db" -i $sqlFilePath -b

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "ERROR: SQL execution failed!" -ForegroundColor Red
        Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host ""
        Write-Host "Output:" -ForegroundColor Yellow
        Write-Host $output -ForegroundColor White
        exit 1
    }

    Write-Host $output -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "MIGRATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "What was done:" -ForegroundColor Cyan
    Write-Host "1. All CSE(DS) variations converted to CSEDS" -ForegroundColor White
    Write-Host "2. Database now uses CSEDS consistently" -ForegroundColor White
    Write-Host "3. Changes committed to database" -ForegroundColor White
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Run: .\VERIFY_CSEDS_STANDARDIZATION.ps1" -ForegroundColor Yellow
    Write-Host "2. Test your application" -ForegroundColor Yellow
    Write-Host "3. Verify CSEDS students, subjects, and faculty display correctly" -ForegroundColor Yellow
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "ERROR: An exception occurred!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.Exception.StackTrace -ForegroundColor White
    exit 1
}
