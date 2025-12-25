# ============================================
# RUN MIGRATION FOR ALL DEPARTMENTS
# ============================================
# This script runs the migration to create dynamic tables
# for DES, IT, ECE, MECH departments
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DYNAMIC TABLE MIGRATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get connection string from appsettings.json
$appSettingsPath = Join-Path $PSScriptRoot "appsettings.json"

if (-not (Test-Path $appSettingsPath)) {
    Write-Host "? ERROR: appsettings.json not found at $appSettingsPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run this script from the project root directory." -ForegroundColor Yellow
    exit 1
}

$appSettings = Get-Content $appSettingsPath | ConvertFrom-Json
$connectionString = $appSettings.ConnectionStrings.DefaultConnection

if ([string]::IsNullOrEmpty($connectionString)) {
    Write-Host "? ERROR: Connection string not found in appsettings.json" -ForegroundColor Red
    exit 1
}

Write-Host "? Found connection string" -ForegroundColor Green
Write-Host ""

# Parse connection string to get database name
if ($connectionString -match "Initial Catalog=([^;]+)") {
    $databaseName = $matches[1]
    Write-Host "?? Database: $databaseName" -ForegroundColor Cyan
} else {
    Write-Host "? Warning: Could not parse database name from connection string" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION PLAN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This migration will:" -ForegroundColor White
Write-Host "  1. Create department-specific tables for:" -ForegroundColor White
Write-Host "     - DES (Design)" -ForegroundColor Yellow
Write-Host "     - IT (Information Technology)" -ForegroundColor Yellow
Write-Host "     - ECE (Electronics & Communication)" -ForegroundColor Yellow
Write-Host "     - MECH (Mechanical)" -ForegroundColor Yellow
Write-Host ""
Write-Host "  2. Tables created per department:" -ForegroundColor White
Write-Host "     - Faculty_{DeptCode}" -ForegroundColor Yellow
Write-Host "     - Students_{DeptCode}" -ForegroundColor Yellow
Write-Host "     - Subjects_{DeptCode}" -ForegroundColor Yellow
Write-Host "     - AssignedSubjects_{DeptCode}" -ForegroundColor Yellow
Write-Host "     - StudentEnrollments_{DeptCode}" -ForegroundColor Yellow
Write-Host ""
Write-Host "  3. Migrate existing data from shared tables" -ForegroundColor White
Write-Host "  4. Keep shared tables intact (backward compatibility)" -ForegroundColor White
Write-Host ""
Write-Host "? Estimated time: 2-5 minutes" -ForegroundColor Cyan
Write-Host ""

$confirmation = Read-Host "Do you want to proceed? (yes/no)"

if ($confirmation -ne "yes") {
    Write-Host ""
    Write-Host "? Migration cancelled by user" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RUNNING MIGRATION..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$migrationScript = Join-Path $PSScriptRoot "Migrations\MIGRATE_ALL_DEPARTMENTS_TO_DYNAMIC.sql"

if (-not (Test-Path $migrationScript)) {
    Write-Host "? ERROR: Migration script not found at $migrationScript" -ForegroundColor Red
    exit 1
}

try {
    # Execute the migration script
    Write-Host "?? Executing migration script..." -ForegroundColor Yellow
    Write-Host ""
    
    # Use Invoke-Sqlcmd if available, otherwise use sqlcmd.exe
    if (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue) {
        Invoke-Sqlcmd -ConnectionString $connectionString -InputFile $migrationScript -Verbose
        $exitCode = 0
    } else {
        # Parse connection string for sqlcmd
        $server = if ($connectionString -match "Server=([^;]+)") { $matches[1] } else { "localhost" }
        
        if ($connectionString -match "Integrated Security=true|Trusted_Connection=true") {
            sqlcmd -S $server -d $databaseName -E -i $migrationScript
        } elseif ($connectionString -match "User Id=([^;]+).*Password=([^;]+)") {
            $userId = $matches[1]
            $password = $matches[2]
            sqlcmd -S $server -d $databaseName -U $userId -P $password -i $migrationScript
        } else {
            throw "Could not parse connection string for sqlcmd"
        }
        
        $exitCode = $LASTEXITCODE
    }
    
    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "? MIGRATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "?? What was created:" -ForegroundColor Cyan
        Write-Host "  ? 20 new tables (5 per department)" -ForegroundColor Green
        Write-Host "  ? Data migrated from shared tables" -ForegroundColor Green
        Write-Host "  ? Foreign keys and constraints added" -ForegroundColor Green
        Write-Host ""
        Write-Host "?? Next Steps:" -ForegroundColor Cyan
        Write-Host "  1. Run verification script: .\VERIFY_ALL_DEPARTMENTS_MIGRATION.ps1" -ForegroundColor Yellow
        Write-Host "  2. Test admin login for each department" -ForegroundColor Yellow
        Write-Host "  3. Verify students can see subjects" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "?? Documentation:" -ForegroundColor Cyan
        Write-Host "  - See DYNAMIC_TABLE_VISUAL_GUIDE.md" -ForegroundColor White
        Write-Host "  - See START_HERE_DYNAMIC_TABLES.md" -ForegroundColor White
        Write-Host ""
    } else {
        throw "Migration script returned error code: $exitCode"
    }
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "? MIGRATION FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "?? Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if SQL Server is running" -ForegroundColor White
    Write-Host "  2. Verify connection string in appsettings.json" -ForegroundColor White
    Write-Host "  3. Check if you have permissions to create tables" -ForegroundColor White
    Write-Host "  4. Review error message above for details" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
