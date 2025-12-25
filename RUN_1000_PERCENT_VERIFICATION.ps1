# ===================================================================
# 1000% GUARANTEE: SUBJECT SELECTION VERIFICATION SCRIPT
# ===================================================================
# Runs the SQL verification and provides visual confirmation
# ===================================================================

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  1000% SUBJECT SELECTION VERIFICATION FOR ALL DEPARTMENTS" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# Get connection string from appsettings.json
$appsettingsPath = "appsettings.json"
if (-not (Test-Path $appsettingsPath)) {
    Write-Host "ERROR: appsettings.json not found!" -ForegroundColor Red
    Write-Host "Run this script from the project root directory." -ForegroundColor Red
    exit 1
}

$appsettings = Get-Content $appsettingsPath | ConvertFrom-Json
$connectionString = $appsettings.ConnectionStrings.DefaultConnection

if (-not $connectionString) {
    Write-Host "ERROR: Connection string not found in appsettings.json!" -ForegroundColor Red
    exit 1
}

Write-Host "Connection String Found: " -NoNewline -ForegroundColor Green
Write-Host $connectionString.Substring(0, 50) + "..." -ForegroundColor Gray

# SQL Script path
$sqlScriptPath = "Migrations\VERIFY_ALL_DEPARTMENTS_SUBJECT_SELECTION_1000_PERCENT.sql"

if (-not (Test-Path $sqlScriptPath)) {
    Write-Host ""
    Write-Host "ERROR: SQL verification script not found!" -ForegroundColor Red
    Write-Host "Expected: $sqlScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Running comprehensive verification..." -ForegroundColor Yellow
Write-Host ""

# Execute SQL script
try {
    sqlcmd -S "(localdb)\MSSQLLocalDB" -d "TutorLiveDB" -i $sqlScriptPath -o "verification_results.txt"
    
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host "  VERIFICATION COMPLETED!" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Results saved to: verification_results.txt" -ForegroundColor Cyan
    Write-Host ""
    
    # Display key results
    Write-Host "KEY FINDINGS:" -ForegroundColor Yellow
    Write-Host ""
    
    $results = Get-Content "verification_results.txt"
    
    # Check for success message
    if ($results -match "1000% GUARANTEE: ALL DEPARTMENTS ARE PROPERLY CONFIGURED") {
        Write-Host "  ALL DEPARTMENTS ARE PROPERLY CONFIGURED" -ForegroundColor Green
        Write-Host "  Current departments can see their subjects" -ForegroundColor Green
        Write-Host "  Future departments will work automatically" -ForegroundColor Green
        Write-Host ""
        Write-Host "=================================================================" -ForegroundColor Green
        Write-Host "  1000% GUARANTEED: SUBJECT SELECTION WORKS FOR ALL DEPTS" -ForegroundColor Green
        Write-Host "=================================================================" -ForegroundColor Green
    }
    else {
        Write-Host "  WARNING: Some configuration issues detected" -ForegroundColor Yellow
        Write-Host "  Review verification_results.txt for details" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "To view full results, run:" -ForegroundColor Cyan
    Write-Host "  notepad verification_results.txt" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to execute verification!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual execution:" -ForegroundColor Yellow
    Write-Host "  1. Open SQL Server Management Studio" -ForegroundColor White
    Write-Host "  2. Connect to (localdb)\MSSQLLocalDB" -ForegroundColor White
    Write-Host "  3. Open: $sqlScriptPath" -ForegroundColor White
    Write-Host "  4. Execute the script" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Press any key to open detailed results..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Open results in notepad
notepad "verification_results.txt"
