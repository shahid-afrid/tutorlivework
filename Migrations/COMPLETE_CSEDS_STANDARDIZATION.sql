-- =====================================================
-- COMPLETE CSEDS STANDARDIZATION - FINAL FIX
-- =====================================================
-- This script standardizes ALL variations of CSE(DS) to "CSEDS"
-- Covers: CSE(DS), CSE (DS), CSDS, CSE-DS, CSE_DS, etc.
-- Applies to: ALL tables with Department columns
-- =====================================================

BEGIN TRANSACTION;

PRINT '========================================================';
PRINT 'COMPLETE CSEDS STANDARDIZATION - STARTING';
PRINT '========================================================';
PRINT '';

-- =====================================================
-- STEP 1: SHOW CURRENT STATE (BEFORE)
-- =====================================================
PRINT 'STEP 1: Current Department Variations (BEFORE):';
PRINT '------------------------------------------------';

SELECT 'Departments.DepartmentCode' AS [Column], DepartmentCode AS [Value], COUNT(*) AS [Count]
FROM Departments
WHERE DepartmentCode LIKE '%DS%' OR DepartmentCode LIKE '%CSED%'
GROUP BY DepartmentCode

UNION ALL

SELECT 'Departments.DepartmentName', DepartmentName, COUNT(*)
FROM Departments
WHERE DepartmentName LIKE '%Data Science%' OR DepartmentName LIKE '%DS%'
GROUP BY DepartmentName

UNION ALL

SELECT 'Students.Department', Department, COUNT(*)
FROM Students
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 'Faculties.Department', Department, COUNT(*)
FROM Faculties
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 'Subjects.Department', Department, COUNT(*)
FROM Subjects
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 'Admins.Department', Department, COUNT(*)
FROM Admins
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 'SubjectAssignments.Department', Department, COUNT(*)
FROM SubjectAssignments
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

ORDER BY [Column], [Value];

PRINT '';
PRINT '------------------------------------------------';
PRINT '';

-- =====================================================
-- STEP 2: UPDATE DEPARTMENTS TABLE
-- =====================================================
PRINT 'STEP 2: Updating Departments Table';
PRINT '-----------------------------------';

-- Update DepartmentCode
UPDATE Departments
SET DepartmentCode = 'CSEDS'
WHERE DepartmentCode IN (
    'CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS',
    'Cse(Ds)', 'cse(ds)', 'CSE DATA SCIENCE', 'CSEDATASCIENCE'
);

PRINT 'Departments.DepartmentCode updated: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- Update DepartmentName to standard display format
UPDATE Departments
SET DepartmentName = 'Computer Science and Engineering (Data Science)'
WHERE DepartmentCode = 'CSEDS' 
AND DepartmentName != 'Computer Science and Engineering (Data Science)';

PRINT 'Departments.DepartmentName updated: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- =====================================================
-- STEP 3: UPDATE STUDENTS TABLE
-- =====================================================
PRINT 'STEP 3: Updating Students Table';
PRINT '--------------------------------';

UPDATE Students
SET Department = 'CSEDS'
WHERE Department IN (
    'CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS',
    'Cse(Ds)', 'cse(ds)', 'CSE DATA SCIENCE', 'CSEDATASCIENCE'
);

PRINT 'Students.Department updated: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- =====================================================
-- STEP 4: UPDATE FACULTIES TABLE
-- =====================================================
PRINT 'STEP 4: Updating Faculties Table';
PRINT '---------------------------------';

UPDATE Faculties
SET Department = 'CSEDS'
WHERE Department IN (
    'CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS',
    'Cse(Ds)', 'cse(ds)', 'CSE DATA SCIENCE', 'CSEDATASCIENCE'
);

PRINT 'Faculties.Department updated: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- =====================================================
-- STEP 5: UPDATE SUBJECTS TABLE
-- =====================================================
PRINT 'STEP 5: Updating Subjects Table';
PRINT '--------------------------------';

UPDATE Subjects
SET Department = 'CSEDS'
WHERE Department IN (
    'CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS',
    'Cse(Ds)', 'cse(ds)', 'CSE DATA SCIENCE', 'CSEDATASCIENCE'
);

PRINT 'Subjects.Department updated: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- =====================================================
-- STEP 6: UPDATE ADMINS TABLE
-- =====================================================
PRINT 'STEP 6: Updating Admins Table';
PRINT '------------------------------';

