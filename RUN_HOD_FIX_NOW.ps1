# =====================================================
# RUN THIS NOW - Fix HOD Columns Database Error
# =====================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FIX HOD COLUMNS DATABASE ERROR" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Problem: Database still has HeadOfDepartment columns that are NOT NULL" -ForegroundColor Red
Write-Host "Solution: Drop these columns from the database" -ForegroundColor Green
Write-Host ""

# Get the SQL file path
$sqlFile = Join-Path $PSScriptRoot "Migrations\FIX_HOD_COLUMNS.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Host "? Error: SQL file not found at: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "?? SQL File: $sqlFile" -ForegroundColor Cyan
Write-Host ""

# Database connection settings
$Server = "localhost"
$Database = "Working5Db"

Write-Host "?? Executing SQL script..." -ForegroundColor Yellow
Write-Host ""

try {
    # Run the SQL script using sqlcmd
    $output = sqlcmd -S $Server -d $Database -i $sqlFile -b
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host $output
        Write-Host ""
        Write-Host "? SUCCESS! HOD columns removed from database" -ForegroundColor Green
        Write-Host ""
        Write-Host "?? Next Steps:" -ForegroundColor Cyan
        Write-Host "   1. Stop your application (if running)" -ForegroundColor White
        Write-Host "   2. Rebuild the solution" -ForegroundColor White
        Write-Host "   3. Start the application" -ForegroundColor White
        Write-Host "   4. Try creating a department again" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "? SQL execution failed" -ForegroundColor Red
        Write-Host $output
        exit 1
    }
}
catch {
    Write-Host "? Error executing SQL: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "?? Alternative: Run the SQL manually in SQL Server Management Studio" -ForegroundColor Yellow
    Write-Host "   File: $sqlFile" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
