# Azure Configuration Check Script
# Run this in PowerShell to verify your Azure setup

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "AZURE CONFIGURATION CHECKER" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
Write-Host "1. Checking Azure CLI..." -ForegroundColor Yellow
$azInstalled = Get-Command az -ErrorAction SilentlyContinue
if ($azInstalled) {
    Write-Host "   ? Azure CLI is installed" -ForegroundColor Green
} else {
    Write-Host "   ? Azure CLI not found. Install from: https://aka.ms/installazurecliwindows" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "2. Checking Azure login status..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if ($account) {
    Write-Host "   ? Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   ? Subscription: $($account.name)" -ForegroundColor Green
} else {
    Write-Host "   ? Not logged in to Azure" -ForegroundColor Red
    Write-Host "   ? Run: az login" -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "3. Searching for TutorLive app..." -ForegroundColor Yellow
$apps = az webapp list --query "[?contains(name,'TutorLive') || contains(name,'tutorlive')].{Name:name, ResourceGroup:resourceGroup, State:state, DefaultHostName:defaultHostName}" | ConvertFrom-Json

if ($apps.Count -eq 0) {
    Write-Host "   ? No app found with 'TutorLive' in name" -ForegroundColor Red
    Write-Host ""
    Write-Host "   All your apps:" -ForegroundColor Yellow
    az webapp list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table
} else {
    foreach ($app in $apps) {
        Write-Host "   ? Found: $($app.Name)" -ForegroundColor Green
        Write-Host "     Resource Group: $($app.ResourceGroup)" -ForegroundColor Gray
        Write-Host "     State: $($app.State)" -ForegroundColor Gray
        Write-Host "     URL: https://$($app.DefaultHostName)" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "4. Checking app settings for: $($app.Name)..." -ForegroundColor Yellow
        $settings = az webapp config appsettings list --name $app.Name --resource-group $app.ResourceGroup | ConvertFrom-Json
        
        $requiredSettings = @("ASPNETCORE_ENVIRONMENT", "ServerSettings__ServerMode")
        $foundSettings = @()
        
        foreach ($setting in $settings) {
            if ($requiredSettings -contains $setting.name) {
                $foundSettings += $setting.name
                Write-Host "   ? $($setting.name) = $($setting.value)" -ForegroundColor Green
            }
        }
        
        $missingSettings = $requiredSettings | Where-Object { $foundSettings -notcontains $_ }
        if ($missingSettings.Count -gt 0) {
            Write-Host "   ? Missing settings:" -ForegroundColor Red
            foreach ($missing in $missingSettings) {
                Write-Host "     - $missing" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "5. Checking connection strings..." -ForegroundColor Yellow
        $connStrings = az webapp config connection-string list --name $app.Name --resource-group $app.ResourceGroup | ConvertFrom-Json
        
        if ($connStrings.PSObject.Properties.Name -contains "DefaultConnection") {
            Write-Host "   ? DefaultConnection is configured" -ForegroundColor Green
        } else {
            Write-Host "   ? DefaultConnection NOT configured" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "6. Checking recent logs..." -ForegroundColor Yellow
        Write-Host "   Fetching last 50 log entries..." -ForegroundColor Gray
        az webapp log tail --name $app.Name --resource-group $app.ResourceGroup --only-show-errors 2>&1 | Select-Object -First 50
    }
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "CHECK COMPLETE" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
