# ?? HOW TO ACCESS SUPER ADMIN DASHBOARD

## ? **QUICK START (3 Steps)**

### **Step 1: Start the Application**
```powershell
dotnet run
```

### **Step 2: Open Browser**
Navigate to one of these URLs:
- **HTTPS**: `https://localhost:5001/SuperAdmin/Login`
- **HTTP**: `http://localhost:5000/SuperAdmin/Login`

### **Step 3: Login**
```
Email:    superadmin@rgmcet.edu.in
Password: Super@123
```

---

## ?? **Detailed Steps**

### **Method 1: Using PowerShell Script (Easiest)**

1. **Run the access script:**
   ```powershell
   .\ACCESS_SUPER_ADMIN_DASHBOARD.ps1
   ```

2. **Press Y** when asked to start the application

3. **Login** with the credentials shown

4. **Done!** You'll see the dashboard with:
   - 6 system statistics cards
   - All departments (CSEDS, CSE, ECE, MECH, CIVIL, EEE)
   - Recent activity feed

---

### **Method 2: Manual Access**

1. **Open Terminal/PowerShell** in project directory

2. **Start Application:**
   ```powershell
   dotnet run
   ```

3. **Wait for startup** (look for messages like):
   ```
   info: TutorLiveMentor Server Starting...
   info: Now listening on: https://localhost:5001
   info: Now listening on: http://localhost:5000
   ```

4. **Open Browser** and go to:
   ```
   https://localhost:5001/SuperAdmin/Login
   ```

5. **Enter Credentials:**
   - Email: `superadmin@rgmcet.edu.in`
   - Password: `Super@123`

6. **Click "Sign In to Super Admin"**

7. **You should see the Dashboard** with:
   - Welcome message with your name
   - 6 colorful statistics cards
   - Grid of 6 departments
   - Recent activity timeline

---

## ?? **What You'll See After Login**

### **Dashboard Features:**
```
????????????????????????????????????????????????????????????
? ?? Super Admin Dashboard                                 ?
? Welcome back, System Administrator                       ?
? [Departments] [Admins] [Audit Logs] [Logout]            ?
????????????????????????????????????????????????????????????

Statistics Cards:
???????????????????????????????????????????????????????????????????
?Departments? Students ? Faculty  ? Subjects ?  Admins  ?Enrollments?
?    6     ?   XXX    ?   YY     ?   ZZ     ?    N     ?    M      ?
???????????????????????????????????????????????????????????????????

Departments Grid (6 cards):
??????????????????????????????????????????????????????????????
? CSEDS - Computer Science & Engineering (Data Science)     ?
? [CSEDS] [Active]                                          ?
? Students: XXX | Faculty: YY | Subjects: ZZ                ?
? [View Details] [Edit]                                     ?
??????????????????????????????????????????????????????????????
... (5 more department cards)

Recent Activity:
?? Login - superadmin@rgmcet.edu.in
   Super admin superadmin@rgmcet.edu.in logged in successfully
   ?? Just now
```

---

## ? **Troubleshooting**

### **Problem 1: Can't Access Login Page**

**Symptom:** Browser shows "This site can't be reached"

**Solutions:**
1. Check if application is running:
   ```powershell
   # You should see output like "Now listening on: https://localhost:5001"
   ```

2. Try HTTP instead of HTTPS:
   ```
   http://localhost:5000/SuperAdmin/Login
   ```

3. Check for port conflicts:
   ```powershell
   netstat -ano | findstr :5001
   ```

4. Restart the application:
   ```powershell
   # Press Ctrl+C to stop, then
   dotnet run
   ```

---

### **Problem 2: Login Fails**

**Symptom:** "Invalid email or password" message

**Solutions:**
1. **Verify exact credentials** (case-sensitive):
   ```
   Email:    superadmin@rgmcet.edu.in
   Password: Super@123
   ```

2. **Check database is updated:**
   ```powershell
   dotnet ef database update
   ```

3. **Verify super admin exists in database:**
   ```sql
   SELECT * FROM SuperAdmins WHERE Email = 'superadmin@rgmcet.edu.in'
   ```

4. **Check application logs** in terminal for errors

---

### **Problem 3: Dashboard Shows Errors**

**Symptom:** After login, dashboard shows errors or blank data

**Solutions:**
1. **Check departments are seeded:**
   ```sql
   SELECT * FROM Departments
   ```
   Should show 6 departments (CSEDS, CSE, ECE, MECH, CIVIL, EEE)

