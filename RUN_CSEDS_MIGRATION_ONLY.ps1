# =====================================================
# RUN CSEDS DYNAMIC TABLE MIGRATION - PHASE 1
# =====================================================
# Purpose: Create CSEDS-specific tables ONLY
# Other departments will continue using shared tables
# =====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CSEDS DYNAMIC TABLE MIGRATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$sqlFile = "Migrations\CREATE_CSEDS_FINAL.sql"
$connectionString = "Server=localhost;Database=Working5Db;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True"

# Check if SQL file exists
if (-not (Test-Path $sqlFile)) {
    Write-Host "? ERROR: Migration file not found: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "? Migration file found" -ForegroundColor Green
Write-Host ""

Write-Host "What this will do:" -ForegroundColor Yellow
Write-Host "  1. Create 5 CSEDS-specific tables" -ForegroundColor White
Write-Host "     - Faculty_CSEDS" -ForegroundColor Gray
Write-Host "     - Students_CSEDS" -ForegroundColor Gray
Write-Host "     - Subjects_CSEDS" -ForegroundColor Gray
Write-Host "     - AssignedSubjects_CSEDS" -ForegroundColor Gray
Write-Host "     - StudentEnrollments_CSEDS" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Migrate ALL CSEDS data from shared tables" -ForegroundColor White
Write-Host ""
Write-Host "  3. Other departments (DES, IT, ECE, MECH) continue using shared tables" -ForegroundColor White
Write-Host ""

# Confirm execution
$confirmation = Read-Host "Continue? (yes/no)"

if ($confirmation -ne "yes") {
    Write-Host ""
    Write-Host "? Migration cancelled" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "Starting migration..." -ForegroundColor Cyan
Write-Host ""

try {
    # Read SQL content
    $sqlContent = Get-Content $sqlFile -Raw

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
        $command.ExecuteNonQuery() | Out-Null
        
        $connection.Close()
        
        Write-Host ""
        Write-Host "? Migration completed successfully!" -ForegroundColor Green
    }
}
catch {
    Write-Host ""
    Write-Host "? Migration failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
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
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = t.TABLE_NAME) AS ColumnCount,
        (SELECT 
            CASE TABLE_NAME
                WHEN 'Faculty_CSEDS' THEN (SELECT COUNT(*) FROM Faculty_CSEDS)
                WHEN 'Students_CSEDS' THEN (SELECT COUNT(*) FROM Students_CSEDS)
                WHEN 'Subjects_CSEDS' THEN (SELECT COUNT(*) FROM Subjects_CSEDS)
                WHEN 'AssignedSubjects_CSEDS' THEN (SELECT COUNT(*) FROM AssignedSubjects_CSEDS)
                WHEN 'StudentEnrollments_CSEDS' THEN (SELECT COUNT(*) FROM StudentEnrollments_CSEDS)
                ELSE 0
            END
        ) AS RecordCount
    FROM INFORMATION_SCHEMA.TABLES t
    WHERE TABLE_NAME LIKE '%_CSEDS'
    ORDER BY TABLE_NAME
"@

    Write-Host "Verifying CSEDS tables..." -ForegroundColor Gray
    Write-Host ""
    
    if (Get-Module -ListAvailable -Name SqlServer) {
        $tables = Invoke-Sqlcmd -Query $verifyQuery -ConnectionString $connectionString
        
        Write-Host "CSEDS Tables Created:" -ForegroundColor Green
        foreach ($table in $tables) {
            Write-Host ("  ? {0,-30} {1,2} columns, {2,4} records" -f $table.TABLE_NAME, $table.ColumnCount, $table.RecordCount) -ForegroundColor White
        }
    }
}
catch {
    Write-Host "  ? Could not verify automatically" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. ? CSEDS tables created" -ForegroundColor Green
Write-Host "2. ? CSEDS data migrated" -ForegroundColor Green
Write-Host "3. ? Update AdminController for CSEDS" -ForegroundColor Yellow
Write-Host "4. ? Test CSEDS functionality" -ForegroundColor Yellow
Write-Host "5. ? Verify data isolation" -ForegroundColor Yellow
Write-Host ""
Write-Host "Other departments (DES, IT, ECE, MECH) still use shared tables ?" -ForegroundColor Gray
Write-Host ""

# Pause before exit
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
