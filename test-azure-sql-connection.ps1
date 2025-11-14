# Test Azure SQL Connection
# This script helps diagnose connection issues to Azure SQL Server

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Azure SQL Connection Test Tool" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Connection details from appsettings.Production.json
$serverName = "tutorlive-sql-server.database.windows.net"
$databaseName = "TutorLiveMentorDB"
$userName = "sqladmin"
$password = "8919427828Aa"

Write-Host "Testing connection to:" -ForegroundColor Yellow
Write-Host "  Server: $serverName" -ForegroundColor White
Write-Host "  Database: $databaseName" -ForegroundColor White
Write-Host "  User: $userName" -ForegroundColor White
Write-Host ""

# Build connection string
$connectionString = "Server=tcp:$serverName,1433;Initial Catalog=$databaseName;Persist Security Info=False;User ID=$userName;Password=$password;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "Attempting to connect..." -ForegroundColor Yellow

try {
    # Load SQL Client
    Add-Type -AssemblyName System.Data

    # Create connection
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    
    # Try to open connection
    $connection.Open()
    
    Write-Host ""
    Write-Host "? SUCCESS!" -ForegroundColor Green
    Write-Host "Successfully connected to Azure SQL Database!" -ForegroundColor Green
    Write-Host ""
    
    # Check if Admins table exists
    Write-Host "Testing database schema..." -ForegroundColor Yellow
    try {
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT COUNT(*) FROM Admins"
        $adminCount = $command.ExecuteScalar()
        
        Write-Host "? Admins table exists with $adminCount admin(s)" -ForegroundColor Green
        Write-Host ""
        
        # Get admin details
        $command.CommandText = "SELECT Email, Department FROM Admins"
        $reader = $command.ExecuteReader()
        
        Write-Host "Admin accounts in database:" -ForegroundColor Cyan
        while ($reader.Read()) {
            Write-Host "  - $($reader["Email"]) (Department: $($reader["Department"]))" -ForegroundColor White
        }
        $reader.Close()
        
    } catch {
        Write-Host "? Admins table does not exist yet" -ForegroundColor Yellow
        Write-Host "   This is normal if migrations haven't run yet" -ForegroundColor Gray
        Write-Host "   Migrations will create tables during deployment" -ForegroundColor Gray
    }
    
    $connection.Close()
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "CONNECTION TEST PASSED!" -ForegroundColor Green
    Write-Host "Your Azure SQL Server is ready for deployment" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "? CONNECTION FAILED!" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Message:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Message -like "*Cannot open server*" -or $_.Exception.Message -like "*firewall*") {
        Write-Host "DIAGNOSIS: Firewall Issue" -ForegroundColor Yellow
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Your IP address is blocked by Azure SQL Server firewall." -ForegroundColor White
        Write-Host ""
        Write-Host "TO FIX THIS:" -ForegroundColor Cyan
        Write-Host "1. Go to Azure Portal: https://portal.azure.com" -ForegroundColor White
        Write-Host "2. Navigate to: SQL servers ? tutorlive-sql-server" -ForegroundColor White
        Write-Host "3. Go to: Security ? Networking" -ForegroundColor White
        Write-Host "4. Under 'Firewall rules', click '+ Add client IP'" -ForegroundColor White
        Write-Host "5. OR enable 'Allow Azure services and resources to access this server'" -ForegroundColor White
        Write-Host "6. Click 'Save'" -ForegroundColor White
        Write-Host ""
        Write-Host "Your current public IP:" -ForegroundColor Yellow
        try {
            $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
            Write-Host "  $publicIP" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Add this IP to your Azure SQL firewall rules!" -ForegroundColor Green
        } catch {
            Write-Host "  (Could not detect IP automatically)" -ForegroundColor Gray
        }
        
    } elseif ($_.Exception.Message -like "*Login failed*") {
        Write-Host "DIAGNOSIS: Authentication Issue" -ForegroundColor Yellow
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "The username or password is incorrect." -ForegroundColor White
        Write-Host ""
        Write-Host "TO FIX THIS:" -ForegroundColor Cyan
        Write-Host "1. Go to Azure Portal: https://portal.azure.com" -ForegroundColor White
        Write-Host "2. Navigate to: SQL servers ? tutorlive-sql-server" -ForegroundColor White
        Write-Host "3. Verify the admin username and reset password if needed" -ForegroundColor White
        Write-Host "4. Update credentials in this script and appsettings.Production.json" -ForegroundColor White
        
    } else {
        Write-Host "DIAGNOSIS: Unknown Issue" -ForegroundColor Yellow
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please check:" -ForegroundColor White
        Write-Host "- Azure SQL Server 'tutorlive-sql-server' exists" -ForegroundColor White
        Write-Host "- Database 'TutorLiveMentorDB' exists" -ForegroundColor White
        Write-Host "- Credentials are correct" -ForegroundColor White
        Write-Host "- Network connectivity" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
