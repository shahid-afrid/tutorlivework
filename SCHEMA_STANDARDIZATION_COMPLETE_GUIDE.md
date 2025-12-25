# SCHEMA STANDARDIZATION - ALL DEPARTMENTS MATCH CSEDS

## ?? PROBLEM IDENTIFIED

You discovered that the schema for DES, IT, ECE, and MECH departments was **DIFFERENT** from CSEDS!

### Wrong Schema (DES, IT, ECE, MECH):
```
Faculty_{DEPT}: FacultyId, Name, Email, Password, Department, Specialization, Qualification, ExperienceYears, PhoneNumber, IsActive, CreatedDate, LastLogin, ProfileImageUrl

Students_{DEPT}: StudentId, Id, FullName, RegdNumber, Department, Year, Semester, Email, PhoneNumber, Password, IsActive, CreatedDate, LastLogin

Subjects_{DEPT}: SubjectId, Name, SubjectCode, Department, SubjectType, Year, Semester, Credits, IsActive, CreatedDate

AssignedSubjects_{DEPT}: AssignmentId, SubjectId, FacultyId, Department, Year, Semester, MaxEnrollments, CurrentEnrollments, IsActive, AssignedDate

StudentEnrollments_{DEPT}: EnrollmentId, StudentId, AssignmentId, SubjectId, FacultyId, EnrollmentDate, IsActive
```

### Correct Schema (CSEDS Standard):
```
Faculty_{DEPT}: FacultyId, Name, Email, Password, Department

Students_{DEPT}: Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject

Subjects_{DEPT}: SubjectId, Name, Department, Year, Semester, SemesterStartDate, SemesterEndDate, SubjectType, MaxEnrollments

AssignedSubjects_{DEPT}: AssignedSubjectId, FacultyId, SubjectId, Department, Year, SelectedCount

StudentEnrollments_{DEPT}: StudentId, AssignedSubjectId, EnrolledAt
```

## ? SOLUTION

I created a complete schema standardization system that:

1. **Drops all existing department tables** (DES, IT, ECE, MECH)
2. **Recreates them with EXACT CSEDS schema**
3. **Verifies schema consistency** across all departments
4. **Preserves CSEDS** (already correct)

## ?? FILES CREATED

### 1. `STANDARDIZE_ALL_DEPT_SCHEMAS_TO_CSEDS.sql`
- Drops old tables with wrong schema
- Creates new tables matching CSEDS exactly
- Uses dynamic SQL to process all departments
- Adds all indexes and foreign keys

### 2. `VERIFY_SCHEMA_CONSISTENCY.sql`
- Compares schemas across all departments
- Checks column names, data types, lengths
- Verifies foreign keys and indexes
- Provides detailed reports

### 3. `RUN_SCHEMA_STANDARDIZATION.ps1`
- PowerShell script to run both SQL files
- Includes confirmation prompt
- Shows progress and results
- Validates completion

## ?? HOW TO RUN

### Step 1: Run Schema Standardization
```powershell
.\RUN_SCHEMA_STANDARDIZATION.ps1
```

**What it does:**
1. Asks for confirmation (type "YES")
2. Drops and recreates DES, IT, ECE, MECH tables
3. Applies CSEDS schema to all
4. Runs verification
5. Shows detailed results

### Step 2: Migrate Data (After Schema Fix)
```powershell
.\RUN_DATA_MIGRATION_ALL_DEPTS.ps1
```

## ?? SCHEMA COMPARISON

### Table: Faculty_{DEPT}

| Column | Data Type | CSEDS | DES | IT | ECE | MECH | Status |
|--------|-----------|-------|-----|----|----|------|--------|
| FacultyId | INT | ? | ? | ? | ? | ? | Match |
| Name | NVARCHAR(100) | ? | ? | ? | ? | ? | Match |
| Email | NVARCHAR(100) | ? | ? | ? | ? | ? | Match |
| Password | NVARCHAR(255) | ? | ? | ? | ? | ? | Match |
| Department | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |

### Table: Students_{DEPT}

| Column | Data Type | CSEDS | DES | IT | ECE | MECH | Status |
|--------|-----------|-------|-----|----|----|------|--------|
| Id | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |
| FullName | NVARCHAR(200) | ? | ? | ? | ? | ? | Match |
| RegdNumber | NVARCHAR(10) | ? | ? | ? | ? | ? | Match |
| Year | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |
| Department | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |
| Semester | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |
| Email | NVARCHAR(200) | ? | ? | ? | ? | ? | Match |
| Password | NVARCHAR(500) | ? | ? | ? | ? | ? | Match |
| SelectedSubject | NVARCHAR(MAX) | ? | ? | ? | ? | ? | Match |

### Table: Subjects_{DEPT}

