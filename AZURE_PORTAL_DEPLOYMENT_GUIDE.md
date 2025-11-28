# ?? Azure Deployment via Azure Portal - Complete Guide

## ?? **WHAT YOU NEED**
- ? Azure account (https://azure.microsoft.com/free/)
- ? GitHub account with your repo: https://github.com/shahid-afrid/tutorlivev1
- ? 30 minutes of your time

**NO Azure CLI needed! Everything done in browser! ??**

---

## ?? **PART 1: CREATE AZURE RESOURCES VIA PORTAL** (20 minutes)

### **Step 1: Login to Azure Portal**

1. Open browser and go to: https://portal.azure.com
2. Sign in with your Microsoft account
3. You should see the Azure Portal dashboard

---

### **Step 2: Create Resource Group**

1. In the Azure Portal, click **"Resource groups"** (left sidebar or search bar)
2. Click **"+ Create"** button at the top
3. Fill in the details:
   ```
   Subscription: (Your subscription - usually "Azure subscription 1")
   Resource group: TutorLiveMentorRG
   Region: Central India (or closest to you)
   ```
4. Click **"Review + create"**
5. Click **"Create"**

? **DONE!** Resource group created in ~5 seconds.

---

### **Step 3: Create SQL Database**

#### 3.1 Start Creation

1. Click **"+ Create a resource"** (top left)
2. Search for **"SQL Database"**
3. Click **"SQL Database"** ? Click **"Create"**

#### 3.2 Basics Tab

Fill in these details:

```
Subscription: (Your subscription)
Resource group: TutorLiveMentorRG (select the one you just created)
Database name: TutorLiveV1DB
Server: Click "Create new"
```

#### 3.3 Create SQL Server (in the popup)

```
Server name: tutorlivev1-sql-server
   ?? Must be globally unique! If taken, try: tutorlivev1-sql-2024
Location: Central India (same as resource group)
Authentication method: Use SQL authentication
Server admin login: sqladmin
Password: YourStrongP@ssw0rd123!
Confirm password: YourStrongP@ssw0rd123!
```

**?? SAVE THESE CREDENTIALS! You'll need them!**

```
?? SQL Server: tutorlivev1-sql-server
?? Admin: sqladmin
?? Password: YourStrongP@ssw0rd123!
```

Click **"OK"**

#### 3.4 Configure Database Tier

Back on the main page:

```
Want to use SQL elastic pool? No
Compute + storage: Click "Configure database"
   ? Service tier: Basic (2 GB, $4.99/month)
   ? Click "Apply"
```

#### 3.5 Backup Storage

```
Backup storage redundancy: Locally-redundant backup storage
```

#### 3.6 Networking Tab

Click **"Next: Networking"** at the bottom

```
Connectivity method: Public endpoint
Firewall rules:
   ? Allow Azure services and resources to access this server: YES
   ? Add current client IP address: YES
```

#### 3.7 Additional Settings Tab

Click **"Next: Additional settings"**

```
Use existing data: None
Enable Microsoft Defender for SQL: Not now
```

#### 3.8 Create the Database

1. Click **"Review + create"**
2. Review your settings
3. Click **"Create"**
4. Wait 2-3 minutes for deployment

? **DONE!** SQL Database created!

---

### **Step 4: Get SQL Connection String**

This is VERY important! We need this for GitHub secrets.

1. In the Azure Portal, click **"All resources"** (left sidebar)
2. Click on **"TutorLiveV1DB"** (your database)
3. In the left menu, click **"Connection strings"**
4. Under **"ADO.NET (SQL authentication)"**, you'll see a long string
5. **COPY** this entire string
6. **IMPORTANT**: Replace `{your_password}` with your actual password: `YourStrongP@ssw0rd123!`

Your connection string should look like this:

```
Server=tcp:tutorlivev1-sql-server.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=YourStrongP@ssw0rd123!;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
```

**?? SAVE THIS CONNECTION STRING!** Open Notepad and paste it there!

---

### **Step 5: Create App Service Plan**

#### 5.1 Start Creation

1. Click **"+ Create a resource"**
2. Search for **"App Service Plan"**
3. Click **"App Service Plan"** ? Click **"Create"**

#### 5.2 Fill Details

```
Subscription: (Your subscription)
Resource group: TutorLiveMentorRG
Name: TutorLiveMentorPlan
Operating System: Linux
Region: Central India (same as before)
Pricing tier: Click "Explore pricing plans"
   ? Choose "Basic B1" ($13.14/month)
   ? Or "Free F1" for testing (limited features)
   ? Click "Select"
```

#### 5.3 Create

1. Click **"Review + create"**
2. Click **"Create"**
3. Wait ~30 seconds

? **DONE!** App Service Plan created!

---

### **Step 6: Create Web App**

#### 6.1 Start Creation

1. Click **"+ Create a resource"**
2. Search for **"Web App"**
3. Click **"Web App"** ? Click **"Create"**

#### 6.2 Basics Tab

```
Subscription: (Your subscription)
Resource group: TutorLiveMentorRG
Name: tutorlive-app
   ?? Must be globally unique! If taken, try: tutorlive-app-2024
   ?? Your URL will be: https://tutorlive-app.azurewebsites.net
Publish: Code
Runtime stack: .NET 8 (LTS)
Operating System: Linux
Region: Central India
Linux Plan: TutorLiveMentorPlan (should be auto-selected)
Pricing plan: Basic B1 (should be auto-selected)
```

**?? SAVE YOUR WEB APP NAME!**

```
?? Web App Name: tutorlive-app
?? URL: https://tutorlive-app.azurewebsites.net
```

#### 6.3 Deployment Tab

Click **"Next: Deployment"**

```
Continuous deployment: Enable (toggle ON)
GitHub account: Click "Authorize" and sign in to GitHub
Organization: (Your GitHub username)
Repository: tutorlivev1
Branch: main
```

**Skip this for now - we'll configure it manually with secrets instead!**
Just leave it disabled.

#### 6.4 Monitoring Tab

Click **"Next: Monitoring"**

```
Enable Application Insights: Yes
Application Insights: Create new
   ? Name: TutorLiveMentorInsights
   ? Location: Central India
```

#### 6.5 Create

1. Click **"Review + create"**
2. Click **"Create"**
3. Wait 1-2 minutes

? **DONE!** Web App created!

---

### **Step 7: Configure Web App Settings**

#### 7.1 Open Web App

1. Click **"Go to resource"** (or find it in "All resources")
2. You should see your Web App: **tutorlive-app**

#### 7.2 Set Connection String

1. In the left menu, click **"Configuration"** (under Settings)
2. Click the **"Connection strings"** tab
3. Click **"+ New connection string"**
4. Fill in:
   ```
   Name: DefaultConnection
   Value: (Paste your SQL connection string from Step 4)
   Type: SQLServer
   Deployment slot setting: Leave unchecked
   ```
5. Click **"OK"**
6. Click **"Save"** at the top
7. Click **"Continue"** to restart the app

? **Connection string configured!**

#### 7.3 Set Application Settings

1. Still in **"Configuration"**
2. Click the **"Application settings"** tab
3. Click **"+ New application setting"** for each of these:

**Setting 1:**
```
Name: ASPNETCORE_ENVIRONMENT
Value: Production
```
Click **"OK"**

**Setting 2:**
```
Name: ServerSettings__ServerMode
Value: Cloud
```
Click **"OK"**

**Setting 3:**
```
Name: AllowedHosts
Value: *
```
Click **"OK"**

**Setting 4:**
```
Name: WEBSITE_RUN_FROM_PACKAGE
Value: 1
```
Click **"OK"**

4. Click **"Save"** at the top
5. Click **"Continue"** to restart

? **Application settings configured!**

---

### **Step 8: Get Publish Profile**

This is needed for GitHub Actions to deploy your app.

1. Still in your Web App (tutorlive-app)
2. Click **"Overview"** in the left menu
3. At the top, click **"Get publish profile"**
4. A file will download: `tutorlive-app.PublishSettings`
5. Open this file with Notepad
6. **COPY ALL THE CONTENT** (Ctrl+A, Ctrl+C)

**?? SAVE THIS!** Keep it open or paste it in a Notepad - you'll need it for GitHub!

? **PART 1 COMPLETE!** All Azure resources are created! ??

---

## ?? **PART 2: CONFIGURE GITHUB SECRETS** (5 minutes)

Now we need to add secrets to your GitHub repository so the workflow can deploy to Azure.

### **Step 1: Open GitHub Repository**

1. Open browser and go to: https://github.com/shahid-afrid/tutorlivev1
2. Click **"Settings"** (top menu, to the right)
3. In the left sidebar, click **"Secrets and variables"** ? **"Actions"**

---

### **Step 2: Add First Secret - AZURE_WEBAPP_PUBLISH_PROFILE**

1. Click **"New repository secret"** (green button)
2. Fill in:
   ```
   Name: AZURE_WEBAPP_PUBLISH_PROFILE
   Secret: (Paste the entire content from the publish profile file you downloaded in Step 8)
   ```
3. Click **"Add secret"**

? **First secret added!**

---

### **Step 3: Add Second Secret - AZURE_SQL_CONNECTION_STRING**

1. Click **"New repository secret"** again
2. Fill in:
   ```
   Name: AZURE_SQL_CONNECTION_STRING
   Secret: (Paste your SQL connection string from Step 4)
   ```
3. Click **"Add secret"**

? **Second secret added!**

---

### **Step 4: Verify Secrets**

You should now see 2 secrets in the list:
- ? AZURE_WEBAPP_PUBLISH_PROFILE
- ? AZURE_SQL_CONNECTION_STRING

? **PART 2 COMPLETE!** GitHub secrets configured! ??

---

## ?? **PART 3: UPDATE YOUR CODE** (5 minutes)

### **Step 1: Update appsettings.Production.json**

Open your `appsettings.Production.json` file and update it with your actual values:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=tcp:tutorlivev1-sql-server.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=__REPLACE_WITH_ENVIRONMENT_VARIABLE__;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
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

**Replace:**
- `tutorlivev1-sql-server` with YOUR SQL server name
- `TutorLiveV1DB` with YOUR database name
- `sqladmin` with YOUR SQL admin username
- Keep `__REPLACE_WITH_ENVIRONMENT_VARIABLE__` as is (don't put real password here!)

---

### **Step 2: Update azure-deploy.yml**

Open `.github/workflows/azure-deploy.yml` and update the `AZURE_WEBAPP_NAME`:

```yaml
env:
  AZURE_WEBAPP_NAME: tutorlive-app  # ?? CHANGE THIS to YOUR web app name!
  DOTNET_VERSION: '8.0.x'
  PROJECT_PATH: 'TutorLiveMentor10.csproj'
```

Also update the health check URL (scroll to bottom of file):

```yaml
HEALTH_URL="https://tutorlive-app.azurewebsites.net/health"  # ?? CHANGE THIS!
```

Replace `tutorlive-app` with YOUR actual web app name.

---

### **Step 3: Save Changes**

Save both files (Ctrl+S).

? **PART 3 COMPLETE!** Files updated! ??

---

## ?? **PART 4: DEPLOY TO AZURE** (10 minutes)

### **Step 1: Commit and Push Changes**

Open terminal/command prompt in your project folder:

```powershell
# Add all changes
git add .

# Commit
git commit -m "Configure Azure deployment settings"

# Push to GitHub
git push origin main
```

---

### **Step 2: Watch GitHub Actions**

1. Go to your GitHub repo: https://github.com/shahid-afrid/tutorlivev1
2. Click **"Actions"** tab (top menu)
3. You should see your workflow running: **"Build and Deploy to Azure App Service"**
4. Click on it to watch progress

You'll see 4 jobs running:
1. ? **build** - Building your app (~2 min)
2. ? **deploy** - Deploying to Azure (~3 min)
3. ? **migrate** - Creating database tables (~2 min)
4. ? **verify** - Health checks (~2 min)

**Total time: ~10 minutes**

? Grab a coffee and wait!

---

### **Step 3: If Actions are Disabled**

If you see a message saying "Workflows are disabled", click:
- **"I understand my workflows, go ahead and enable them"**

Then the workflow will start automatically.

---

### **Step 4: Monitor the Workflow**

Watch each job turn green ?:
- If a job fails ?, click on it to see the error
- Common issues are in the Troubleshooting section below

? **PART 4 COMPLETE!** App deployed! ??

---

## ? **PART 5: VERIFY YOUR DEPLOYMENT** (5 minutes)

### **Test 1: Home Page**

Open browser and go to:
```
https://tutorlive-app.azurewebsites.net
```
(Replace `tutorlive-app` with YOUR web app name)

? You should see your TutorLiveMentor home page!

---

### **Test 2: Health Check**

Go to:
```
https://tutorlive-app.azurewebsites.net/health
```

? Should return: `Healthy`

---

### **Test 3: Database Health Check**

Go to:
```
https://tutorlive-app.azurewebsites.net/health/ready
```

? Should return JSON showing database status

---

### **Test 4: Admin Login**

Go to:
```
https://tutorlive-app.azurewebsites.net/Admin/Login
```

Login with:
```
Email: cseds@rgmcet.edu.in
Password: 9059530688
```

? Should redirect to Admin Dashboard!

---

## ?? **SUCCESS!**

If all 4 tests passed, your app is successfully deployed! ??

**Your Live URLs:**
```
?? Home: https://tutorlive-app.azurewebsites.net
?? Health: https://tutorlive-app.azurewebsites.net/health
?? Admin: https://tutorlive-app.azurewebsites.net/Admin/Login
```

---

## ?? **TROUBLESHOOTING**

### Issue 1: "GitHub Actions workflow not running"

**Solution:**
1. Go to GitHub ? Actions tab
2. If disabled, click "Enable workflows"
3. Manually trigger: Click "Build and Deploy" ? "Run workflow" ? "Run workflow"

---

### Issue 2: "Deploy job fails - unauthorized"

**Solution:** Publish profile secret is wrong
1. Go to Azure Portal ? Your Web App
2. Click "Get publish profile" again
3. Download the file
4. Go to GitHub ? Settings ? Secrets ? Actions
5. Click "AZURE_WEBAPP_PUBLISH_PROFILE" ? "Update secret"
6. Paste the NEW content
7. Re-run the workflow

---

### Issue 3: "Migration job fails - connection error"

**Solution:** Connection string is wrong
1. Go to Azure Portal ? SQL Database ? Connection strings
2. Copy the connection string again
3. Replace `{your_password}` with actual password
4. Go to GitHub ? Settings ? Secrets ? Actions
5. Click "AZURE_SQL_CONNECTION_STRING" ? "Update secret"
6. Paste the corrected string
7. Re-run the workflow

---

### Issue 4: "Website shows 500 error"

**Solution:** Enable detailed errors to see what's wrong
1. Go to Azure Portal ? Your Web App ? Configuration
2. Application settings ? New application setting:
   ```
   Name: ASPNETCORE_DETAILEDERRORS
   Value: true
   ```
3. Save and restart
4. Reload your website - you'll see detailed error message
5. Check the logs: Web App ? Monitoring ? Log stream

---

### Issue 5: "Admin accounts not created"

**Solution:** Check if admin seeder ran
1. Azure Portal ? Web App ? Monitoring ? Log stream
2. Look for: `[ADMIN SEEDER] Successfully created default admin accounts`
3. If not found, restart the web app:
   - Azure Portal ? Web App ? Overview ? Restart
4. Wait 2 minutes and check logs again

---

## ?? **COST MANAGEMENT**

Your current setup costs approximately **$18/month**:
- App Service (B1): $13.14/month
- SQL Database (Basic): $4.99/month

### To Save Costs:

#### Option 1: Stop when not using
```
Azure Portal ? Web App ? Overview ? Stop
```
(Restart when needed)

#### Option 2: Downgrade to Free Tier (Testing only)
```
Azure Portal ? App Service Plan ? Scale up (App Service plan)
? Choose "Free F1" ? Apply
```
?? Limitations: 60 min/day, no custom domain, no SSL

#### Option 3: Delete everything
```
Azure Portal ? Resource groups ? TutorLiveMentorRG
? Delete resource group
```
?? This deletes EVERYTHING! Use only when completely done.

---

## ?? **QUICK REFERENCE**

### Your Azure Resources:
```
Resource Group: TutorLiveMentorRG
SQL Server: tutorlivev1-sql-server.database.windows.net
SQL Database: TutorLiveV1DB
SQL Admin: sqladmin
SQL Password: YourStrongP@ssw0rd123!
Web App: tutorlive-app
App URL: https://tutorlive-app.azurewebsites.net
```

### Your GitHub Secrets:
```
AZURE_WEBAPP_PUBLISH_PROFILE (from publish profile download)
AZURE_SQL_CONNECTION_STRING (SQL connection string)
```

### Admin Login Credentials:
```
Primary Admin:
  Email: cseds@rgmcet.edu.in
  Password: 9059530688

CSE Admin:
  Email: admin.cse@rgmcet.edu.in
  Password: CSEAdmin@2024

Super Admin:
  Email: superadmin@rgmcet.edu.in
  Password: SuperAdmin@2024
```

---

## ?? **FINAL CHECKLIST**

### Before Deployment:
- [x] Azure account created
- [x] GitHub account ready
- [ ] Resource group created ?
- [ ] SQL Database created ?
- [ ] Web App created ?
- [ ] Connection string copied ?
- [ ] Publish profile downloaded ?
- [ ] GitHub secrets added ?
- [ ] appsettings.Production.json updated ?
- [ ] azure-deploy.yml updated ?

### After Deployment:
- [ ] Code pushed to GitHub
- [ ] GitHub Actions workflow completed
- [ ] Home page loads
- [ ] Health check passes
- [ ] Admin login works
- [ ] Database tables created

---

## ?? **NEED HELP?**

### Check GitHub Actions Logs:
https://github.com/shahid-afrid/tutorlivev1/actions

### Check Azure Logs:
Azure Portal ? Web App ? Monitoring ? Log stream

### View Database Tables:
Azure Portal ? SQL Database ? Query editor ? Login ? Run:
```sql
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
```

---

**?? YOU'RE ALL SET! HAPPY DEPLOYING! ??**

**Total Time:** ~45 minutes
**Difficulty:** ?? (Easy)
**Cost:** ~$18/month

Good luck! ??
