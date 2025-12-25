# =====================================================
# DYNAMIC TABLE MIGRATION - EXECUTION SCRIPT
# =====================================================
# Purpose: Execute the dynamic table migration
# Splits shared tables into department-specific tables
# =====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DYNAMIC TABLE MIGRATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$sqlFile = "Migrations\SplitToDepartmentTables.sql"
$connectionString = "Server=(localdb)\mssqllocaldb;Database=TutorLiveMentorDb;Trusted_Connection=True;MultipleActiveResultSets=true"

# Check if SQL file exists
if (-not (Test-Path $sqlFile)) {
    Write-Host "? ERROR: Migration file not found: $sqlFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected location:" -ForegroundColor Yellow
    Write-Host "  $((Get-Location).Path)\$sqlFile" -ForegroundColor Yellow
    exit 1
}

Write-Host "? Migration file found: $sqlFile" -ForegroundColor Green
Write-Host ""

# Read SQL content
$sqlContent = Get-Content $sqlFile -Raw

Write-Host "Migration Preview:" -ForegroundColor Yellow
Write-Host "  Tables to create: Faculty_CSEDS, Students_CSEDS, Subjects_CSEDS, ..." -ForegroundColor White
Write-Host "  Data to migrate: All CSEDS records from shared tables" -ForegroundColor White
Write-Host ""

# Confirm execution
Write-Host "? WARNING: This will create new tables and migrate data" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "Do you want to continue? (yes/no)"

if ($confirmation -ne "yes") {
    Write-Host ""
    Write-Host "? Migration cancelled by user" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "Starting migration..." -ForegroundColor Cyan
Write-Host ""

try {
    # Try using SqlServer module first
    if (Get-Module -ListAvailable -Name SqlServer) {
        Write-Host "Using SqlServer PowerShell module..." -ForegroundColor Gray
        
        Import-Module SqlServer -ErrorAction Stop
        
        Invoke-Sqlcmd -Query $sqlContent -ConnectionString $connectionString -QueryTimeout 300 -Verbose
        
        Write-Host ""
        Write-Host "? Migration completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "SqlServer module not found. Using ADO.NET..." -ForegroundColor Gray
        
        # Use ADO.NET as fallback
        Add-Type -AssemblyName System.Data
        
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = $sqlContent
        $command.CommandTimeout = 300
        
        Write-Host "Executing SQL commands..." -ForegroundColor Gray
        $rowsAffected = $command.ExecuteNonQuery()
        
        $connection.Close()
        
        Write-Host ""
        Write-Host "? Migration completed successfully!" -ForegroundColor Green
        Write-Host "  Rows affected: $rowsAffected" -ForegroundColor White
    }
}
catch {
    Write-Host ""
    Write-Host "? Migration failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if SQL Server is running" -ForegroundColor White
    Write-Host "  2. Verify connection string in script" -ForegroundColor White
    Write-Host "  3. Check if database 'TutorLiveMentorDb' exists" -ForegroundColor White
    Write-Host "  4. Run migration manually in SSMS" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Verify tables created
    $verifyQuery = @"
    SELECT 
        TABLE_NAME,
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = t.TABLE_NAME) AS ColumnCount
    FROM INFORMATION_SCHEMA.TABLES t
    WHERE TABLE_NAME LIKE '%_CSEDS'
    ORDER BY TABLE_NAME
"@

    Write-Host "Verifying CSEDS tables..." -ForegroundColor Gray
    Write-Host ""
    
    if (Get-Module -ListAvailable -Name SqlServer) {
        $tables = Invoke-Sqlcmd -Query $verifyQuery -ConnectionString $connectionString
        
        Write-Host "Tables Created:" -ForegroundColor Green
        foreach ($table in $tables) {
            Write-Host "  ? $($table.TABLE_NAME) ($($table.ColumnCount) columns)" -ForegroundColor White
        }
    }
    else {
        Write-Host "  Run this query manually to verify:" -ForegroundColor Yellow
        Write-Host $verifyQuery -ForegroundColor Gray
    }
}
catch {
    Write-Host "  ? Could not verify automatically" -ForegroundColor Yellow
    Write-Host "  Please verify manually in SQL Server" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. ? Tables created for CSEDS department" -ForegroundColor White
Write-Host "2. ? Data migrated from shared tables" -ForegroundColor White
Write-Host "3. ? Test CSEDS admin functionality" -ForegroundColor Yellow
Write-Host "4. ? Update remaining controllers to use DynamicDbContextFactory" -ForegroundColor Yellow
Write-Host "5. ? Run migration for other departments (CSE, ECE, etc.)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Documentation: DYNAMIC_DATABASE_ARCHITECTURE_GUIDE.md" -ForegroundColor Cyan
Write-Host ""

# Pause before exit
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
