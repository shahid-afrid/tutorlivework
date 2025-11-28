# ?? QUICK REFERENCE GUIDE

> **Fast access to common commands and solutions**

---

## ?? Common Commands

### Development
```bash
dotnet run                    # Start app
dotnet watch run              # Start with hot reload
dotnet build                  # Build project
dotnet clean                  # Clean build files
```

### Database
```bash
dotnet ef database update     # Apply migrations
dotnet ef migrations add Name # Create new migration
dotnet ef migrations remove   # Remove last migration
```

### Testing
```bash
# Open browser console: F12
# Check Network tab: F12 ? Network
# Check Application logs: VS Code Terminal
```

---

## ?? Quick Fixes

### Faculty Update Not Saving?
```csharp
// Use this pattern:
_context.Entry(faculty).State = EntityState.Modified;
await _context.SaveChangesAsync();

// OR use Update():
_context.Faculties.Update(updatedFaculty);
await _context.SaveChangesAsync();
```

### Modal Not Closing?
```javascript
// Force close:
const modal = bootstrap.Modal.getInstance(document.getElementById('editModal'));
modal.hide();
document.querySelectorAll('.modal-backdrop').forEach(el => el.remove());
document.body.classList.remove('modal-open');
```

### 400 Bad Request?
```javascript
// Check you're sending all required properties:
const data = {
    FacultyId: facultyId,
    Name: name,
    Email: email,
    Password: password || '',  // Empty string, NOT null
    Department: 'CSE(DS)',
    SelectedSubjectIds: [],
    AvailableSubjects: [],
    IsEdit: true
};
```

---

## ?? Debugging Checklist

When something doesn't work:
1. ? Check browser console (F12)
2. ? Check VS Code terminal (backend logs)
3. ? Check Network tab (request/response)
4. ? Restart application (`Ctrl+C`, `dotnet run`)
5. ? Clear browser cache (`Ctrl+Shift+R`)
6. ? Check database values directly (SQL query)

---

## ?? Login Credentials

**Admin:**
- Email: `cseds@rgmcet.edu.in`
- Password: `admin123`

---

## ?? Important Files

### Controllers
- `Controllers/AdminController.cs` - Admin operations
- `Controllers/StudentController.cs` - Student operations
- `Controllers/FacultyController.cs` - Faculty operations

### Views
- `Views/Admin/ManageCSEDSFaculty.cshtml` - Faculty management
- `Views/Admin/ManageCSEDSSubjects.cshtml` - Subject management
- `Views/Admin/CSEDSReports.cshtml` - Reports dashboard

### Models
- `Models/Faculty.cs` - Faculty entity
- `Models/Subject.cs` - Subject entity
- `Models/StudentEnrollment.cs` - Enrollment entity
- `Models/CSEDSViewModels.cs` - View models

---

## ??? Database Queries

### Check Faculty
```sql
SELECT * FROM Faculties WHERE Email = 'email@example.com';
```

### Check Enrollments
```sql
SELECT COUNT(*) FROM StudentEnrollments WHERE SubjectId = 1;
```

### Check Subjects
```sql
SELECT SubjectId, SubjectName, SubjectType, MaxEnrollments 
FROM Subjects 
WHERE Department = 'CSE(DS)';
```

---

## ?? Testing Flow

### Test Faculty Update:
1. Open browser console (F12)
2. Go to Manage CSEDS Faculty
3. Click Edit
4. Change name to "TEST NAME"
5. Click Update
6. Look for: `[UPDATE] SaveChangesAsync returned: 1 changes`
7. ? If you see it = Working!

### Test Subject Creation:
1. Go to Manage CSEDS Subjects
2. Click "Add New Subject"
3. Fill in details
4. Click Save
5. Verify appears in list

### Test Student Enrollment:
1. Login as student
2. Select a subject
3. Choose faculty
4. Verify enrollment count increases

---

## ? Emergency Commands

### Restart Everything:
```bash
Ctrl+C           # Stop app
dotnet clean     # Clean
dotnet build     # Build
dotnet run       # Start
Ctrl+Shift+R     # Hard refresh browser
```

### Reset Database:
```bash
dotnet ef database drop      # WARNING: Deletes all data!
dotnet ef database update    # Recreates with migrations
```

---

## ?? When Things Go Wrong

### Step 1: Check Console Logs
Look for errors in:
- Browser console (F12)
- VS Code terminal

### Step 2: Enable Detailed Logging
Add to `appsettings.Development.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Microsoft.EntityFrameworkCore": "Information"
    }
  }
}
```

### Step 3: Check Network Tab
F12 ? Network ? Find failing request ? Check:
- Request Payload
- Response
- Status Code

---

## ?? Full Documentation

For detailed information, see:
- **COMPREHENSIVE_DOCUMENTATION.md** - Complete guide
- **README.md** - Quick start
- **PROJECT_SUMMARY.md** - Project overview

---

## ?? Most Common Issues

1. **Faculty update not saving** ? Check EntityState.Modified
2. **Modal not closing** ? Use bootstrap.Modal methods
3. **400 Bad Request** ? Send all required properties
4. **Database connection error** ? Check connection string
5. **Migration error** ? Remove last migration and recreate

---

**Keep this file open while working for quick reference!**

*Last Updated: December 2024*
