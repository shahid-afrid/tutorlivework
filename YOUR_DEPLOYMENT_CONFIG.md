# ?? YOUR DEPLOYMENT CONFIGURATION

## ? **WHAT YOU'VE CHOSEN:**

Based on your Azure Portal screenshot, here's your setup:

```
??????????????????????????????????????????????????????
? YOUR AZURE WEB APP CONFIGURATION                   ?
??????????????????????????????????????????????????????
? Web App Name:      Tutorlive                       ?
? URL:               https://tutorlive.azurewebsites.net ?
? Publish:           Code ?                         ?
? Runtime:           .NET 8 (LTS) ?                 ?
? Operating System:  Windows ?                      ?
? Region:            Central India ?                ?
? Plan:              ASP_TutorLiveRG_ad86 (F1) ?   ?
? Pricing:           Free F1 (Shared) ?            ?
??????????????????????????????????????????????????????
```

---

## ?? **YOUR CREDENTIALS TO SAVE:**

### SQL Database (from earlier steps):
```
?? SQL Server: ___________________
?? Database: ___________________
?? SQL Admin: sqladmin
?? SQL Password: ___________________
?? Connection String: ___________________
```

### Web App:
```
?? Web App Name: Tutorlive
?? URL: https://tutorlive.azurewebsites.net
```

---

## ? **FILES ALREADY UPDATED:**

I've updated these files for you:

### 1. `appsettings.Production.json`
- Connection string template ready
- Replace placeholders with YOUR actual values:
  - `YOUR_SQL_SERVER_NAME` ? your SQL server name
  - `YOUR_DATABASE_NAME` ? your database name  
  - `YOUR_SQL_ADMIN` ? your SQL admin username

### 2. `.github/workflows/azure-deploy.yml`
- Web app name: `Tutorlive` ?
- Health check URL: `https://tutorlive.azurewebsites.net/health` ?

---

## ?? **NEXT STEPS:**

### Step 1: Finish Web App Creation (In Azure Portal)
Continue with the wizard:
1. Click **"Next: Deployment"** ? Leave disabled
2. Click **"Next: Networking"** ? Use defaults
3. Click **"Next: Monitoring"** ? Enable Application Insights: Yes
4. Click **"Review + create"**
5. Click **"Create"**
6. Wait 1-2 minutes ?

### Step 2: Configure Web App Settings
After creation:
1. Go to your Web App ? Configuration
2. Add Connection String:
   - Name: `DefaultConnection`
   - Value: (Your SQL connection string)
   - Type: `SQLServer`
3. Add Application Settings:
   - `ASPNETCORE_ENVIRONMENT` = `Production`
   - `ServerSettings__ServerMode` = `Cloud`
   - `AllowedHosts` = `*`
   - `WEBSITE_RUN_FROM_PACKAGE` = `1`
4. Click **Save**

### Step 3: Download Publish Profile
1. Web App ? Overview ? "Get publish profile"
2. Save the downloaded file
3. Open with Notepad and copy ALL content

### Step 4: Add GitHub Secrets
Go to: https://github.com/shahid-afrid/tutorlivev1/settings/secrets/actions

Add 2 secrets:
1. **AZURE_WEBAPP_PUBLISH_PROFILE**
   - Paste entire publish profile content
2. **AZURE_SQL_CONNECTION_STRING**
   - Paste your SQL connection string

### Step 5: Update appsettings.Production.json
Replace these in the file:
- `YOUR_SQL_SERVER_NAME` ? e.g., `tutorlivev1-sql-server`
- `YOUR_DATABASE_NAME` ? e.g., `TutorLiveV1DB`
- `YOUR_SQL_ADMIN` ? e.g., `sqladmin`
- Keep password as `__REPLACE_WITH_ENVIRONMENT_VARIABLE__`

### Step 6: Deploy!
```bash
git add .
git commit -m "Configure Azure deployment for Windows"
git push origin main
```

### Step 7: Verify
Visit: https://tutorlive.azurewebsites.net

---

## ?? **YOUR URLS:**

```
?? Home: https://tutorlive.azurewebsites.net
?? Health: https://tutorlive.azurewebsites.net/health
?? Admin: https://tutorlive.azurewebsites.net/Admin/Login
```

---

## ?? **IMPORTANT NOTES:**

### Free F1 Tier Limitations:
- ? **60 minutes per day** runtime limit
- ?? Slower performance
- ? No custom domain
- ? No SSL certificate
- ? Perfect for testing!

### To Upgrade Later:
```
Azure Portal ? App Service Plan ? Scale up
? Choose "Basic B1" ($13/month)
```

---

## ?? **TROUBLESHOOTING:**

### If deployment fails:
1. Check GitHub Actions logs
2. Verify both secrets are added
3. Check Azure logs: Web App ? Log stream
4. Verify connection string is correct

### If 500 error:
1. Enable detailed errors:
   - Configuration ? New setting
   - `ASPNETCORE_DETAILEDERRORS` = `true`
2. Check logs for error details

---

## ?? **WINDOWS vs LINUX:**

### What You Chose: Windows ?
- Pros: Familiar, works great
- Cons: None for your use case!
- Your workflow: Works perfectly! ?

### Your workflow builds on Ubuntu (GitHub cloud)
### But deploys to Windows (Azure) ?
### This is NORMAL and WORKS PERFECTLY! ??

---

## ? **READY TO CONTINUE?**

You're at: **Step 6 - Creating Web App**

Next: Continue with Azure Portal wizard and follow Steps 1-7 above!

Good luck! ??
