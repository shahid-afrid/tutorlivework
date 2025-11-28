# ?? Azure Deployment - Complete Step-by-Step Guide

## ?? **PREREQUISITES CHECKLIST**
Before starting, ensure you have:
- ? Azure account (free tier works for testing)
- ? GitHub account (your repo: https://github.com/shahid-afrid/tutorlivev1)
- ? Azure CLI installed (https://aka.ms/installazurecliwindows)
- ? Visual Studio Code or Visual Studio 2022

---

## ?? **PART 1: CREATE AZURE RESOURCES** (15 minutes)

### **Step 1.1: Login to Azure**

Open PowerShell/Command Prompt and run:

```powershell
# Login to Azure
az login

# Verify you're logged in
az account show

# If you have multiple subscriptions, set the one you want to use
az account list --output table
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### **Step 1.2: Set Your Variables**

Copy and paste this in PowerShell (customize the values):

```powershell
# CUSTOMIZE THESE VALUES
$RESOURCE_GROUP = "TutorLiveMentorRG"
$LOCATION = "centralindia"  # or "eastus", "westeurope", etc.
$SQL_SERVER = "tutorlivev1-sql-server"  # Must be globally unique
$SQL_DB = "TutorLiveV1DB"
$SQL_ADMIN = "sqladmin"
$SQL_PASSWORD = "YourStrongP@ssw0rd123!"  # CHANGE THIS!
$APP_PLAN = "TutorLiveMentorPlan"
$WEB_APP = "tutorlive-app"  # Must be globally unique

# Display your configuration
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AZURE DEPLOYMENT CONFIGURATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Resource Group: $RESOURCE_GROUP"
Write-Host "Location: $LOCATION"
Write-Host "SQL Server: $SQL_SERVER"
Write-Host "SQL Database: $SQL_DB"
Write-Host "Web App: $WEB_APP"
Write-Host "========================================" -ForegroundColor Cyan
```

### **Step 1.3: Create Resource Group**

```powershell
Write-Host "Creating Resource Group..." -ForegroundColor Yellow
az group create --name $RESOURCE_GROUP --location $LOCATION

# Verify it was created
az group show --name $RESOURCE_GROUP
```

? **SUCCESS CHECK**: You should see JSON output showing your resource group details.

### **Step 1.4: Create SQL Server**

```powershell
Write-Host "Creating SQL Server..." -ForegroundColor Yellow
az sql server create `
  --name $SQL_SERVER `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --admin-user $SQL_ADMIN `
  --admin-password $SQL_PASSWORD

# Configure firewall to allow Azure services
Write-Host "Configuring SQL Server firewall..." -ForegroundColor Yellow
az sql server firewall-rule create `
  --resource-group $RESOURCE_GROUP `
  --server $SQL_SERVER `
  --name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0

# Add your current IP to access from your machine
az sql server firewall-rule create `
  --resource-group $RESOURCE_GROUP `
  --server $SQL_SERVER `
  --name AllowMyIP `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 255.255.255.255
```

? **SUCCESS CHECK**: SQL Server should be created with firewall rules.

### **Step 1.5: Create SQL Database**

```powershell
Write-Host "Creating SQL Database..." -ForegroundColor Yellow
az sql db create `
  --resource-group $RESOURCE_GROUP `
  --server $SQL_SERVER `
  --name $SQL_DB `
  --service-objective Basic `
  --backup-storage-redundancy Local
```

? **SUCCESS CHECK**: Database created successfully.

### **Step 1.6: Get SQL Connection String**

```powershell
Write-Host "========================================" -ForegroundColor Green
Write-Host "SQL CONNECTION STRING" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$CONNECTION_STRING = "Server=tcp:$SQL_SERVER.database.windows.net,1433;Initial Catalog=$SQL_DB;Persist Security Info=False;User ID=$SQL_ADMIN;Password=$SQL_PASSWORD;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host $CONNECTION_STRING -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
Write-Host "SAVE THIS CONNECTION STRING!" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

# Save to a file for safekeeping
$CONNECTION_STRING | Out-File -FilePath "connection-string.txt"
Write-Host "Also saved to: connection-string.txt" -ForegroundColor Green
```

?? **IMPORTANT**: Copy this connection string! You'll need it for GitHub Secrets.

### **Step 1.7: Create App Service Plan**

```powershell
Write-Host "Creating App Service Plan..." -ForegroundColor Yellow
az appservice plan create `
  --name $APP_PLAN `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --sku B1 `
  --is-linux
```

### **Step 1.8: Create Web App**

```powershell
Write-Host "Creating Web App..." -ForegroundColor Yellow
az webapp create `
  --name $WEB_APP `
  --resource-group $RESOURCE_GROUP `
  --plan $APP_PLAN `
  --runtime "DOTNETCORE:8.0"

# Get the Web App URL
$WEB_APP_URL = az webapp show --name $WEB_APP --resource-group $RESOURCE_GROUP --query defaultHostName -o tsv

Write-Host "========================================" -ForegroundColor Green
Write-Host "WEB APP CREATED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "URL: https://$WEB_APP_URL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
```

### **Step 1.9: Configure Web App Settings**

```powershell
Write-Host "Configuring Web App settings..." -ForegroundColor Yellow

# Set connection string
az webapp config connection-string set `
  --name $WEB_APP `
  --resource-group $RESOURCE_GROUP `
  --connection-string-type SQLServer `
  --settings DefaultConnection="$CONNECTION_STRING"

# Set application settings
az webapp config appsettings set `
  --name $WEB_APP `
  --resource-group $RESOURCE_GROUP `
  --settings `
    ASPNETCORE_ENVIRONMENT="Production" `
    ServerSettings__ServerMode="Cloud" `
    AllowedHosts="*"

Write-Host "Web App configured successfully!" -ForegroundColor Green
```

### **Step 1.10: Get Publish Profile**

```powershell
Write-Host "Downloading Publish Profile..." -ForegroundColor Yellow
az webapp deployment list-publishing-profiles `
  --name $WEB_APP `
  --resource-group $RESOURCE_GROUP `
  --xml | Out-File -FilePath "publish-profile.xml"

Write-Host "========================================" -ForegroundColor Green
Write-Host "Publish Profile saved to: publish-profile.xml" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
```

? **PART 1 COMPLETE!** All Azure resources are created!

---

## ?? **PART 2: CONFIGURE GITHUB SECRETS** (5 minutes)

### **Step 2.1: Open GitHub Repository**

1. Go to: https://github.com/shahid-afrid/tutorlivev1
2. Click **Settings** (top menu)
3. Click **Secrets and variables** ? **Actions** (left sidebar)

### **Step 2.2: Add AZURE_WEBAPP_PUBLISH_PROFILE**

1. Click **New repository secret**
2. Name: `AZURE_WEBAPP_PUBLISH_PROFILE`
3. Value: Open the `publish-profile.xml` file you downloaded and copy ALL its content
4. Click **Add secret**

? **SUCCESS CHECK**: Secret "AZURE_WEBAPP_PUBLISH_PROFILE" should appear in the list.

### **Step 2.3: Add AZURE_SQL_CONNECTION_STRING**

1. Click **New repository secret**
2. Name: `AZURE_SQL_CONNECTION_STRING`
3. Value: Paste the connection string from Step 1.6
4. Click **Add secret**

? **SUCCESS CHECK**: You should now have 2 secrets.

---

## ?? **PART 3: UPDATE YOUR FILES** (5 minutes)

### **Step 3.1: Update appsettings.Production.json**

You need to update the connection string in your `appsettings.Production.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=tcp:YOUR_SQL_SERVER.database.windows.net,1433;Initial Catalog=YOUR_DB_NAME;Persist Security Info=False;User ID=YOUR_SQL_ADMIN;Password=__REPLACE_WITH_ENVIRONMENT_VARIABLE__;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Information"
    }
  },
  "AllowedHosts": "*",
  "ServerSettings": {
    "ApplicationName": "TutorLiveMentor",
    "ServerMode": "Cloud",
    "HttpPort": 80,
    "HttpsPort": 443
  }
}
```

Replace:
- `YOUR_SQL_SERVER` with your SQL Server name (e.g., `tutorlivev1-sql-server`)
- `YOUR_DB_NAME` with your database name (e.g., `TutorLiveV1DB`)
- `YOUR_SQL_ADMIN` with your SQL admin username (e.g., `sqladmin`)
- Keep the `__REPLACE_WITH_ENVIRONMENT_VARIABLE__` as is (Azure will replace it)

### **Step 3.2: Update azure-deploy.yml**

Update the `AZURE_WEBAPP_NAME` in your workflow file:

```yaml
env:
  AZURE_WEBAPP_NAME: tutorlive-app  # Change this to YOUR web app name
  DOTNET_VERSION: '8.0.x'
  SOLUTION_PATH: 'TutorLiveMentor10.csproj'  # NO .sln file needed
  PROJECT_PATH: 'TutorLiveMentor10.csproj'
```

Also, update the URL in the verify step (at the bottom):

```yaml
HEALTH_URL="https://YOUR_WEB_APP_NAME.azurewebsites.net/health"
```

Replace `YOUR_WEB_APP_NAME` with your actual web app name.

---

## ?? **PART 4: DEPLOY** (10 minutes)

### **Step 4.1: Create Solution File (if missing)**

Your workflow references `TutorLiveMentor.sln` but it might not exist. Let's fix this:

**Option A: Remove .sln reference** (EASIEST)

Update your `azure-deploy.yml`:

```yaml
- name: Restore dependencies
  run: dotnet restore ${{ env.PROJECT_PATH }}

- name: Build application
  run: dotnet build ${{ env.PROJECT_PATH }} --configuration Release --no-restore
```

Remove `${{ env.SOLUTION_PATH }}` and use `${{ env.PROJECT_PATH }}` instead.

**Option B: Create solution file**

```powershell
cd C:\Users\shahi\Source\Repos\tutor-livev1
dotnet new sln -n TutorLiveMentor
dotnet sln add TutorLiveMentor10.csproj
```

### **Step 4.2: Commit and Push Changes**

```powershell
cd C:\Users\shahi\Source\Repos\tutor-livev1

git add .
git commit -m "Configure Azure deployment"
git push origin main
```

### **Step 4.3: Enable GitHub Actions**

1. Go to your GitHub repo: https://github.com/shahid-afrid/tutorlivev1
2. Click **Actions** tab
3. If prompted, click **"I understand my workflows, go ahead and enable them"**
4. You should see your workflow: "Build and Deploy to Azure App Service"
5. Click on it to watch the deployment

### **Step 4.4: Monitor Deployment**

The workflow will run automatically on push. You'll see 4 jobs:

1. ? **build** - Builds your application (~2 minutes)
2. ? **deploy** - Deploys to Azure (~3 minutes)
3. ? **migrate** - Runs database migrations (~2 minutes)
4. ? **verify** - Health checks (~2 minutes)

Total time: ~10 minutes

---

## ? **PART 5: VERIFY DEPLOYMENT** (5 minutes)

### **Step 5.1: Check Web App**

Open your browser and go to:
```
https://YOUR_WEB_APP_NAME.azurewebsites.net
```

You should see your TutorLiveMentor home page!

### **Step 5.2: Check Health Endpoint**

```
https://YOUR_WEB_APP_NAME.azurewebsites.net/health
```

Should return: `Healthy`

### **Step 5.3: Test Admin Login**

```
URL: https://YOUR_WEB_APP_NAME.azurewebsites.net/Admin/Login
Email: cseds@rgmcet.edu.in
Password: 9059530688
```

---

## ?? **TROUBLESHOOTING**

### Issue: Workflow fails at "restore dependencies"

**Solution**: Your workflow references a .sln file that doesn't exist.

Fix in `azure-deploy.yml`:
```yaml
env:
  PROJECT_PATH: 'TutorLiveMentor10.csproj'
  # Remove or comment out SOLUTION_PATH

# Update all references from ${{ env.SOLUTION_PATH }} to ${{ env.PROJECT_PATH }}
```

### Issue: "Connection string not found"

**Solution**: Check Azure configuration:

```powershell
# View current connection strings
az webapp config connection-string list `
  --name $WEB_APP `
  --resource-group $RESOURCE_GROUP

# Re-set if missing
az webapp config connection-string set `
  --name $WEB_APP `
  --resource-group $RESOURCE_GROUP `
  --connection-string-type SQLServer `
  --settings DefaultConnection="YOUR_CONNECTION_STRING"
```

### Issue: Database migration fails

**Solution**: Check if the secret is correct:

1. Go to GitHub ? Settings ? Secrets
2. Verify `AZURE_SQL_CONNECTION_STRING` is set correctly
3. Update if needed and re-run the workflow

### Issue: 500 error on website

**Solution**: Check logs:

```powershell
# Stream logs
az webapp log tail `
  --name $WEB_APP `
  --resource-group $RESOURCE_GROUP

# Or enable detailed errors temporarily
az webapp config appsettings set `
  --name $WEB_APP `
  --resource-group $RESOURCE_GROUP `
  --settings ASPNETCORE_DETAILEDERRORS="true"
```

---

## ?? **COST ESTIMATE**

With the Basic B1 tier setup:
- **App Service Plan (B1)**: ~$13/month
- **SQL Database (Basic)**: ~$5/month
- **Total**: ~$18/month

To reduce costs for testing:
```powershell
# Downgrade to Free tier (testing only)
az appservice plan update `
  --name $APP_PLAN `
  --resource-group $RESOURCE_GROUP `
  --sku FREE
```

---

## ?? **SUCCESS CHECKLIST**

- [ ] Azure resources created
- [ ] GitHub secrets configured
- [ ] Files updated (appsettings.Production.json, azure-deploy.yml)
- [ ] Code pushed to GitHub
- [ ] GitHub Actions workflow ran successfully
- [ ] Website loads at https://YOUR_WEB_APP_NAME.azurewebsites.net
- [ ] Health check returns "Healthy"
- [ ] Admin login works
- [ ] Database has tables and data

---

## ?? **QUICK COMMANDS REFERENCE**

```powershell
# View all resources
az resource list --resource-group $RESOURCE_GROUP --output table

# Restart web app
az webapp restart --name $WEB_APP --resource-group $RESOURCE_GROUP

# View logs
az webapp log tail --name $WEB_APP --resource-group $RESOURCE_GROUP

# Stop web app (to save costs)
az webapp stop --name $WEB_APP --resource-group $RESOURCE_GROUP

# Start web app
az webapp start --name $WEB_APP --resource-group $RESOURCE_GROUP

# Delete everything (cleanup)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

---

## ?? **NEED HELP?**

If you encounter issues:

1. **Check GitHub Actions logs**: https://github.com/shahid-afrid/tutorlivev1/actions
2. **Check Azure logs**: 
   ```powershell
   az webapp log tail --name $WEB_APP --resource-group $RESOURCE_GROUP
   ```
3. **Verify secrets**: GitHub ? Settings ? Secrets and variables ? Actions

---

**?? YOU'RE READY TO DEPLOY! ??**

Start with **PART 1** and work through each step. Good luck! ??
