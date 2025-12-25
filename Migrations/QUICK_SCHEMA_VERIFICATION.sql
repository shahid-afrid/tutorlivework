-- QUICK SCHEMA VERIFICATION SCRIPT
-- Run this anytime to verify all departments have CSEDS schema
-- =====================================================

USE [Working5Db];
GO

PRINT '========================================';
PRINT 'SCHEMA CONSISTENCY VERIFICATION';
PRINT 'Date: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- 1. Check table counts per department
PRINT '=== TABLE COUNT PER DEPARTMENT ===';
PRINT '';

SELECT 
    CASE 
        WHEN TABLE_NAME LIKE '%_CSEDS' THEN 'CSEDS'
        WHEN TABLE_NAME LIKE '%_DES' THEN 'DES'
        WHEN TABLE_NAME LIKE '%_IT' THEN 'IT'
        WHEN TABLE_NAME LIKE '%_ECE' THEN 'ECE'
        WHEN TABLE_NAME LIKE '%_MECH' THEN 'MECH'
    END AS Department,
    COUNT(*) AS TableCount,
    CASE 
        WHEN COUNT(*) = 5 THEN '? COMPLETE'
        ELSE '? INCOMPLETE'
    END AS Status
FROM INFORMATION_SCHEMA.TABLES
WHERE (TABLE_NAME LIKE 'Faculty_%' 
   OR TABLE_NAME LIKE 'Students_%'
   OR TABLE_NAME LIKE 'Subjects_%'
   OR TABLE_NAME LIKE 'AssignedSubjects_%'
   OR TABLE_NAME LIKE 'StudentEnrollments_%')
   AND TABLE_NAME NOT LIKE 'FacultySelectionSchedules' -- Exclude shared system table
GROUP BY 
    CASE 
        WHEN TABLE_NAME LIKE '%_CSEDS' THEN 'CSEDS'
        WHEN TABLE_NAME LIKE '%_DES' THEN 'DES'
        WHEN TABLE_NAME LIKE '%_IT' THEN 'IT'
        WHEN TABLE_NAME LIKE '%_ECE' THEN 'ECE'
        WHEN TABLE_NAME LIKE '%_MECH' THEN 'MECH'
    END
ORDER BY Department;

-- 2. Check Faculty table schema consistency
PRINT '';
PRINT '=== FACULTY TABLE SCHEMA ===';
PRINT 'Expected: 5 columns (FacultyId, Name, Email, Password, Department)';
PRINT '';

SELECT 
    TABLE_NAME,
    COUNT(*) AS ColumnCount,
    CASE 
        WHEN COUNT(*) = 5 THEN '? CORRECT'
        ELSE '? INCORRECT'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'Faculty_%'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- 3. Check Students table schema consistency
PRINT '';
PRINT '=== STUDENTS TABLE SCHEMA ===';
PRINT 'Expected: 9 columns (Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject)';
PRINT '';

SELECT 
    TABLE_NAME,
    COUNT(*) AS ColumnCount,
    CASE 
        WHEN COUNT(*) = 9 THEN '? CORRECT'
        ELSE '? INCORRECT'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'Students_%'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- 4. Check Subjects table schema consistency
PRINT '';
PRINT '=== SUBJECTS TABLE SCHEMA ===';
PRINT 'Expected: 9 columns (SubjectId, Name, Department, Year, Semester, SemesterStartDate, SemesterEndDate, SubjectType, MaxEnrollments)';
PRINT '';

SELECT 
    TABLE_NAME,
    COUNT(*) AS ColumnCount,
    CASE 
        WHEN COUNT(*) = 9 THEN '? CORRECT'
        ELSE '? INCORRECT'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'Subjects_%'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- 5. Check AssignedSubjects table schema consistency
PRINT '';
PRINT '=== ASSIGNEDSUBJECTS TABLE SCHEMA ===';
PRINT 'Expected: 6 columns (AssignedSubjectId, FacultyId, SubjectId, Department, Year, SelectedCount)';
PRINT '';

