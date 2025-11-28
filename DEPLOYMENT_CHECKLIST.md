# ? DEPLOYMENT PROGRESS TRACKER

Print this page or keep it open to track your progress!

---

## ?? PHASE 1: AZURE PORTAL SETUP

### Resource Group
- [ ] Logged into Azure Portal (https://portal.azure.com)
- [ ] Clicked "Resource groups"
- [ ] Clicked "+ Create"
- [ ] Name: `TutorLiveMentorRG`
- [ ] Region: `Central India`
- [ ] Clicked "Create"
- [ ] ? Resource Group Created!

---

### SQL Database & Server
- [ ] Clicked "+ Create a resource"
- [ ] Searched for "SQL Database"
- [ ] Clicked "Create"
- [ ] Database name: `TutorLiveV1DB`
- [ ] Clicked "Create new" for Server
- [ ] Server name: `________________` (write yours here!)
- [ ] Admin login: `sqladmin`
- [ ] Password: `________________` (write it here!)
- [ ] Location: Same as resource group
- [ ] Clicked "OK"
- [ ] Selected "Basic" tier
- [ ] Networking: Public endpoint, Allow Azure services: YES
- [ ] Clicked "Create"
- [ ] Waited 2-3 minutes
- [ ] ? SQL Database Created!

---

### Connection String
- [ ] Opened SQL Database in portal
- [ ] Clicked "Connection strings"
- [ ] Copied ADO.NET string
- [ ] Replaced `{your_password}` with real password
- [ ] ? Saved connection string in Notepad!

```
?? MY CONNECTION STRING:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### App Service Plan
- [ ] Clicked "+ Create a resource"
- [ ] Searched for "App Service Plan"
- [ ] Name: `TutorLiveMentorPlan`
- [ ] Operating System: Linux
- [ ] Region: Same as before
- [ ] Pricing: Basic B1
- [ ] Clicked "Create"
- [ ] ? App Service Plan Created!

---

### Web App
- [ ] Clicked "+ Create a resource"
- [ ] Searched for "Web App"
- [ ] Name: `________________` (write yours here!)
- [ ] Runtime: .NET 8 (LTS)
- [ ] Operating System: Linux
- [ ] Region: Same as before
- [ ] Plan: TutorLiveMentorPlan
- [ ] Monitoring: Enable Application Insights
- [ ] Clicked "Create"
- [ ] Waited 1-2 minutes
- [ ] ? Web App Created!

```
?? MY WEB APP NAME: _____________________
?? MY URL: https://______________________.azurewebsites.net
```

---

### Configure Web App
- [ ] Opened Web App
- [ ] Clicked "Configuration"
- [ ] Connection strings tab
- [ ] Added "DefaultConnection" (SQLServer type)
- [ ] Pasted connection string
- [ ] Clicked "Save"
- [ ] Application settings tab
- [ ] Added `ASPNETCORE_ENVIRONMENT` = `Production`
- [ ] Added `ServerSettings__ServerMode` = `Cloud`
- [ ] Added `AllowedHosts` = `*`
- [ ] Added `WEBSITE_RUN_FROM_PACKAGE` = `1`
- [ ] Clicked "Save"
- [ ] ? Web App Configured!

---

### Publish Profile
- [ ] In Web App, clicked "Overview"
- [ ] Clicked "Get publish profile"
- [ ] File downloaded
- [ ] Opened file in Notepad
- [ ] Selected all (Ctrl+A)
- [ ] Copied all (Ctrl+C)
- [ ] ? Publish Profile Ready!

---

## ?? PHASE 2: GITHUB SECRETS

- [ ] Opened https://github.com/shahid-afrid/tutorlivev1
- [ ] Clicked "Settings"
- [ ] Clicked "Secrets and variables" ? "Actions"
- [ ] Clicked "New repository secret"
- [ ] Name: `AZURE_WEBAPP_PUBLISH_PROFILE`
- [ ] Pasted publish profile content
- [ ] Clicked "Add secret"
- [ ] ? First Secret Added!

---

- [ ] Clicked "New repository secret" again
- [ ] Name: `AZURE_SQL_CONNECTION_STRING`
- [ ] Pasted connection string
- [ ] Clicked "Add secret"
- [ ] ? Second Secret Added!

---

- [ ] Verified both secrets are listed
- [ ] ? GitHub Secrets Complete!

---

## ?? PHASE 3: UPDATE CODE

### Update appsettings.Production.json
- [ ] Opened file in VS Code
- [ ] Updated SQL server name on line 3
- [ ] Updated database name on line 3
- [ ] Updated admin username on line 3
- [ ] Kept password as `__REPLACE_WITH_ENVIRONMENT_VARIABLE__`
- [ ] Saved file (Ctrl+S)
- [ ] ? Production Settings Updated!

---

### Update azure-deploy.yml
- [ ] Opened `.github/workflows/azure-deploy.yml`
- [ ] Line 11: Updated `AZURE_WEBAPP_NAME` to my web app name
- [ ] Line 78: Updated health check URL with my web app name
- [ ] Saved file (Ctrl+S)
- [ ] ? Workflow File Updated!

---

## ?? PHASE 4: DEPLOY

- [ ] Opened terminal in project folder
- [ ] Ran: `git add .`
- [ ] Ran: `git commit -m "Configure Azure deployment"`
- [ ] Ran: `git push origin main`
- [ ] ? Code Pushed to GitHub!

---

- [ ] Opened https://github.com/shahid-afrid/tutorlivev1/actions
- [ ] Clicked on running workflow
- [ ] Watching progress...
- [ ] Build job completed ?
- [ ] Deploy job completed ?
- [ ] Migrate job completed ?
- [ ] Verify job completed ?
- [ ] ? Deployment Complete!

---

## ? PHASE 5: VERIFY

### Test 1: Home Page
- [ ] Opened `https://______________________.azurewebsites.net`
- [ ] Home page loaded successfully
- [ ] ? Home Page Works!

---

### Test 2: Health Check
- [ ] Opened `https://______________________.azurewebsites.net/health`
- [ ] Shows "Healthy"
- [ ] ? Health Check Works!

---

### Test 3: Database Health
- [ ] Opened `https://______________________.azurewebsites.net/health/ready`
- [ ] Shows JSON with database info
- [ ] ? Database Connected!

---

### Test 4: Admin Login
- [ ] Opened `https://______________________.azurewebsites.net/Admin/Login`
- [ ] Entered email: `cseds@rgmcet.edu.in`
- [ ] Entered password: `9059530688`
- [ ] Clicked Login
- [ ] Redirected to Admin Dashboard
- [ ] ? Admin Login Works!

---

## ?? FINAL STATUS

- [ ] All Azure resources created
- [ ] All GitHub secrets added
- [ ] All code files updated
- [ ] Code deployed successfully
- [ ] All tests passed

---

### ?? DEPLOYMENT SUCCESSFUL! ??

**My Live App URL:**
```
https://______________________.azurewebsites.net
```

**Deployment Date:** _______________

**Time Taken:** _______ minutes

**Total Cost:** ~$18/month

---

## ?? POST-DEPLOYMENT TASKS

- [ ] Change default admin passwords (security!)
- [ ] Test all features on live site
- [ ] Set up monitoring alerts
- [ ] Configure custom domain (optional)
- [ ] Enable SSL certificate
- [ ] Set up automated backups
- [ ] Document any custom settings
- [ ] Share app URL with team

---

## ?? TROUBLESHOOTING (if needed)

If something failed, check:

- [ ] GitHub Actions logs
- [ ] Azure Web App logs (Log stream)
- [ ] Connection string is correct
- [ ] Publish profile is correct
- [ ] All secrets are added
- [ ] File changes are saved and pushed

---

**Remember:** You can always re-run GitHub Actions workflow manually!
Go to: Actions ? Click workflow ? "Re-run all jobs"

---

Good luck! ??
