-- ========================================
-- REAL-TIME EDIT DEPARTMENT TEST
-- ========================================
-- Run this BEFORE and AFTER editing department to see the difference

PRINT '========================================';
PRINT 'SNAPSHOT: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- What's in Departments table?
PRINT '1. DEPARTMENT TABLE (ID=1):';
SELECT 
    DepartmentId,
    DepartmentName,
    DepartmentCode AS [Stored_DeptCode],
    CASE 
        WHEN DepartmentCode = 'CSEDS' THEN 'CSEDS (Correct)'
        WHEN DepartmentCode = 'CSE(DS)' THEN 'CSE(DS) (Wrong - should be CSEDS)'
        ELSE DepartmentCode
    END AS [DeptCode_Status],
    HeadOfDepartment,
    HeadOfDepartmentEmail,
    LastModifiedDate
FROM Departments
WHERE DepartmentId = 1;
PRINT '';

-- What codes exist in Students?
PRINT '2. STUDENT DEPARTMENT CODES:';
SELECT 
    Department AS [Student_DeptCode],
    COUNT(*) AS StudentCount,
    CASE 
        WHEN Department = 'CSEDS' THEN '? Matches if Dept=CSEDS'
        WHEN Department = 'CSE(DS)' THEN '? Matches if Dept=CSE(DS)'
        ELSE '? Other'
    END AS Status
FROM Students
WHERE Department LIKE '%CSE%DS%' OR Department = 'CSEDS'
GROUP BY Department;
PRINT '';

-- What codes exist in Faculties?
PRINT '3. FACULTY DEPARTMENT CODES:';
SELECT 
    Department AS [Faculty_DeptCode],
    COUNT(*) AS FacultyCount,
    CASE 
        WHEN Department = 'CSEDS' THEN '? Matches if Dept=CSEDS'
        WHEN Department = 'CSE(DS)' THEN '? Matches if Dept=CSE(DS)'
        ELSE '? Other'
    END AS Status
FROM Faculties
WHERE Department LIKE '%CSE%DS%' OR Department = 'CSEDS'
GROUP BY Department;
PRINT '';

-- What codes exist in Subjects?
PRINT '4. SUBJECT DEPARTMENT CODES:';
SELECT 
    Department AS [Subject_DeptCode],
    COUNT(*) AS SubjectCount,
    CASE 
        WHEN Department = 'CSEDS' THEN '? Matches if Dept=CSEDS'
        WHEN Department = 'CSE(DS)' THEN '? Matches if Dept=CSE(DS)'
        ELSE '? Other'
    END AS Status
FROM Subjects
WHERE Department LIKE '%CSE%DS%' OR Department = 'CSEDS'
GROUP BY Department;
PRINT '';

-- Simulate what GetAllDepartmentsDetailed would show
PRINT '5. WHAT GetAllDepartmentsDetailed() WILL SHOW:';
DECLARE @DeptCode NVARCHAR(50);
DECLARE @NormalizedCode NVARCHAR(50);

SELECT @DeptCode = DepartmentCode FROM Departments WHERE DepartmentId = 1;

-- Simulate normalization (same logic as DepartmentNormalizer.Normalize)
SET @NormalizedCode = CASE 
    WHEN @DeptCode IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS', 'CSEDS') THEN 'CSEDS'
    ELSE @DeptCode
END;

PRINT 'Department.DepartmentCode = ' + @DeptCode;
PRINT 'Normalized for queries = ' + @NormalizedCode;
PRINT '';

SELECT 
    'Statistics' AS Section,
    @DeptCode AS [Raw_DeptCode_From_DB],
    @NormalizedCode AS [Normalized_For_Query],
    (SELECT COUNT(*) FROM Students WHERE Department = @NormalizedCode) AS TotalStudents,
    (SELECT COUNT(*) FROM Faculties WHERE Department = @NormalizedCode) AS TotalFaculty,
    (SELECT COUNT(*) FROM Subjects WHERE Department = @NormalizedCode) AS TotalSubjects;
PRINT '';

-- Check for mismatches
PRINT '6. MISMATCH DETECTION:';
IF @DeptCode != @NormalizedCode
BEGIN
    PRINT '??  WARNING: Department code will be normalized during queries!';
    PRINT '   Stored as: ' + @DeptCode;
    PRINT '   Queried as: ' + @NormalizedCode;
    PRINT '';
    
    -- Check if data exists under the normalized code
    DECLARE @StudentCountNormalized INT, @StudentCountRaw INT;
    SELECT @StudentCountNormalized = COUNT(*) FROM Students WHERE Department = @NormalizedCode;
    SELECT @StudentCountRaw = COUNT(*) FROM Students WHERE Department = @DeptCode;
    
    IF @StudentCountNormalized > 0 AND @StudentCountRaw = 0
    BEGIN
        PRINT '? Data exists under normalized code (' + @NormalizedCode + ')';
        PRINT '   Statistics should show correctly: ' + CAST(@StudentCountNormalized AS VARCHAR) + ' students';
    END
    ELSE IF @StudentCountRaw > 0 AND @StudentCountNormalized = 0
    BEGIN
        PRINT '? ERROR: Data exists under raw code (' + @DeptCode + ') but not normalized code!';
        PRINT '   Statistics will show ZERO!';
        PRINT '   FIX: Normalize student data to ' + @NormalizedCode;
    END
    ELSE IF @StudentCountNormalized = 0 AND @StudentCountRaw = 0
    BEGIN
        PRINT '??  No students found under either code';
    END
    ELSE
    BEGIN
        PRINT '? SPLIT DATA: Some students under ' + @DeptCode + ', some under ' + @NormalizedCode;
        PRINT '   This will cause inconsistent statistics!';
    END
END
ELSE
BEGIN
    PRINT '? No normalization needed - codes match';
END

PRINT '';
PRINT '========================================';
PRINT 'END SNAPSHOT';
PRINT '========================================';
