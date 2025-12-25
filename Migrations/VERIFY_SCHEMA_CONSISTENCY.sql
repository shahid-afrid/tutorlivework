-- VERIFY SCHEMA CONSISTENCY ACROSS ALL DEPARTMENTS
-- =====================================================
-- This script verifies that all department tables have
-- the EXACT SAME schema as CSEDS (the standard)
-- =====================================================

USE [Working5Db];
GO

SET NOCOUNT ON;

PRINT '========================================';
PRINT 'SCHEMA CONSISTENCY VERIFICATION';
PRINT 'Started at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- =====================================================
-- 1. CHECK FACULTY TABLES SCHEMA
-- =====================================================
PRINT '=== 1. FACULTY TABLES SCHEMA ===';
PRINT '';
PRINT 'Expected columns: FacultyId, Name, Email, Password, Department';
PRINT '';

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Faculty_CSEDS', 'Faculty_DES', 'Faculty_IT', 'Faculty_ECE', 'Faculty_MECH')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- =====================================================
-- 2. CHECK STUDENTS TABLES SCHEMA
-- =====================================================
PRINT '';
PRINT '=== 2. STUDENTS TABLES SCHEMA ===';
PRINT '';
PRINT 'Expected columns: Id, FullName, RegdNumber, Year, Department, Semester, Email, Password, SelectedSubject';
PRINT '';

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Students_CSEDS', 'Students_DES', 'Students_IT', 'Students_ECE', 'Students_MECH')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- =====================================================
-- 3. CHECK SUBJECTS TABLES SCHEMA
-- =====================================================
PRINT '';
PRINT '=== 3. SUBJECTS TABLES SCHEMA ===';
PRINT '';
PRINT 'Expected columns: SubjectId, Name, Department, Year, Semester, SemesterStartDate, SemesterEndDate, SubjectType, MaxEnrollments';
PRINT '';

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('Subjects_CSEDS', 'Subjects_DES', 'Subjects_IT', 'Subjects_ECE', 'Subjects_MECH')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- =====================================================
-- 4. CHECK ASSIGNEDSUBJECTS TABLES SCHEMA
-- =====================================================
PRINT '';
PRINT '=== 4. ASSIGNEDSUBJECTS TABLES SCHEMA ===';
PRINT '';
PRINT 'Expected columns: AssignedSubjectId, FacultyId, SubjectId, Department, Year, SelectedCount';
PRINT '';

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('AssignedSubjects_CSEDS', 'AssignedSubjects_DES', 'AssignedSubjects_IT', 'AssignedSubjects_ECE', 'AssignedSubjects_MECH')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- =====================================================
-- 5. CHECK STUDENTENROLLMENTS TABLES SCHEMA
-- =====================================================
PRINT '';
PRINT '=== 5. STUDENTENROLLMENTS TABLES SCHEMA ===';
PRINT '';
PRINT 'Expected columns: StudentId, AssignedSubjectId, EnrolledAt';
PRINT '';

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('StudentEnrollments_CSEDS', 'StudentEnrollments_DES', 'StudentEnrollments_IT', 'StudentEnrollments_ECE', 'StudentEnrollments_MECH')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- =====================================================
-- 6. SCHEMA COMPARISON - Detect Differences
-- =====================================================
PRINT '';
PRINT '=== 6. SCHEMA DIFFERENCES DETECTION ===';
PRINT '';
PRINT 'Checking if all departments have IDENTICAL schemas...';
PRINT '';

-- Compare Faculty tables
WITH FacultySchema AS (
    SELECT 
        TABLE_NAME,
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE,
        ORDINAL_POSITION
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME IN ('Faculty_CSEDS', 'Faculty_DES', 'Faculty_IT', 'Faculty_ECE', 'Faculty_MECH')
)
SELECT 
    'Faculty Tables' AS TableType,
    CASE 
        WHEN COUNT(DISTINCT COLUMN_NAME + DATA_TYPE + ISNULL(CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR), '')) = 
             (SELECT COUNT(*) FROM FacultySchema WHERE TABLE_NAME = 'Faculty_CSEDS')
        THEN '? ALL SCHEMAS MATCH'
        ELSE '? SCHEMAS DIFFER'
    END AS Status
FROM FacultySchema;

-- Compare Students tables
WITH StudentsSchema AS (
    SELECT 
        TABLE_NAME,
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE,
        ORDINAL_POSITION
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME IN ('Students_CSEDS', 'Students_DES', 'Students_IT', 'Students_ECE', 'Students_MECH')
)
SELECT 
    'Students Tables' AS TableType,
    CASE 
        WHEN COUNT(DISTINCT COLUMN_NAME + DATA_TYPE + ISNULL(CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR), '')) = 
             (SELECT COUNT(*) FROM StudentsSchema WHERE TABLE_NAME = 'Students_CSEDS')
        THEN '? ALL SCHEMAS MATCH'
        ELSE '? SCHEMAS DIFFER'
    END AS Status
FROM StudentsSchema;

