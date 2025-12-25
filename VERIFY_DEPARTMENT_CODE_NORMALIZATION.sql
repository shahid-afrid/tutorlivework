-- ========================================
-- VERIFY DEPARTMENT CODE NORMALIZATION FIX
-- ========================================
-- Run this to check if department codes are properly normalized to CSEDS

PRINT '========================================';
PRINT 'CHECKING DEPARTMENT CODE CONSISTENCY';
PRINT '========================================';
PRINT '';

-- Check Departments table
PRINT '1. DEPARTMENTS TABLE:';
SELECT 
    DepartmentId,
    DepartmentName,
    DepartmentCode,
    HeadOfDepartment,
    HeadOfDepartmentEmail,
    IsActive,
    CASE 
        WHEN DepartmentCode = 'CSEDS' THEN '? CORRECT'
        WHEN DepartmentCode LIKE '%CSE%DS%' THEN '? NEEDS FIX (Use CSEDS)'
        ELSE '? OTHER DEPARTMENT'
    END AS Status
FROM Departments
ORDER BY DepartmentCode;

PRINT '';
PRINT '2. ADMINS TABLE:';
SELECT 
    AdminId,
    Email,
    Department,
    CreatedDate,
    LastLogin,
    CASE 
        WHEN Department = 'CSEDS' THEN '? CORRECT'
        WHEN Department LIKE '%CSE%DS%' THEN '? NEEDS FIX (Use CSEDS)'
        ELSE '? OTHER DEPARTMENT'
    END AS Status
FROM Admins
WHERE Department LIKE '%CSE%'
ORDER BY Department;

PRINT '';
PRINT '3. STUDENTS COUNT BY DEPARTMENT:';
SELECT 
    Department,
    COUNT(*) AS StudentCount,
    CASE 
        WHEN Department = 'CSEDS' THEN '? CORRECT'
        WHEN Department LIKE '%CSE%DS%' THEN '? NEEDS FIX (Use CSEDS)'
        ELSE '? OTHER DEPARTMENT'
    END AS Status
FROM Students
GROUP BY Department
ORDER BY Department;

PRINT '';
PRINT '4. FACULTY COUNT BY DEPARTMENT:';
SELECT 
    Department,
    COUNT(*) AS FacultyCount,
    CASE 
        WHEN Department = 'CSEDS' THEN '? CORRECT'
        WHEN Department LIKE '%CSE%DS%' THEN '? NEEDS FIX (Use CSEDS)'
        ELSE '? OTHER DEPARTMENT'
    END AS Status
FROM Faculties
GROUP BY Department
ORDER BY Department;

PRINT '';
PRINT '5. SUBJECTS COUNT BY DEPARTMENT:';
SELECT 
    Department,
    COUNT(*) AS SubjectCount,
    CASE 
        WHEN Department = 'CSEDS' THEN '? CORRECT'
        WHEN Department LIKE '%CSE%DS%' THEN '? NEEDS FIX (Use CSEDS)'
        ELSE '? OTHER DEPARTMENT'
    END AS Status
FROM Subjects
GROUP BY Department
ORDER BY Department;

PRINT '';
PRINT '========================================';
PRINT 'SUMMARY:';
PRINT '========================================';

-- Check if any CSE(DS) variations exist
DECLARE @HasCSEDSVariations BIT = 0;

IF EXISTS (
    SELECT 1 FROM Departments WHERE DepartmentCode LIKE '%CSE%DS%' AND DepartmentCode != 'CSEDS'
    UNION
    SELECT 1 FROM Admins WHERE Department LIKE '%CSE%DS%' AND Department != 'CSEDS'
    UNION
    SELECT 1 FROM Students WHERE Department LIKE '%CSE%DS%' AND Department != 'CSEDS'
    UNION
    SELECT 1 FROM Faculties WHERE Department LIKE '%CSE%DS%' AND Department != 'CSEDS'
    UNION
    SELECT 1 FROM Subjects WHERE Department LIKE '%CSE%DS%' AND Department != 'CSEDS'
)
BEGIN
    SET @HasCSEDSVariations = 1;
    PRINT '? FOUND CSE(DS) VARIATIONS - Run the fix script below:';
    PRINT '';
    PRINT '-- QUICK FIX SCRIPT:';
    PRINT 'UPDATE Departments SET DepartmentCode = ''CSEDS'' WHERE DepartmentCode IN (''CSE(DS)'', ''CSE-DS'', ''CSE (DS)'', ''CSE_DS'', ''CSDS'');';
    PRINT 'UPDATE Admins SET Department = ''CSEDS'' WHERE Department IN (''CSE(DS)'', ''CSE-DS'', ''CSE (DS)'', ''CSE_DS'', ''CSDS'');';
    PRINT 'UPDATE Students SET Department = ''CSEDS'' WHERE Department IN (''CSE(DS)'', ''CSE-DS'', ''CSE (DS)'', ''CSE_DS'', ''CSDS'');';
    PRINT 'UPDATE Faculties SET Department = ''CSEDS'' WHERE Department IN (''CSE(DS)'', ''CSE-DS'', ''CSE (DS)'', ''CSE_DS'', ''CSDS'');';
    PRINT 'UPDATE Subjects SET Department = ''CSEDS'' WHERE Department IN (''CSE(DS)'', ''CSE-DS'', ''CSE (DS)'', ''CSE_DS'', ''CSDS'');';
END
ELSE
BEGIN
    PRINT '? ALL DEPARTMENT CODES ARE PROPERLY NORMALIZED TO CSEDS!';
    PRINT '? No action needed.';
END

PRINT '';
PRINT '========================================';
PRINT 'VERIFICATION COMPLETE';
PRINT '========================================';
