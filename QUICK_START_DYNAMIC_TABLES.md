# ?? QUICK START - Dynamic Table Architecture

## ? What You Need to Know

**Big Change**: Each department now gets its own isolated database tables!

```
Before: Students (all depts mixed)
After:  Students_CSEDS, Students_CSE, Students_ECE, etc.
```

## ?? Step-by-Step Implementation

### Step 1: Run the Migration ? (5 minutes)

```powershell
# Open PowerShell in project root
.\RUN_DYNAMIC_TABLE_MIGRATION.ps1
```

This creates:
- ? `Faculty_CSEDS`
- ? `Students_CSEDS`
- ? `Subjects_CSEDS`
- ? `AssignedSubjects_CSEDS`
- ? `StudentEnrollments_CSEDS`

And migrates all existing CSEDS data!

### Step 2: Test CSEDS Admin (5 minutes)

1. Login as CSEDS admin
2. Go to Dynamic Dashboard
3. Check if faculty/students show correctly
4. Try adding a new faculty member
5. Try adding a new student

**If everything works ? You're 50% done!** ?

### Step 3: Update One Controller Method (Example)

**OLD CODE** (queries shared table):
```csharp
public async Task<IActionResult> ManageFaculty()
{
    var faculty = await _context.Faculties
        .Where(f => f.Department == "CSEDS")
        .ToListAsync();
    
    return View(faculty);
}
```

**NEW CODE** (queries department-specific table):
```csharp
private readonly DynamicDbContextFactory _dbFactory;

public async Task<IActionResult> ManageFaculty(string department)
{
    using var context = _dbFactory.GetContext(department);
    
    var faculty = await context.Faculties.ToListAsync();  // ? Faculty_CSEDS
    
    return View(faculty);
}
```

**That's it!** The `GetContext(department)` automatically maps to the right table.

### Step 4: Repeat for Other Departments (10 minutes each)

Create tables for CSE:
```csharp
// In SuperAdmin -> Create Department
await _dynamicTableService.CreateDepartmentTables("CSE");
```

This automatically creates:
- `Faculty_CSE`
- `Students_CSE`
- `Subjects_CSE`
- etc.

### Step 5: Verify (5 minutes)

```sql
-- Check what tables exist
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%_CSEDS' OR TABLE_NAME LIKE '%_CSE'
ORDER BY TABLE_NAME

-- Count records per department
SELECT 'CSEDS Faculty', COUNT(*) FROM Faculty_CSEDS
UNION ALL
SELECT 'CSEDS Students', COUNT(*) FROM Students_CSEDS
UNION ALL
SELECT 'CSE Faculty', COUNT(*) FROM Faculty_CSE
UNION ALL
SELECT 'CSE Students', COUNT(*) FROM Students_CSE
```

## ?? Key Concepts

### 1. DynamicDbContextFactory

**What it does**: Creates a DbContext that points to department-specific tables

```csharp
// Inject in controller constructor
private readonly DynamicDbContextFactory _dbFactory;

public AdminController(DynamicDbContextFactory dbFactory)
{
    _dbFactory = dbFactory;
}

// Use in methods
using var context = _dbFactory.GetContext("CSEDS");
var students = await context.Students.ToListAsync();  // Queries Students_CSEDS
```

### 2. DynamicTableService

**What it does**: Creates and manages department-specific tables

```csharp
// Inject in service
private readonly DynamicTableService _tableService;

// Create tables for new department
var result = await _tableService.CreateDepartmentTables("ECE");

// Check if tables exist
bool exists = await _tableService.TableExists("Faculty_ECE");

// Migrate existing data
var migration = await _tableService.MigrateExistingData("ECE");
```

### 3. Automatic Setup

When SuperAdmin creates a department, **tables are created automatically**:

```csharp
// SuperAdminController -> CreateDepartment
// Tables are created by DynamicDepartmentSetupService automatically
// No manual intervention needed!
```

## ?? Checklist

### Phase 1: CSEDS (Current)
- [x] Create dynamic table services
- [x] Create migration script
- [x] Run migration for CSEDS
- [ ] Test CSEDS functionality
- [ ] Verify data integrity

