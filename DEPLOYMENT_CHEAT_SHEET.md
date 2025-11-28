# ?? QUICK DEPLOYMENT CHEAT SHEET

## ?? **WHAT TO COPY AND SAVE**

### 1?? SQL Server Details (from Azure Portal - Step 3)
```
?? SQL Server Name: tutorlivev1-sql-server
?? SQL Admin: sqladmin
?? SQL Password: YourStrongP@ssw0rd123!
```

### 2?? SQL Connection String (from Azure Portal - Step 4)
```
Server=tcp:tutorlivev1-sql-server.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=YourStrongP@ssw0rd123!;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
```
?? Replace server name, database name, username, and password with YOUR values!

### 3?? Web App Details (from Azure Portal - Step 6)
```
?? Web App Name: tutorlive-app
?? URL: https://tutorlive-app.azurewebsites.net
```

---

## ?? **GITHUB SECRETS TO ADD**

Go to: https://github.com/shahid-afrid/tutorlivev1/settings/secrets/actions

### Secret 1: AZURE_WEBAPP_PUBLISH_PROFILE
```
Name: AZURE_WEBAPP_PUBLISH_PROFILE
Value: [Paste entire content from downloaded .PublishSettings file]
```

### Secret 2: AZURE_SQL_CONNECTION_STRING
```
Name: AZURE_SQL_CONNECTION_STRING
Value: [Paste your SQL connection string from above]
```

---

## ?? **FILES TO UPDATE**

### File 1: appsettings.Production.json

Update line 3 with YOUR values:
```json
"DefaultConnection": "Server=tcp:YOUR_SQL_SERVER.database.windows.net,1433;Initial Catalog=YOUR_DB_NAME;Persist Security Info=False;User ID=YOUR_ADMIN;Password=__REPLACE_WITH_ENVIRONMENT_VARIABLE__;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
```

Replace:
- `YOUR_SQL_SERVER` ? e.g., `tutorlivev1-sql-server`
- `YOUR_DB_NAME` ? e.g., `TutorLiveV1DB`
- `YOUR_ADMIN` ? e.g., `sqladmin`

### File 2: .github/workflows/azure-deploy.yml

Update line 11 with YOUR web app name:
```yaml
AZURE_WEBAPP_NAME: tutorlive-app  # ?? Change this!
```

Update line 78 with YOUR web app URL:
```yaml
HEALTH_URL="https://tutorlive-app.azurewebsites.net/health"  # ?? Change this!
```

---

## ?? **DEPLOYMENT STEPS (QUICK)**

### Step 1: Azure Portal (20 min)
1. Create Resource Group: `TutorLiveMentorRG`
2. Create SQL Database: `TutorLiveV1DB` + Server
3. Get Connection String ? Save it!
4. Create App Service Plan: `TutorLiveMentorPlan`
5. Create Web App: `tutorlive-app`
6. Configure Web App ? Connection strings + Settings
7. Download Publish Profile ? Save it!

### Step 2: GitHub Secrets (2 min)
1. Add `AZURE_WEBAPP_PUBLISH_PROFILE`
2. Add `AZURE_SQL_CONNECTION_STRING`

### Step 3: Update Files (2 min)
1. Update `appsettings.Production.json`
2. Update `azure-deploy.yml`

### Step 4: Deploy (1 min)
```bash
git add .
git commit -m "Configure Azure deployment"
git push origin main
```

### Step 5: Wait (10 min)
Watch GitHub Actions: https://github.com/shahid-afrid/tutorlivev1/actions

### Step 6: Test
Visit: https://YOUR-WEB-APP-NAME.azurewebsites.net

---

## ? **SUCCESS CHECKS**

- [ ] Azure resources created
- [ ] Connection string saved
- [ ] Publish profile downloaded
- [ ] GitHub secrets added (2 secrets)
- [ ] appsettings.Production.json updated
- [ ] azure-deploy.yml updated
- [ ] Code pushed to GitHub
- [ ] GitHub Actions completed (all green ?)
- [ ] Website loads
- [ ] Admin login works

---

## ?? **COMMON MISTAKES TO AVOID**

? Forgetting to replace `{your_password}` in connection string
? Not updating web app name in yaml file
? Copying only part of the publish profile
? Using wrong secret names (must match exactly!)
? Not saving after adding Connection String in Azure

---

## ?? **TROUBLESHOOTING QUICK FIXES**

### Workflow fails at deploy:
? Re-download publish profile and update GitHub secret

### Migration fails:
? Check connection string has correct password

### 500 error on website:
? Check Azure logs: Web App ? Log stream

### Admin not created:
? Restart web app and check logs

---

## ?? **PRO TIPS**

? Keep all credentials in a password manager
? Download publish profile after any web app changes
? Check Azure costs daily: Azure Portal ? Cost Management
? Stop web app when not using to save money
? Use Application Insights to monitor performance

---

## ?? **YOU'RE READY!**

Follow the detailed guide: `AZURE_PORTAL_DEPLOYMENT_GUIDE.md`

Good luck! ??
