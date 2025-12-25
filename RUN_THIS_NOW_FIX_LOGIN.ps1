# ============================================
# INSTANT FIX - Run This Now!
# ============================================

Write-Host "?? FIXING SUPER ADMIN LOGIN ERROR..." -ForegroundColor Cyan
Write-Host ""

# Connection string
$connectionString = "Server=(localdb)\MSSQLLocalDB;Database=WorkingDb;Trusted_Connection=True;MultipleActiveResultSets=true"

# SQL commands
$sqlCommands = @(
    "ALTER TABLE AuditLogs ALTER COLUMN ActionPerformedBy NVARCHAR(100) NULL",
    "ALTER TABLE AuditLogs ALTER COLUMN EntityType NVARCHAR(100) NULL",
    "ALTER TABLE AuditLogs ALTER COLUMN ActionDescription NVARCHAR(500) NULL",
    "ALTER TABLE AuditLogs ALTER COLUMN IpAddress NVARCHAR(50) NULL",
    "ALTER TABLE AuditLogs ALTER COLUMN OldValue NVARCHAR(MAX) NULL",
    "ALTER TABLE AuditLogs ALTER COLUMN NewValue NVARCHAR(MAX) NULL",
    "ALTER TABLE AuditLogs ALTER COLUMN Status NVARCHAR(50) NULL"
)

try {
    # Load SQL Client
    Add-Type -AssemblyName "System.Data.SqlClient"
    
    Write-Host "Connecting to database..." -ForegroundColor Yellow
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "? Connected to WorkingDb" -ForegroundColor Green
    Write-Host ""

    Write-Host "Fixing AuditLogs table columns..." -ForegroundColor Yellow
    foreach ($sql in $sqlCommands) {
        $command = New-Object System.Data.SqlClient.SqlCommand($sql, $connection)
        $command.ExecuteNonQuery() | Out-Null
        Write-Host "? Fixed: $($sql.Split(' ')[3])" -ForegroundColor Green
    }

    $connection.Close()
    
    Write-Host ""
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host " ? FIX APPLIED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Your app should still be running" -ForegroundColor White
    Write-Host "2. Just refresh the login page in browser" -ForegroundColor White
    Write-Host "3. Login again with:" -ForegroundColor White
    Write-Host "   Email:    " -NoNewline
    Write-Host "superadmin@rgmcet.edu.in" -ForegroundColor Cyan
    Write-Host "   Password: " -NoNewline
    Write-Host "Super@123" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "? IT WILL WORK NOW! ??" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "? Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "ALTERNATIVE FIX:" -ForegroundColor Yellow
    Write-Host "1. Open SQL Server Management Studio" -ForegroundColor White
    Write-Host "2. Connect to: (localdb)\MSSQLLocalDB" -ForegroundColor Cyan
    Write-Host "3. Run the file: FIX_AUDIT_LOGS_NULL_ERROR.sql" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
