# FIX YEAR 2 ENROLLMENT LIMIT ISSUE - COMPLETE GUIDE

## ?? THE PROBLEM

Second-year students are being enrolled BEYOND the 60-student limit because:

### 1. **Database Schema is OUTDATED** ?
Your `Subjects` table only has 2 columns:
- `Id`
- `Name`

But the code expects these columns:
- `SubjectId`
- `Name`
- `Department`
- `Year`
- `SubjectType`
- `MaxEnrollments` ? **THIS IS MISSING!**
- `Semester`
- `SemesterStartDate`
- `SemesterEndDate`

### 2. **Code is CORRECT** ?
The enrollment logic at `StudentController.cs` line 496 correctly uses:
```csharp
var maxLimit = assignedSubject.Subject.MaxEnrollments ?? 70;
```

But since the `MaxEnrollments` column doesn't exist in your database, it defaults to NULL, which becomes 70!

---

## ??? THE FIX (DO THIS IN ORDER)

### STEP 1: STOP THE RUNNING APPLICATION

**You MUST stop the app before running migrations!**

1. In Visual Studio, press **Shift + F5** (Stop Debugging)
2. OR click the red ? Stop button
3. **Close any open browser tabs** for the app
4. **Wait 10 seconds** for the process to fully terminate

### STEP 2: APPLY THE DATABASE MIGRATION

Open **Package Manager Console** in Visual Studio:
- `Tools` ? `NuGet Package Manager` ? `Package Manager Console`

Run this command:
```powershell
Update-Database -Verbose
```

This will apply the `20251128021006_InitialMigration` which adds all missing columns.

**OR** use Command Prompt/PowerShell:
```powershell
cd C:\Users\shahi\Source\Repos\tutor-livev1
dotnet ef database update
```

### STEP 3: VERIFY THE SCHEMA WAS UPDATED

Run this SQL query to check if the columns were added:
```sql
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Subjects' 
ORDER BY ORDINAL_POSITION;
```

**Expected Output:**
```
SubjectId         int
Name              nvarchar
Department        nvarchar
Year              int          ? SHOULD BE HERE NOW!
Semester          nvarchar
SemesterStartDate datetime2
SemesterEndDate   datetime2
SubjectType       nvarchar     ? SHOULD BE HERE NOW!
MaxEnrollments    int          ? SHOULD BE HERE NOW!
```

### STEP 4: SET MaxEnrollments FOR YEAR 2 SUBJECTS

Now that the column exists, set the correct limits:

```sql
-- Set Year 2 Core subjects to 60-student limit
UPDATE Subjects
SET MaxEnrollments = 60
WHERE Year = 2 
  AND SubjectType = 'Core';

-- Set Year 3 and Year 4 Core subjects to 70-student limit
UPDATE Subjects
SET MaxEnrollments = 70
WHERE Year IN (3, 4) 
  AND SubjectType = 'Core';

-- Verify the update
SELECT SubjectId, Name, Year, SubjectType, MaxEnrollments
FROM Subjects
WHERE SubjectType = 'Core'
ORDER BY Year, Name;
```

### STEP 5: VERIFY THE FIX

Check current enrollment counts:
```sql
SELECT 
    s.Name AS SubjectName,
    s.Year,
    s.MaxEnrollments AS Limit,
    COUNT(DISTINCT se.StudentId) AS CurrentEnrollments,
    s.MaxEnrollments - COUNT(DISTINCT se.StudentId) AS SpotsLeft
FROM 
    Subjects s
    LEFT JOIN AssignedSubjects asub ON s.SubjectId = asub.SubjectId
    LEFT JOIN StudentEnrollments se ON asub.AssignedSubjectId = se.AssignedSubjectId
WHERE 
    s.Year = 2 
    AND s.SubjectType = 'Core'
GROUP BY 
    s.SubjectId, s.Name, s.Year, s.MaxEnrollments
ORDER BY 
    CurrentEnrollments DESC;
```

### STEP 6: START THE APPLICATION

Now restart your app and test:

1. Press **F5** in Visual Studio
2. Login as a Year 2 student
3. Try to enroll in a subject
4. **If 60 students are already enrolled, you should see:**
   ```
   "This subject is already full (maximum 60 students). Someone enrolled just before you."
   ```

---

## ?? QUICK TROUBLESHOOTING

### If migration fails with "Build failed"
**Problem:** App is still running
**Solution:** 
1. Check Task Manager for `TutorLiveMentor10.exe`
2. End the process
3. Try migration again

### If migration says "No migrations were applied"
**Problem:** Migration was already applied before
**Solution:** 
1. Check if columns exist: `SELECT * FROM Subjects`
2. If columns exist, skip to STEP 4

### If you see "Invalid column name 'MaxEnrollments'"
**Problem:** Migration didn't apply successfully
**Solution:**
1. Drop and recreate the database:
   ```powershell
   Drop-Database
   Update-Database
   ```
2. **WARNING:** This deletes all data! Only do this if it's test data.

---

## ? FINAL VERIFICATION CHECKLIST

- [ ] App is stopped
- [ ] Migration applied successfully
- [ ] `Subjects` table has `Year`, `SubjectType`, `MaxEnrollments` columns
- [ ] Year 2 subjects have `MaxEnrollments = 60`
- [ ] Year 3/4 subjects have `MaxEnrollments = 70`
- [ ] App restarted
- [ ] Tested enrollment with Year 2 student
- [ ] Enrollment blocked at 60 students ?

---

## ?? WHY THIS WORKS

**Before Fix:**
```
Database: MaxEnrollments column doesn't exist
Code:     var maxLimit = assignedSubject.Subject.MaxEnrollments ?? 70;
Result:   NULL ?? 70 = 70 (WRONG for Year 2!)
```

**After Fix:**
```
Database: MaxEnrollments = 60 (for Year 2)
Code:     var maxLimit = assignedSubject.Subject.MaxEnrollments ?? 70;
Result:   60 ?? 70 = 60 (CORRECT!)
```

---

## ?? WHAT CHANGED IN THE CODE (ALREADY DONE)

These fixes were already applied in previous sessions:

### `StudentController.cs` (Line 496)
```csharp
// ? FIXED - Now uses Subject.MaxEnrollments
var maxLimit = assignedSubject.Subject.MaxEnrollments ?? 70;
```

### `SubjectSelectionValidator.cs` (Line 55)
```csharp
// ? FIXED - Now checks Subject.MaxEnrollments
var coreSubjects = availableSubjects
    .Where(s => s.Subject.SubjectType == "Core" && 
               s.SelectedCount < (s.Subject.MaxEnrollments ?? 70))
```

---

**THAT'S IT! Your Year 2 enrollment limit should now work correctly!** ??