UPDATE Admins
SET Department = 'CSEDS'
WHERE Department IN (
    'CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS',
    'Cse(Ds)', 'cse(ds)', 'CSE DATA SCIENCE', 'CSEDATASCIENCE'
);

PRINT 'Admins.Department updated: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- =====================================================
-- STEP 7: UPDATE SUBJECTASSIGNMENTS TABLE
-- =====================================================
PRINT 'STEP 7: Updating SubjectAssignments Table';
PRINT '------------------------------------------';

UPDATE SubjectAssignments
SET Department = 'CSEDS'
WHERE Department IN (
    'CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS',
    'Cse(Ds)', 'cse(ds)', 'CSE DATA SCIENCE', 'CSEDATASCIENCE'
);

PRINT 'SubjectAssignments.Department updated: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- =====================================================
-- STEP 8: VERIFY FINAL STATE (AFTER)
-- =====================================================
PRINT 'STEP 8: Final Department State (AFTER):';
PRINT '----------------------------------------';

SELECT 'Departments.DepartmentCode' AS [Column], DepartmentCode AS [Value], COUNT(*) AS [Count]
FROM Departments
WHERE DepartmentCode LIKE '%DS%' OR DepartmentCode LIKE '%CSED%'
GROUP BY DepartmentCode

UNION ALL

SELECT 'Departments.DepartmentName', DepartmentName, COUNT(*)
FROM Departments
WHERE DepartmentName LIKE '%Data Science%' OR DepartmentName LIKE '%DS%'
GROUP BY DepartmentName

UNION ALL

SELECT 'Students.Department', Department, COUNT(*)
FROM Students
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 'Faculties.Department', Department, COUNT(*)
FROM Faculties
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 'Subjects.Department', Department, COUNT(*)
FROM Subjects
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 'Admins.Department', Department, COUNT(*)
FROM Admins
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 'SubjectAssignments.Department', Department, COUNT(*)
FROM SubjectAssignments
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

ORDER BY [Column], [Value];

PRINT '';
PRINT '----------------------------------------';
PRINT '';

-- =====================================================
-- STEP 9: VERIFICATION CHECKS
-- =====================================================
PRINT 'STEP 9: Verification Checks';
PRINT '----------------------------';

-- Count any remaining variations (should be 0)
DECLARE @RemainingVariations INT;

SELECT @RemainingVariations = COUNT(*)
FROM (
    SELECT Department FROM Students WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS')
    UNION ALL
    SELECT Department FROM Faculties WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS')
    UNION ALL
    SELECT Department FROM Subjects WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS')
    UNION ALL
    SELECT Department FROM Admins WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS')
    UNION ALL
    SELECT Department FROM SubjectAssignments WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS')
    UNION ALL
    SELECT DepartmentCode FROM Departments WHERE DepartmentCode IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS')
) AS AllDepts;

IF @RemainingVariations = 0
BEGIN
    PRINT 'SUCCESS: All variations converted to CSEDS';
    PRINT 'No remaining CSE(DS) variations found';
END
ELSE
BEGIN
    PRINT 'WARNING: ' + CAST(@RemainingVariations AS VARCHAR) + ' variations still remain';
    PRINT 'Please review the data manually';
END

PRINT '';

-- Show final CSEDS counts
PRINT 'Final CSEDS Record Counts:';
PRINT '--------------------------';
SELECT 
    'Students' AS TableName, 
    COUNT(*) AS [CSEDS Records]
FROM Students WHERE Department = 'CSEDS'
UNION ALL
SELECT 'Faculties', COUNT(*) FROM Faculties WHERE Department = 'CSEDS'
UNION ALL
SELECT 'Subjects', COUNT(*) FROM Subjects WHERE Department = 'CSEDS'
UNION ALL
SELECT 'Admins', COUNT(*) FROM Admins WHERE Department = 'CSEDS'
UNION ALL
SELECT 'SubjectAssignments', COUNT(*) FROM SubjectAssignments WHERE Department = 'CSEDS'
UNION ALL
SELECT 'Departments', COUNT(*) FROM Departments WHERE DepartmentCode = 'CSEDS';

PRINT '';
PRINT '========================================================';
PRINT 'COMPLETE CSEDS STANDARDIZATION - FINISHED';
PRINT '========================================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Review the results above';
PRINT '2. If successful, commit the transaction';
PRINT '3. Update application code to use CSEDS consistently';
PRINT '4. Test the application thoroughly';
PRINT '';

-- COMMIT THE TRANSACTION
COMMIT TRANSACTION;
PRINT 'Transaction committed successfully!';
PRINT '';