SELECT 
    TABLE_NAME,
    COUNT(*) AS ColumnCount,
    CASE 
        WHEN COUNT(*) = 6 THEN '? CORRECT'
        ELSE '? INCORRECT'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'AssignedSubjects_%'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- 6. Check StudentEnrollments table schema consistency
PRINT '';
PRINT '=== STUDENTENROLLMENTS TABLE SCHEMA ===';
PRINT 'Expected: 3 columns (StudentId, AssignedSubjectId, EnrolledAt)';
PRINT '';

SELECT 
    TABLE_NAME,
    COUNT(*) AS ColumnCount,
    CASE 
        WHEN COUNT(*) = 3 THEN '? CORRECT'
        ELSE '? INCORRECT'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'StudentEnrollments_%'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- 7. Verify specific column existence
PRINT '';
PRINT '=== CRITICAL COLUMNS VERIFICATION ===';
PRINT '';

-- Check if Password column exists (not PasswordHash)
SELECT 
    'Password Column Check' AS CheckType,
    COUNT(*) AS TablesWithPassword,
    CASE 
        WHEN COUNT(*) = 5 THEN '? ALL CORRECT'
        ELSE '? SOME MISSING'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'Faculty_%' 
  AND COLUMN_NAME = 'Password';

-- Check if Id column exists (not RollNumber)
SELECT 
    'Id Column Check (Students)' AS CheckType,
    COUNT(*) AS TablesWithId,
    CASE 
        WHEN COUNT(*) = 5 THEN '? ALL CORRECT'
        ELSE '? SOME MISSING'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'Students_%' 
  AND COLUMN_NAME = 'Id';

-- Check if SelectedCount column exists (not CurrentEnrollment)
SELECT 
    'SelectedCount Column Check' AS CheckType,
    COUNT(*) AS TablesWithSelectedCount,
    CASE 
        WHEN COUNT(*) = 5 THEN '? ALL CORRECT'
        ELSE '? SOME MISSING'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'AssignedSubjects_%' 
  AND COLUMN_NAME = 'SelectedCount';

-- Check if EnrolledAt column exists (not EnrollmentTime)
SELECT 
    'EnrolledAt Column Check' AS CheckType,
    COUNT(*) AS TablesWithEnrolledAt,
    CASE 
        WHEN COUNT(*) = 5 THEN '? ALL CORRECT'
        ELSE '? SOME MISSING'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'StudentEnrollments_%' 
  AND COLUMN_NAME = 'EnrolledAt';

-- 8. Overall Summary
PRINT '';
PRINT '========================================';
PRINT '=== OVERALL SUMMARY ===';
PRINT '========================================';
PRINT '';

DECLARE @TotalTables INT, @ExpectedTables INT;
SET @ExpectedTables = 25; -- 5 departments × 5 tables each

SELECT @TotalTables = COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE (TABLE_NAME LIKE 'Faculty_%' 
   OR TABLE_NAME LIKE 'Students_%'
   OR TABLE_NAME LIKE 'Subjects_%'
   OR TABLE_NAME LIKE 'AssignedSubjects_%'
   OR TABLE_NAME LIKE 'StudentEnrollments_%')
   AND TABLE_NAME NOT LIKE 'FacultySelectionSchedules'; -- Exclude shared system table

PRINT 'Total Department Tables: ' + CAST(@TotalTables AS VARCHAR);
PRINT 'Expected Tables: ' + CAST(@ExpectedTables AS VARCHAR);

IF @TotalTables = @ExpectedTables
    PRINT 'Status: ? ALL TABLES PRESENT';
ELSE
    PRINT 'Status: ? SOME TABLES MISSING';

PRINT '';
PRINT 'Note: FacultySelectionSchedules is a shared system table (excluded from count)';
PRINT '';
PRINT 'Verification completed at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
GO
