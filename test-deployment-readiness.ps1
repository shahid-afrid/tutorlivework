# Test Deployment Readiness
# This script verifies your setup before deploying to Azure

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   AZURE DEPLOYMENT READINESS TEST" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# Test 1: Check if .NET 8 is installed
Write-Host "Test 1: Checking .NET 8 SDK..." -ForegroundColor Yellow
try {
    $dotnetVersion = dotnet --version
    if ($dotnetVersion -like "8.*") {
        Write-Host "? .NET 8 SDK found: $dotnetVersion" -ForegroundColor Green
    } else {
        Write-Host "? .NET 8 SDK not found. Current version: $dotnetVersion" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "? .NET SDK not installed" -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# Test 2: Check if EF Core tools are installed
Write-Host "Test 2: Checking EF Core Tools..." -ForegroundColor Yellow
try {
    $efVersion = dotnet ef --version
    Write-Host "? EF Core Tools installed: $efVersion" -ForegroundColor Green
} catch {
    Write-Host "? EF Core Tools not installed. Installing..." -ForegroundColor Yellow
    dotnet tool install --global dotnet-ef
    Write-Host "? EF Core Tools installed" -ForegroundColor Green
}
Write-Host ""

# Test 3: Check if project builds
Write-Host "Test 3: Building project..." -ForegroundColor Yellow
$buildResult = dotnet build TutorLiveMentor10.csproj --configuration Release 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "? Project builds successfully" -ForegroundColor Green
} else {
    Write-Host "? Build failed:" -ForegroundColor Red
    Write-Host $buildResult -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# Test 4: Check appsettings.Production.json
Write-Host "Test 4: Checking appsettings.Production.json..." -ForegroundColor Yellow
if (Test-Path "appsettings.Production.json") {
    $settings = Get-Content "appsettings.Production.json" -Raw | ConvertFrom-Json
    $connString = $settings.ConnectionStrings.DefaultConnection
    
    if ($connString -like "*tutorlive-sql-server*") {
        Write-Host "? Production connection string configured" -ForegroundColor Green
        
        # Check if password is placeholder
        if ($connString -like "*YOUR_ACTUAL_PASSWORD_HERE*") {
            Write-Host "? WARNING: Update password in appsettings.Production.json" -ForegroundColor Yellow
        }
    } else {
        Write-Host "? Connection string not configured for Azure" -ForegroundColor Red
        $allPassed = $false
    }
} else {
    Write-Host "? appsettings.Production.json not found" -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# Test 5: Check GitHub workflow file
Write-Host "Test 5: Checking GitHub workflow..." -ForegroundColor Yellow
if (Test-Path ".github\workflows\azure-deploy.yml") {
    Write-Host "? GitHub workflow file exists" -ForegroundColor Green
} else {
    Write-Host "? GitHub workflow file not found" -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# Test 6: Check migrations exist
Write-Host "Test 6: Checking migrations..." -ForegroundColor Yellow
$migrations = Get-ChildItem -Path "Migrations" -Filter "*.cs" -ErrorAction SilentlyContinue
if ($migrations.Count -gt 0) {
    Write-Host "? Found $($migrations.Count) migration files" -ForegroundColor Green
} else {
    Write-Host "? No migrations found - database might be empty" -ForegroundColor Yellow
}
Write-Host ""

# Test 7: Test Azure SQL Connection (if credentials provided)
Write-Host "Test 7: Testing Azure SQL Connection..." -ForegroundColor Yellow
Write-Host "Would you like to test the Azure SQL connection now? (Y/N)" -ForegroundColor Cyan
$testSQL = Read-Host

if ($testSQL -eq "Y" -or $testSQL -eq "y") {
    Write-Host ""
    Write-Host "Enter your Azure SQL details:" -ForegroundColor Cyan
    $serverName = Read-Host "Server name (e.g., tutorlive-sql-server.database.windows.net)"
    $databaseName = Read-Host "Database name (default: TutorLiveMentorDB)"
    if ([string]::IsNullOrWhiteSpace($databaseName)) { $databaseName = "TutorLiveMentorDB" }
    $userName = Read-Host "SQL admin username (default: sqladmin)"
    if ([string]::IsNullOrWhiteSpace($userName)) { $userName = "sqladmin" }
    $password = Read-Host "SQL admin password" -AsSecureString
    $passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    
    $connectionString = "Server=tcp:$serverName,1433;Initial Catalog=$databaseName;User ID=$userName;Password=$passwordText;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    try {
        Add-Type -AssemblyName System.Data
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        Write-Host "? Successfully connected to Azure SQL Database!" -ForegroundColor Green
        $connection.Close()
    } catch {
        Write-Host "? Failed to connect to Azure SQL:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $allPassed = $false
    }
} else {
    Write-Host "? Skipped SQL connection test" -ForegroundColor Gray
}
Write-Host ""

# Final Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "           READINESS SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if ($allPassed) {
    Write-Host "? ALL CHECKS PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your project is ready for deployment!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Update password in appsettings.Production.json (if needed)" -ForegroundColor White
    Write-Host "2. Configure GitHub Secrets (AZURE_WEBAPP_PUBLISH_PROFILE & AZURE_SQL_CONNECTION_STRING)" -ForegroundColor White
    Write-Host "3. Commit and push to GitHub" -ForegroundColor White
    Write-Host "4. Deployment will start automatically" -ForegroundColor White
} else {
    Write-Host "??  SOME CHECKS FAILED" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please fix the errors above before deploying." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
