# ? FINAL DEPLOYMENT CHECKLIST - B1 Plan Active!

## ?? **Great News: You've Upgraded to B1!**

Your app is now on the **B1 Basic** tier, which means:
- ? No more quota limits
- ? Unlimited CPU minutes
- ? 1.75 GB RAM
- ? Always on (doesn't sleep)
- ? Production-ready!

---

## ?? **Complete Checklist - Do These in Order:**

### ? **1. Verify GitHub Secrets (CRITICAL)**

Go to: https://github.com/shahid-afrid/tutor-livev1/settings/secrets/actions

**You MUST have these 2 secrets:**

#### Secret 1: AZURE_WEBAPP_PUBLISH_PROFILE
```xml
<publishData><publishProfile profileName="TutorLive - Web Deploy" publishMethod="MSDeploy" publishUrl="tutorlive-gpc5eehydeavgbbb.scm.centralindia-01.azurewebsites.net:443" msdeploySite="TutorLive" userName="$TutorLive" userPWD="64EkBa4gQS5Y3hq5nyrMe01DFSHjmNtKmMKNYzC8JgucwbNyTEtE9oMblSNF" destinationAppUrl="https://tutorlive-gpc5eehydeavgbbb.centralindia-01.azurewebsites.net" SQLServerDBConnectionString="Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" mySQLDBConnectionString="" hostingProviderForumLink="" controlPanelLink="https://portal.azure.com" webSystem="WebSites"><databases><add name="DefaultConnection" connectionString="Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" providerName="System.Data.SqlClient" type="Sql" /></databases></publishProfile><publishProfile profileName="TutorLive - FTP" publishMethod="FTP" publishUrl="ftps://waws-prod-pn1-039.ftp.azurewebsites.windows.net/site/wwwroot" ftpPassiveMode="True" userName="TutorLive\$TutorLive" userPWD="64EkBa4gQS5Y3hq5nyrMe01DFSHjmNtKmMKNYzC8JgucwbNyTEtE9oMblSNF" destinationAppUrl="https://tutorlive-gpc5eehydeavgbbb.centralindia-01.azurewebsites.net" SQLServerDBConnectionString="Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" mySQLDBConnectionString="" hostingProviderForumLink="" controlPanelLink="https://portal.azure.com" webSystem="WebSites"><databases><add name="DefaultConnection" connectionString="Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" providerName="System.Data.SqlClient" type="Sql" /></databases></publishProfile><publishProfile profileName="TutorLive - Zip Deploy" publishMethod="ZipDeploy" publishUrl="tutorlive-gpc5eehydeavgbbb.scm.centralindia-01.azurewebsites.net:443" userName="$TutorLive" userPWD="64EkBa4gQS5Y3hq5nyrMe01DFSHjmNtKmMKNYzC8JgucwbNyTEtE9oMblSNF" destinationAppUrl="https://tutorlive-gpc5eehydeavgbbb.centralindia-01.azurewebsites.net" SQLServerDBConnectionString="Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" mySQLDBConnectionString="" hostingProviderForumLink="" controlPanelLink="https://portal.azure.com" webSystem="WebSites"><databases><add name="DefaultConnection" connectionString="Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" providerName="System.Data.SqlClient" type="Sql" /></databases></publishProfile></publishData>
```

#### Secret 2: AZURE_SQL_CONNECTION_STRING
```
Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
```

**?? IMPORTANT:** After upgrading to B1, you should **re-download the publish profile** because Azure regenerates credentials after plan changes!

1. Go to Azure Portal ? TutorLive app
2. Click **"Get publish profile"** (top menu)
3. Open the downloaded file
4. Copy ALL content
5. Update the `AZURE_WEBAPP_PUBLISH_PROFILE` secret in GitHub

---

### ? **2. Configure Azure App Settings**

Go to Azure Portal ? TutorLive ? Configuration ? Application settings

**Add these 4 settings:**

| Name | Value |
|------|-------|
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `ServerSettings__ServerMode` | `Cloud` |
| `AllowedHosts` | `*` |
| `WEBSITE_RUN_FROM_PACKAGE` | `1` |

**Click "Save" at the top!**

---

### ? **3. Configure Connection String in Azure**

Go to Azure Portal ? TutorLive ? Configuration ? Connection strings

**Add this:**

| Name | Value | Type |
|------|-------|------|
| `DefaultConnection` | `Server=tcp:tutorlivev1-sql-2024.database.windows.net,1433;Initial Catalog=TutorLiveV1DB;Persist Security Info=False;User ID=sqladmin;Password=8919427828Aa;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;` | `SQLServer` |

**Click "Save" at the top!**

---

### ? **4. Enable "Always On" (B1 Feature)**

Since you're on B1 now, enable "Always On":

1. Go to Azure Portal ? TutorLive ? Configuration ? General settings
2. Toggle **"Always On"** to **ON**
3. Click **"Save"**

This prevents your app from sleeping!

---

### ? **5. Configure SQL Server Firewall**

Your Azure SQL needs to allow connections from Azure services:

1. Go to Azure Portal ? Search for **"tutorlivev1-sql-2024"**
2. Click on your SQL Server
3. Click **"Networking"** (left menu under Security)
4. Under **"Firewall rules"**, toggle **"Allow Azure services and resources to access this server"** to **ON**
5. Click **"Save"**

---

### ? **6. Trigger Deployment**

Now push a commit to trigger deployment:

```bash
cd C:\Users\shahi\Source\Repos\tutor-livev1
git commit --allow-empty -m "Deploy to B1 plan with fixed configuration"
git push origin main
```

---

### ? **7. Monitor Deployment**

Watch it here: https://github.com/shahid-afrid/tutor-livev1/actions

Expected timeline:
- ?? **build** job: ~3 minutes
- ?? **deploy** job: ~2 minutes
- ?? **migrate** job: ~1 minute
- ?? **verify** job: ~2 minutes

**Total: ~8-10 minutes**

---

## ?? **Your Live App URLs:**

After deployment succeeds, visit:

| URL | Purpose |
|-----|---------|
| https://tutorlive-gpc5eehydeavgbbb.centralindia-01.azurewebsites.net | Home Page |
| https://tutorlive-gpc5eehydeavgbbb.centralindia-01.azurewebsites.net/health | Health Check |
| https://tutorlive-gpc5eehydeavgbbb.centralindia-01.azurewebsites.net/Admin/Login | Admin Login |

**Admin Credentials:**
- Email: `cseds@rgmcet.edu.in`
- Password: `9059530688`

---

## ?? **If You Still Get Errors:**

### Error: "No credentials found"
- ? Check GitHub secrets are added to `tutor-livev1` repo (with hyphen)
- ? Re-download publish profile from Azure after B1 upgrade

### Error: "Publish profile is invalid"
- ? The publish profile must be from the CURRENT app (after B1 upgrade)
- ? Download fresh publish profile from Azure Portal

### Error: "Database connection failed"
- ? Check SQL Server firewall allows Azure services
- ? Verify connection string in Azure Configuration
- ? Check GitHub secret `AZURE_SQL_CONNECTION_STRING` is correct

### Error: "App shows error page"
- ? Check Application Insights logs in Azure Portal
- ? Verify `ASPNETCORE_ENVIRONMENT=Production` is set
- ? Check if migrations ran successfully in GitHub Actions logs

---

## ?? **B1 Plan Costs:**

- **Monthly:** ~$13.14 USD
- **Daily:** ~$0.44 USD
- **Per Hour:** ~$0.018 USD

**To avoid charges:** Delete the App Service Plan when not needed, or scale back down to Free (F1) tier.

---

## ?? **Success Indicators:**

? GitHub Actions workflow shows all green checkmarks  
? Home page loads at https://tutorlive-gpc5eehydeavgbbb.centralindia-01.azurewebsites.net  
? Health endpoint returns "Healthy"  
? Admin login works  
? Database is populated with initial data  

---

## ?? **Next Steps After Successful Deployment:**

1. **Test all features** - Admin portal, student registration, etc.
2. **Monitor Application Insights** - Check for errors/performance
3. **Set up custom domain** (optional) - For professional URL
4. **Enable SSL** - Azure provides free SSL for default domains
5. **Set up backup** - Azure SQL automatic backups are enabled by default

---

## ?? **Need Help?**

1. Check GitHub Actions logs for detailed error messages
2. Check Azure Portal ? TutorLive ? Log Stream for real-time logs
3. Check Application Insights ? Failures for error details

---

**You're almost there! Follow this checklist step-by-step and your app will be live!** ??