| Column | Data Type | CSEDS | DES | IT | ECE | MECH | Status |
|--------|-----------|-------|-----|----|----|------|--------|
| SubjectId | INT | ? | ? | ? | ? | ? | Match |
| Name | NVARCHAR(200) | ? | ? | ? | ? | ? | Match |
| Department | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |
| Year | INT | ? | ? | ? | ? | ? | Match |
| Semester | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |
| SemesterStartDate | DATETIME2 | ? | ? | ? | ? | ? | Match |
| SemesterEndDate | DATETIME2 | ? | ? | ? | ? | ? | Match |
| SubjectType | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |
| MaxEnrollments | INT | ? | ? | ? | ? | ? | Match |

### Table: AssignedSubjects_{DEPT}

| Column | Data Type | CSEDS | DES | IT | ECE | MECH | Status |
|--------|-----------|-------|-----|----|----|------|--------|
| AssignedSubjectId | INT | ? | ? | ? | ? | ? | Match |
| FacultyId | INT | ? | ? | ? | ? | ? | Match |
| SubjectId | INT | ? | ? | ? | ? | ? | Match |
| Department | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |
| Year | INT | ? | ? | ? | ? | ? | Match |
| SelectedCount | INT | ? | ? | ? | ? | ? | Match |

### Table: StudentEnrollments_{DEPT}

| Column | Data Type | CSEDS | DES | IT | ECE | MECH | Status |
|--------|-----------|-------|-----|----|----|------|--------|
| StudentId | NVARCHAR(50) | ? | ? | ? | ? | ? | Match |
| AssignedSubjectId | INT | ? | ? | ? | ? | ? | Match |
| EnrolledAt | DATETIME2 | ? | ? | ? | ? | ? | Match |

## ? VERIFICATION QUERIES

### Check Table Existence
```sql
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%_CSEDS' OR TABLE_NAME LIKE '%_DES' 
   OR TABLE_NAME LIKE '%_IT' OR TABLE_NAME LIKE '%_ECE' 
   OR TABLE_NAME LIKE '%_MECH'
ORDER BY TABLE_NAME;
```

### Compare Column Counts
```sql
SELECT 
    TABLE_NAME,
    COUNT(*) AS ColumnCount
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Faculty_CSEDS', 'Faculty_DES', 'Faculty_IT', 'Faculty_ECE', 'Faculty_MECH')
GROUP BY TABLE_NAME;
```

### Check Foreign Keys
```sql
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    fk.name AS ConstraintName
FROM sys.foreign_keys fk
WHERE OBJECT_NAME(fk.parent_object_id) LIKE '%_DES' 
   OR OBJECT_NAME(fk.parent_object_id) LIKE '%_IT'
   OR OBJECT_NAME(fk.parent_object_id) LIKE '%_ECE'
   OR OBJECT_NAME(fk.parent_object_id) LIKE '%_MECH'
ORDER BY TableName;
```

## ?? WHAT'S DIFFERENT NOW?

### Before:
- DES, IT, ECE, MECH had **extra columns** (IsActive, CreatedDate, etc.)
- Different primary key names (AssignmentId vs AssignedSubjectId)
- Different column names (CurrentEnrollments vs SelectedCount)
- Inconsistent data types and lengths

### After:
- **ALL departments identical to CSEDS**
- Same column names everywhere
- Same data types and lengths
- Same indexes and foreign keys
- **100% consistency**

## ?? BENEFITS

1. **Code Reusability**: Same queries work for all departments
2. **Maintenance**: Fix once, applies to all
3. **Testing**: Test one, confident for all
4. **Documentation**: One schema reference
5. **Migration**: Easier to add new departments

## ?? IMPORTANT NOTES

1. **Data Loss Warning**: Running standardization will DROP existing tables
2. **Backup First**: Always backup before running
3. **Run in Order**: 
   - First: Schema standardization
   - Then: Data migration
4. **CSEDS Preserved**: CSEDS tables are NOT touched (already correct)

## ?? CHECKLIST

Before running:
- [ ] Backup database
- [ ] Review schema differences
- [ ] Understand data will be recreated
- [ ] Have data migration script ready

After running:
- [ ] Verify all 25 tables exist (5 per department × 5 departments)
- [ ] Check schema consistency report
- [ ] Confirm foreign keys created
- [ ] Run data migration
- [ ] Test application

## ?? QUICK START

```powershell
# 1. Standardize schemas
.\RUN_SCHEMA_STANDARDIZATION.ps1

# 2. Check results in SQL Server Management Studio

# 3. Run data migration (next step)
```

## ? SUCCESS CRITERIA

Schema standardization is successful when:
- [ ] All 25 tables exist (Faculty, Students, Subjects, AssignedSubjects, StudentEnrollments for each dept)
- [ ] All tables have IDENTICAL column structure
- [ ] All foreign keys properly created
- [ ] All indexes properly created
- [ ] Verification script shows "ALL SCHEMAS MATCH"
- [ ] No compilation errors in application

## ?? SUPPORT

If you encounter issues:
1. Check SQL Server logs
2. Review verification output
3. Ensure proper permissions
4. Verify connection string
5. Run verification script separately

---

**Created**: 2025-12-23
**Status**: Ready to Execute
**Risk Level**: Medium (requires table recreation)
**Estimated Time**: 2-5 minutes
