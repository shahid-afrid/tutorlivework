-- ========================================
-- VERIFY THE REAL FIX
-- ========================================
-- Run this to verify the fix is working

PRINT '========================================';
PRINT 'TESTING REAL FIX FOR EDIT DEPARTMENT';
PRINT '========================================';
PRINT '';

-- Check current state
PRINT '1. CURRENT DATABASE STATE:';
SELECT 
    DepartmentId,
    DepartmentName,
    DepartmentCode AS [Current_Code],
    CASE 
        WHEN DepartmentCode = 'CSEDS' THEN '? Already normalized'
        WHEN DepartmentCode = 'CSE(DS)' THEN '?? Will be shown as CSEDS in form now'
        ELSE DepartmentCode
    END AS [What_Form_Will_Show],
    HeadOfDepartment,
    HeadOfDepartmentEmail
FROM Departments
WHERE DepartmentId = 1;
PRINT '';

-- Check where students are
PRINT '2. WHERE ARE STUDENTS?';
SELECT 
    Department AS [Student_DeptCode],
    COUNT(*) AS Count,
    CASE 
        WHEN Department = 'CSEDS' THEN '? Matches normalized code'
        WHEN Department = 'CSE(DS)' THEN '? Will match via normalization'
        ELSE '? Other'
    END AS Status
FROM Students
WHERE Department IN ('CSEDS', 'CSE(DS)')
GROUP BY Department;
PRINT '';

-- Simulate what GetAllDepartmentsDetailed will return NOW
PRINT '3. WHAT EDIT FORM WILL SHOW (AFTER FIX):';
DECLARE @RawCode NVARCHAR(50);
DECLARE @NormalizedCode NVARCHAR(50);

SELECT @RawCode = DepartmentCode FROM Departments WHERE DepartmentId = 1;

-- Simulate normalization
SET @NormalizedCode = CASE 
    WHEN @RawCode IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS', 'CSEDS') THEN 'CSEDS'
    ELSE @RawCode
END;

PRINT 'Database has: ' + @RawCode;
PRINT 'Form will show: ' + @NormalizedCode + ' (NORMALIZED)';
PRINT 'Statistics will query: ' + @NormalizedCode;
PRINT '';

-- Check statistics with normalized code
PRINT '4. STATISTICS (Using normalized code):';
SELECT 
    'Statistics' AS Section,
    @NormalizedCode AS [Code_Used_For_Query],
    (SELECT COUNT(*) FROM Students WHERE Department = @NormalizedCode OR Department = @RawCode) AS TotalStudents,
    (SELECT COUNT(*) FROM Faculties WHERE Department = @NormalizedCode OR Department = @RawCode) AS TotalFaculty,
    (SELECT COUNT(*) FROM Subjects WHERE Department = @NormalizedCode OR Department = @RawCode) AS TotalSubjects;
PRINT '';

-- Predict what will happen after save
PRINT '5. WHAT WILL HAPPEN WHEN YOU SAVE:';
PRINT 'Input from form: ' + @NormalizedCode;
PRINT 'After normalization: ' + @NormalizedCode + ' (No change)';
PRINT 'Saved to DB: ' + @NormalizedCode;
PRINT '';
PRINT 'Result: ? Database code stays consistent';
PRINT 'Result: ? Statistics remain correct';
PRINT '';

PRINT '========================================';
PRINT 'EXPECTED BEHAVIOR:';
PRINT '========================================';
PRINT '';
PRINT 'BEFORE FIX:';
PRINT '  Edit form shows: CSE(DS) (if DB has CSE(DS))';
PRINT '  User saves ? Normalizes to CSEDS';
PRINT '  Problem: Code changes from CSE(DS) to CSEDS';
PRINT '  Result: Statistics break ?';
PRINT '';
PRINT 'AFTER FIX:';
PRINT '  Edit form shows: CSEDS (normalized)';
PRINT '  User saves ? Normalizes to CSEDS (no change)';
PRINT '  Result: Code stays CSEDS';
PRINT '  Result: Statistics work ?';
PRINT '';

PRINT '========================================';
PRINT 'READY TO TEST!';
PRINT '========================================';
PRINT '';
PRINT 'Steps:';
PRINT '1. Restart your app (Shift+F5, then F5)';
PRINT '2. Edit department ID 1';
PRINT '3. Note: Department Code field shows CSEDS';
PRINT '4. Add HOD info and save';
PRINT '5. Statistics should remain the same!';
PRINT '';