2. **Verify session is working:**
   - Press F12 in browser
   - Go to Application/Storage ? Cookies
   - Look for `TutorLiveMentor.Session`

3. **Clear browser cache:**
   - Press Ctrl+Shift+Delete
   - Clear cached images and files

4. **Check browser console for JavaScript errors:**
   - Press F12
   - Go to Console tab
   - Look for any red error messages

---

### **Problem 4: "Access Denied" or 401 Error**

**Symptom:** Redirected back to login or see access denied

**Solutions:**
1. **Clear session:**
   ```csharp
   // In browser, clear cookies for localhost
   ```

2. **Restart application:**
   ```powershell
   # Stop with Ctrl+C, then
   dotnet run
   ```

3. **Check session configuration in Program.cs** is correct

---

## ?? **Verification Checklist**

Before accessing, verify:

- [ ] Application is running (`dotnet run`)
- [ ] Migration is applied (`dotnet ef database update`)
- [ ] SuperAdmin table exists in database
- [ ] 6 Departments are seeded
- [ ] Browser is on correct URL
- [ ] Credentials are correct (copy-paste to avoid typos)

---

## ?? **What Makes it "Not Accessible"?**

Common issues:

1. **URL is wrong**
   - ? `localhost:5001/SuperAdmin` (missing /Login)
   - ? `localhost:5001/Admin/Login` (wrong controller)
   - ? `localhost:5001/SuperAdmin/Login` (correct)

2. **Application not running**
   - Check terminal shows "Now listening on..."

3. **Migration not applied**
   - Database doesn't have SuperAdmins table
   - Run: `dotnet ef database update`

4. **Wrong credentials**
   - Email typo (e.g., `superadmin@rgmcet.com` instead of `.edu.in`)
   - Password typo (remember capital S and @)

5. **Browser cache issues**
   - Try incognito/private mode
   - Or clear cache (Ctrl+Shift+Delete)

---

## ?? **Quick Commands**

```powershell
# Check migrations
dotnet ef migrations list

# Apply migration
dotnet ef database update

# Run application
dotnet run

# Open browser (Windows)
start https://localhost:5001/SuperAdmin/Login

# Stop application
# Press Ctrl+C in terminal
```

---

## ?? **Still Can't Access?**

### **Run This Diagnostic:**

```powershell
# 1. Check if tables exist
dotnet ef database update

# 2. Run application with verbose logging
$env:ASPNETCORE_ENVIRONMENT="Development"
dotnet run --verbosity detailed

# 3. Check specific URL in browser
start https://localhost:5001/SuperAdmin/Login

# 4. Check console output for errors
```

### **Check These Files:**
- `SUPER_ADMIN_PHASE_1_ERRORS_FIXED.md` - Initial setup
- `SUPER_ADMIN_PHASE_2_STEP_1_COMPLETE.md` - Dashboard details
- `Controllers/SuperAdminController.cs` - Login logic
- `Views/SuperAdmin/Login.cshtml` - Login page
- `Views/SuperAdmin/Dashboard.cshtml` - Dashboard page

---

## ? **Success Indicators**

You've successfully accessed when you see:

1. ? **Login Page**:
   - Red-gold gradient header
   - Crown icon with "SUPER ADMIN ACCESS" badge
   - Email and password fields
   - "Sign In to Super Admin" button

2. ? **After Login - Dashboard**:
   - Red-gold header with crown icon
   - Welcome message with "System Administrator"
   - 6 colorful stat cards
   - Grid of 6 department cards
   - Recent activity list
   - [Departments] [Admins] [Audit Logs] [Logout] buttons

---

## ?? **Test After Access**

Once you can see the dashboard:

1. ? Check all 6 stat cards show numbers
2. ? Verify all 6 departments appear
3. ? Click "View Details" on a department
4. ? Click "Edit" on a department (should show edit page)
5. ? Click "Manage All Departments"
6. ? Click "Logout" (should return to login)
7. ? Login again (should work smoothly)

---

## ?? **You're Ready!**

Once you see the dashboard, you can:
- ? View system-wide statistics
- ? Manage all 6 departments
- ? View and manage department admins
- ? Monitor system activity
- ? Configure department settings

**The Super Admin system is fully functional!** ??

---

**Need More Help?**
- Run: `.\ACCESS_SUPER_ADMIN_DASHBOARD.ps1`
- Or post the specific error you're seeing

---

**Developed for RGMCET**
Team: Shahid Afrid (23091A32D4) & Veena (23091A32H9)
Guide: Dr. P. Penchala Prasad, CSE(DS)

© All Rights Reserved @2025