-- Compare Subjects tables
WITH SubjectsSchema AS (
    SELECT 
        TABLE_NAME,
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE,
        ORDINAL_POSITION
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME IN ('Subjects_CSEDS', 'Subjects_DES', 'Subjects_IT', 'Subjects_ECE', 'Subjects_MECH')
)
SELECT 
    'Subjects Tables' AS TableType,
    CASE 
        WHEN COUNT(DISTINCT COLUMN_NAME + DATA_TYPE + ISNULL(CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR), '')) = 
             (SELECT COUNT(*) FROM SubjectsSchema WHERE TABLE_NAME = 'Subjects_CSEDS')
        THEN '? ALL SCHEMAS MATCH'
        ELSE '? SCHEMAS DIFFER'
    END AS Status
FROM SubjectsSchema;

-- Compare AssignedSubjects tables
WITH AssignedSubjectsSchema AS (
    SELECT 
        TABLE_NAME,
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE,
        ORDINAL_POSITION
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME IN ('AssignedSubjects_CSEDS', 'AssignedSubjects_DES', 'AssignedSubjects_IT', 'AssignedSubjects_ECE', 'AssignedSubjects_MECH')
)
SELECT 
    'AssignedSubjects Tables' AS TableType,
    CASE 
        WHEN COUNT(DISTINCT COLUMN_NAME + DATA_TYPE + ISNULL(CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR), '')) = 
             (SELECT COUNT(*) FROM AssignedSubjectsSchema WHERE TABLE_NAME = 'AssignedSubjects_CSEDS')
        THEN '? ALL SCHEMAS MATCH'
        ELSE '? SCHEMAS DIFFER'
    END AS Status
FROM AssignedSubjectsSchema;

-- Compare StudentEnrollments tables
WITH StudentEnrollmentsSchema AS (
    SELECT 
        TABLE_NAME,
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE,
        ORDINAL_POSITION
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME IN ('StudentEnrollments_CSEDS', 'StudentEnrollments_DES', 'StudentEnrollments_IT', 'StudentEnrollments_ECE', 'StudentEnrollments_MECH')
)
SELECT 
    'StudentEnrollments Tables' AS TableType,
    CASE 
        WHEN COUNT(DISTINCT COLUMN_NAME + DATA_TYPE + ISNULL(CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR), '')) = 
             (SELECT COUNT(*) FROM StudentEnrollmentsSchema WHERE TABLE_NAME = 'StudentEnrollments_CSEDS')
        THEN '? ALL SCHEMAS MATCH'
        ELSE '? SCHEMAS DIFFER'
    END AS Status
FROM StudentEnrollmentsSchema;

-- =====================================================
-- 7. CHECK FOREIGN KEY CONSTRAINTS
-- =====================================================
PRINT '';
PRINT '=== 7. FOREIGN KEY CONSTRAINTS ===';
PRINT '';

SELECT 
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) LIKE '%_CSEDS' 
   OR OBJECT_NAME(fk.parent_object_id) LIKE '%_DES'
   OR OBJECT_NAME(fk.parent_object_id) LIKE '%_IT'
   OR OBJECT_NAME(fk.parent_object_id) LIKE '%_ECE'
   OR OBJECT_NAME(fk.parent_object_id) LIKE '%_MECH'
ORDER BY TableName, ForeignKeyName;

-- =====================================================
-- 8. CHECK INDEXES
-- =====================================================
PRINT '';
PRINT '=== 8. INDEXES ===';
PRINT '';

SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE OBJECT_NAME(i.object_id) LIKE '%_CSEDS' 
   OR OBJECT_NAME(i.object_id) LIKE '%_DES'
   OR OBJECT_NAME(i.object_id) LIKE '%_IT'
   OR OBJECT_NAME(i.object_id) LIKE '%_ECE'
   OR OBJECT_NAME(i.object_id) LIKE '%_MECH'
ORDER BY TableName, IndexName, ic.key_ordinal;

-- =====================================================
-- 9. TABLE COUNT SUMMARY
-- =====================================================
PRINT '';
PRINT '=== 9. TABLE COUNT SUMMARY ===';
PRINT '';
PRINT 'Each department should have exactly 5 tables:';
PRINT '  - Faculty_{DEPT}';
PRINT '  - Students_{DEPT}';
PRINT '  - Subjects_{DEPT}';
PRINT '  - AssignedSubjects_{DEPT}';
PRINT '  - StudentEnrollments_{DEPT}';
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
WHERE TABLE_NAME LIKE 'Faculty_%' 
   OR TABLE_NAME LIKE 'Students_%'
   OR TABLE_NAME LIKE 'Subjects_%'
   OR TABLE_NAME LIKE 'AssignedSubjects_%'
   OR TABLE_NAME LIKE 'StudentEnrollments_%'
GROUP BY 
    CASE 
        WHEN TABLE_NAME LIKE '%_CSEDS' THEN 'CSEDS'
        WHEN TABLE_NAME LIKE '%_DES' THEN 'DES'
        WHEN TABLE_NAME LIKE '%_IT' THEN 'IT'
        WHEN TABLE_NAME LIKE '%_ECE' THEN 'ECE'
        WHEN TABLE_NAME LIKE '%_MECH' THEN 'MECH'
    END
ORDER BY Department;

PRINT '';
PRINT '========================================';
PRINT 'VERIFICATION COMPLETE';
PRINT 'Completed at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
GO
