-- ========================================
-- DIAGNOSE EDIT DEPARTMENT STATISTICS ISSUE
-- ========================================
-- This will show us what's happening with the department codes

PRINT '========================================';
PRINT 'CURRENT DATABASE STATE';
PRINT '========================================';
PRINT '';

-- 1. Check the Departments table
PRINT '1. DEPARTMENTS TABLE:';
SELECT 
    DepartmentId,
    DepartmentName,
    DepartmentCode,
    HeadOfDepartment,
    HeadOfDepartmentEmail,
    IsActive,
    CreatedDate,
    LastModifiedDate
FROM Departments
ORDER BY DepartmentId;
PRINT '';

-- 2. Check ALL department codes in use
PRINT '2. ALL DEPARTMENT CODES IN SYSTEM:';
SELECT 'Departments' AS TableName, DepartmentCode AS Code, COUNT(*) AS Count
FROM Departments
GROUP BY DepartmentCode

UNION ALL

SELECT 'Students', Department, COUNT(*)
FROM Students
GROUP BY Department

UNION ALL

SELECT 'Faculties', Department, COUNT(*)
FROM Faculties
GROUP BY Department

UNION ALL

SELECT 'Subjects', Department, COUNT(*)
FROM Subjects
GROUP BY Department

UNION ALL

SELECT 'Admins', Department, COUNT(*)
FROM Admins
GROUP BY Department

ORDER BY TableName, Code;
PRINT '';

-- 3. Specific check for CSE(DS) vs CSEDS
PRINT '3. CSE DATA SCIENCE VARIATIONS:';
SELECT 
    TableName,
    Code,
    Count,
    CASE 
        WHEN Code = 'CSEDS' THEN '? CORRECT'
        WHEN Code IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSDS') THEN '? NEEDS NORMALIZATION'
        ELSE '? OTHER DEPT'
    END AS Status
FROM (
    SELECT 'Departments' AS TableName, DepartmentCode AS Code, COUNT(*) AS Count
    FROM Departments
    WHERE DepartmentCode LIKE '%CSE%DS%' OR DepartmentCode = 'CSEDS'
    GROUP BY DepartmentCode
    
    UNION ALL
    
    SELECT 'Students', Department, COUNT(*)
    FROM Students
    WHERE Department LIKE '%CSE%DS%' OR Department = 'CSEDS'
    GROUP BY Department
    
    UNION ALL
    
    SELECT 'Faculties', Department, COUNT(*)
    FROM Faculties
    WHERE Department LIKE '%CSE%DS%' OR Department = 'CSEDS'
    GROUP BY Department
    
    UNION ALL
    
    SELECT 'Subjects', Department, COUNT(*)
    FROM Subjects
    WHERE Department LIKE '%CSE%DS%' OR Department = 'CSEDS'
    GROUP BY Department
    
    UNION ALL
    
    SELECT 'Admins', Department, COUNT(*)
    FROM Admins
    WHERE Department LIKE '%CSE%DS%' OR Department = 'CSEDS'
    GROUP BY Department
) AS DeptCodes
ORDER BY TableName, Code;
PRINT '';

-- 4. Check what EditDepartment would show for Department ID 1
PRINT '4. WHAT EditDepartment/1 SHOULD SHOW:';
DECLARE @DeptId INT = 1;
DECLARE @DeptCode NVARCHAR(50);

SELECT @DeptCode = DepartmentCode FROM Departments WHERE DepartmentId = @DeptId;

SELECT 
    'Department Info' AS Section,
    d.DepartmentId,
    d.DepartmentName,
    d.DepartmentCode,
    d.HeadOfDepartment,
    d.HeadOfDepartmentEmail,
    (SELECT COUNT(*) FROM Students WHERE Department = d.DepartmentCode) AS TotalStudents_DirectMatch,
    (SELECT COUNT(*) FROM Students WHERE Department = 'CSEDS') AS TotalStudents_CSEDS,
    (SELECT COUNT(*) FROM Students WHERE Department = 'CSE(DS)') AS TotalStudents_CSEDS_Parens,
    (SELECT COUNT(*) FROM Faculties WHERE Department = d.DepartmentCode) AS TotalFaculty_DirectMatch,
    (SELECT COUNT(*) FROM Faculties WHERE Department = 'CSEDS') AS TotalFaculty_CSEDS,
    (SELECT COUNT(*) FROM Subjects WHERE Department = d.DepartmentCode) AS TotalSubjects_DirectMatch,
    (SELECT COUNT(*) FROM Subjects WHERE Department = 'CSEDS') AS TotalSubjects_CSEDS
FROM Departments d
WHERE d.DepartmentId = @DeptId;
PRINT '';

-- 5. Check for mismatched data
PRINT '5. POTENTIAL MISMATCH ISSUES:';
IF EXISTS (
    SELECT 1 FROM Departments WHERE DepartmentCode = 'CSE(DS)'
) AND EXISTS (
    SELECT 1 FROM Students WHERE Department = 'CSEDS'
)
BEGIN
    PRINT '? MISMATCH DETECTED:';
    PRINT '   - Department table has: CSE(DS)';
    PRINT '   - Students table has: CSEDS';
    PRINT '   - This will cause statistics to show ZERO!';
    PRINT '';
    PRINT 'FIX: Run the normalization script to standardize to CSEDS';
END
ELSE IF EXISTS (
    SELECT 1 FROM Departments WHERE DepartmentCode = 'CSEDS'
) AND EXISTS (
    SELECT 1 FROM Students WHERE Department = 'CSE(DS)'
)
BEGIN
    PRINT '? MISMATCH DETECTED:';
    PRINT '   - Department table has: CSEDS';
    PRINT '   - Students table has: CSE(DS)';
    PRINT '   - This will cause statistics to show ZERO!';
    PRINT '';
    PRINT 'FIX: Run the normalization script to standardize to CSEDS';
END
ELSE
BEGIN
    PRINT '? No obvious mismatches detected';
    PRINT '   All tables appear to be using the same department code format';
END

PRINT '';
PRINT '========================================';
PRINT 'DIAGNOSIS COMPLETE';
PRINT '========================================';