### Phase 2: Update Controllers
- [ ] AdminController ? DynamicFaculty methods
- [ ] AdminController ? DynamicStudent methods
- [ ] AdminController ? DynamicSubject methods
- [ ] StudentController ? Use dynamic tables
- [ ] FacultyController ? Use dynamic tables

### Phase 3: Other Departments
- [ ] Create CSE tables
- [ ] Create ECE tables
- [ ] Create MECH tables
- [ ] Test each department

### Phase 4: Cleanup
- [ ] Archive old shared tables
- [ ] Remove deprecated code
- [ ] Update all documentation

## ?? Common Patterns

### Pattern 1: Get Department Context
```csharp
using var context = _dbFactory.GetContext(department);
```

### Pattern 2: Query Department Data
```csharp
var students = await context.Students.ToListAsync();  // Auto-mapped to Students_{dept}
var faculty = await context.Faculties.ToListAsync();   // Auto-mapped to Faculty_{dept}
```

### Pattern 3: Save to Department Table
```csharp
using var context = _dbFactory.GetContext(department);
context.Students.Add(newStudent);
await context.SaveChangesAsync();  // Saves to Students_{dept}
```

### Pattern 4: Cross-Table Joins (Within Department)
```csharp
using var context = _dbFactory.GetContext(department);

var enrollments = await context.StudentEnrollments
    .Include(se => se.Student)       // From Students_{dept}
    .Include(se => se.AssignedSubject) // From AssignedSubjects_{dept}
        .ThenInclude(a => a.Subject)   // From Subjects_{dept}
        .ThenInclude(s => s.Faculty)   // From Faculty_{dept}
    .ToListAsync();
```

## ?? Important Notes

### DO ?
- Always use `using var context = ...` (auto-dispose)
- Use `GetContext(department)` for department operations
- Test queries in SQL first
- Verify table exists before operations

### DON'T ?
- Don't hardcode table names
- Don't query shared tables for department data
- Don't forget to dispose contexts
- Don't mix department data

## ?? Troubleshooting

### Issue: "Table does not exist"
```csharp
// Check if table exists
bool exists = await _tableService.TableExists($"Faculty_{deptCode}");

// Create if missing
if (!exists) {
    var result = await _tableService.CreateDepartmentTables(deptCode);
}
```

### Issue: "No data showing"
```sql
-- Check if data was migrated
SELECT COUNT(*) FROM Faculty_CSEDS;
SELECT COUNT(*) FROM Students_CSEDS;

-- If zero, run migration again
```

### Issue: "Wrong department data showing"
```csharp
// Verify department code
var normalizedCode = DynamicTableConfiguration.NormalizeDepartmentCode(department);
Console.WriteLine($"Using department: {normalizedCode}");

// Clear cache and try again
_dbFactory.ClearCache(department);
```

## ?? Further Reading

- **Full Guide**: `DYNAMIC_DATABASE_ARCHITECTURE_GUIDE.md`
- **Migration Script**: `Migrations/SplitToDepartmentTables.sql`
- **Services**: `Services/DynamicTableService.cs`
- **Factory**: `Services/DynamicDbContextFactory.cs`

## ?? Success Criteria

You know it's working when:
1. ? CSEDS admin sees only CSEDS data
2. ? CSE admin sees only CSE data (when implemented)
3. ? SQL queries show separate tables per department
4. ? Adding data to one department doesn't affect others
5. ? Performance is faster (smaller tables)

## ?? Need Help?

1. Check SQL tables: `SELECT * FROM Faculty_CSEDS`
2. Verify context: `Console.WriteLine(context.GetDepartmentCode())`
3. Check logs: Look for `[DYNAMIC SETUP]` messages
4. Re-run migration: `.\RUN_DYNAMIC_TABLE_MIGRATION.ps1`

---

**Status**: Infrastructure ? Complete
**Next**: Test CSEDS ? Update Controllers ? Roll out to other departments

Let's go! ??
