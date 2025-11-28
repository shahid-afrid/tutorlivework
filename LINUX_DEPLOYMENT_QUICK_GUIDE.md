# ?? YOUR LINUX DEPLOYMENT - QUICK ACTION GUIDE

## ? **YOUR ACTUAL CONFIGURATION:**

```
Web App Name:    TutorLive
URL:             https://tutorlive.azurewebsites.net
OS:              Linux (Perfect for .NET 8!)
Region:          Central India
Plan:            Free F1
SQL Server:      tutorlivev1-sql-2024.database.windows.net
SQL Database:    TutorLiveV1DB
SQL Admin:       sqladmin
SQL Password:    8919427828Aa
```

---

## ?? **IMMEDIATE NEXT STEPS:**

### **Step 1: Click "Create" in Azure Portal** ? DO THIS NOW!

Wait 2 minutes for deployment...

---

### **Step 2: After Web App is Created**

Click "Go to resource"

#### 2.1 Configure Connection String

```
1. Click "Configuration" (left menu under Settings)
2. Click "Connection strings" tab
3. Click "+ New connection string"
4. Fill in:

   Name: DefaultConnection
   
   Value: (paste this EXACT string)
   Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
   
   Type: SQLServer

5. Click "OK"
6. Click "Save" at top
7. Click "Continue" to restart
```

#### 2.2 Add Application Settings

```
Still in Configuration ? Application settings tab:

Add these 4 settings (click "+ New application setting" for each):

1. ASPNETCORE_ENVIRONMENT = Production
2. ServerSettings__ServerMode = Cloud
3. AllowedHosts = *
4. WEBSITE_RUN_FROM_PACKAGE = 1

Then click "Save" at top
```

---

### **Step 3: Download Publish Profile**

```
1. Click "Overview" (left menu)
2. Click "Get publish profile" at top
3. File downloads: TutorLive.PublishSettings
4. Open with Notepad
5. Copy ALL content (Ctrl+A, Ctrl+C)
6. Save it somewhere!
```

---

### **Step 4: Add GitHub Secrets**

Go to: https://github.com/shahid-afrid/tutorlivev1/settings/secrets/actions

#### Secret 1:
```
Name: AZURE_WEBAPP_PUBLISH_PROFILE
Value: (Paste entire publish profile content)
Click "Add secret"
```

#### Secret 2:
```
Name: AZURE_SQL_CONNECTION_STRING
Value: Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
Click "Add secret"
```

---

### **Step 5: Deploy!**

```sh
cd C:\Users\shahi\Source\Repos\tutor-livev1
git add .
git commit -m "Deploy to Azure Linux App Service"
git push origin main
```

---

### **Step 6: Watch Deployment**

Go to: https://github.com/shahid-afrid/tutorlivev1/actions

You'll see 4 jobs:
- ? build
- ? deploy
- ? migrate (creates database tables!)
- ? verify

Total time: ~10 minutes

---

### **Step 7: Verify Live App**

Visit: https://tutorlive.azurewebsites.net

Test:
1. Home page loads ?
2. /health returns "Healthy" ?
3. Admin login works ?
   - Email: cseds@rgmcet.edu.in
   - Password: 9059530688

---

## ?? **CHECKLIST:**

- [ ] Clicked "Create" in Azure Portal
- [ ] Waited for deployment (~2 min)
- [ ] Added Connection String in Configuration
- [ ] Added 4 Application Settings
- [ ] Downloaded Publish Profile
- [ ] Added both GitHub Secrets
- [ ] Pushed code to GitHub
- [ ] Watched GitHub Actions complete
- [ ] Verified app is live!

---

## ?? **YOUR URLS:**

```
?? Live App:    https://tutorlive.azurewebsites.net
?? Health:      https://tutorlive.azurewebsites.net/health
?? Admin:       https://tutorlive.azurewebsites.net/Admin/Login
?? Monitoring:  https://portal.azure.com ? TutorLive ? Application Insights
```

---

## ?? **LINUX vs WINDOWS - YOU MADE THE RIGHT CHOICE!**

| Feature | Linux (Your Choice ?) | Windows (Old) |
|---------|----------------------|---------------|
| .NET 8 Performance | ? Faster | ?? Slower |
| Resource Usage | ? Lower | ?? Higher |
| Startup Time | ? Faster | ?? Slower |
| Industry Standard | ? Yes | ?? Legacy |
| Your Workflow | ? Already configured | ?? Works but not optimal |

**You chose wisely!** ??

---

## ?? **IMPORTANT NOTES:**

1. **Password in Connection String**: Your SQL password `8919427828Aa` is in the connection string. Azure will store this securely in Configuration, and GitHub will store it securely in Secrets. The appsettings.Production.json file has `__REPLACE_WITH_ENVIRONMENT_VARIABLE__` so the password never goes into your code.

2. **Free Tier Limits**: 
   - 60 minutes per day runtime
   - App stops after 20 minutes of inactivity
   - Perfect for testing!
   - Upgrade to Basic B1 ($13/month) for production

3. **Application Insights**: Already enabled - you can see:
   - Performance metrics
   - Error tracking
   - User analytics
   - All free for first 5GB/month!

---

## ? **FILES ALREADY UPDATED:**

- ? `.github/workflows/azure-deploy.yml` ? Web app name: "Tutorlive"
- ? `appsettings.Production.json` ? SQL server: "tutorlivev1-sql-2024"

**You're ready to deploy!** ??

---

## ?? **START NOW:**

1. Click "Create" in Azure Portal (on your screen right now!)
2. Follow the 7 steps above
3. Your app will be live in 30 minutes!

Good luck! ??
