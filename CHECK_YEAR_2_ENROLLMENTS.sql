-- CHECK YEAR 2 ENROLLMENT STATUS
-- This script shows if Year 2 subjects are exceeding their 60-student limit

PRINT '========================================';
PRINT 'YEAR 2 SUBJECTS - ENROLLMENT CHECK';
PRINT '========================================';
PRINT '';

-- Show Year 2 subjects and their enrollment counts
SELECT 
    s.SubjectId,
    s.Name AS SubjectName,
    s.Year,
    s.SubjectType,
    s.MaxEnrollments AS DatabaseLimit,
    COUNT(DISTINCT se.StudentId) AS ActualEnrollments,
    CASE 
        WHEN COUNT(DISTINCT se.StudentId) > ISNULL(s.MaxEnrollments, 70) THEN '? OVER LIMIT!'
        WHEN COUNT(DISTINCT se.StudentId) = ISNULL(s.MaxEnrollments, 70) THEN '?? AT LIMIT'
        ELSE '? OK'
    END AS Status,
    ISNULL(s.MaxEnrollments, 70) - COUNT(DISTINCT se.StudentId) AS SpotsRemaining
FROM 
    Subjects s
LEFT JOIN 
    AssignedSubjects asub ON s.SubjectId = asub.SubjectId
LEFT JOIN 
    StudentEnrollments se ON asub.AssignedSubjectId = se.AssignedSubjectId
WHERE 
    s.Year = 2
    AND s.SubjectType = 'Core'
GROUP BY 
    s.SubjectId,
    s.Name,
    s.Year,
    s.SubjectType,
    s.MaxEnrollments
ORDER BY 
    ActualEnrollments DESC;

PRINT '';
PRINT '========================================';
PRINT 'DETAILED BREAKDOWN BY FACULTY';
PRINT '========================================';
PRINT '';

-- Show each faculty assignment and its enrollment count
SELECT 
    s.SubjectId,
    s.Name AS SubjectName,
    s.MaxEnrollments AS SubjectLimit,
    f.FacultyId,
    f.Name AS FacultyName,
    asub.AssignedSubjectId,
    asub.SelectedCount AS CachedCount,
    COUNT(se.StudentId) AS ActualEnrollments,
    CASE 
        WHEN COUNT(se.StudentId) != asub.SelectedCount THEN '?? COUNT MISMATCH!'
        ELSE '? Counts Match'
    END AS CountStatus
FROM 
    Subjects s
INNER JOIN 
    AssignedSubjects asub ON s.SubjectId = asub.SubjectId
INNER JOIN 
    Faculty f ON asub.FacultyId = f.FacultyId
LEFT JOIN 
    StudentEnrollments se ON asub.AssignedSubjectId = se.AssignedSubjectId
WHERE 
    s.Year = 2
    AND s.SubjectType = 'Core'
GROUP BY 
    s.SubjectId,
    s.Name,
    s.MaxEnrollments,
    f.FacultyId,
    f.Name,
    asub.AssignedSubjectId,
    asub.SelectedCount
ORDER BY 
    s.Name,
    f.Name;

PRINT '';
PRINT '========================================';
PRINT 'STUDENTS ENROLLED IN YEAR 2 SUBJECTS';
PRINT '========================================';
PRINT '';

-- List all students enrolled in Year 2 subjects
SELECT 
    s.SubjectId,
    s.Name AS SubjectName,
    s.MaxEnrollments,
    st.Id AS StudentId,
    st.FullName AS StudentName,
    st.Year AS StudentYear,
    f.Name AS FacultyName,
    se.EnrolledAt
FROM 
    Subjects s
INNER JOIN 
    AssignedSubjects asub ON s.SubjectId = asub.SubjectId
INNER JOIN 
    StudentEnrollments se ON asub.AssignedSubjectId = se.AssignedSubjectId
INNER JOIN 
    Students st ON se.StudentId = st.Id
INNER JOIN 
    Faculty f ON asub.FacultyId = f.FacultyId
WHERE 
    s.Year = 2
    AND s.SubjectType = 'Core'
ORDER BY 
    s.Name,
    se.EnrolledAt;

PRINT '';
PRINT '========================================';
PRINT 'ISSUE DETECTION';
PRINT '========================================';
PRINT '';

-- Detect if any Year 2 subjects have exceeded their limit
IF EXISTS (
    SELECT 1
    FROM Subjects s
    LEFT JOIN AssignedSubjects asub ON s.SubjectId = asub.SubjectId
    LEFT JOIN StudentEnrollments se ON asub.AssignedSubjectId = se.AssignedSubjectId
    WHERE s.Year = 2
      AND s.SubjectType = 'Core'
    GROUP BY s.SubjectId, s.MaxEnrollments
    HAVING COUNT(DISTINCT se.StudentId) > ISNULL(s.MaxEnrollments, 70)
)
BEGIN
    PRINT '? CRITICAL ISSUE DETECTED!';
    PRINT 'One or more Year 2 subjects have MORE students than their MaxEnrollments limit!';
    PRINT '';
    
    SELECT 
        s.SubjectId,
        s.Name,
        s.MaxEnrollments AS Limit,
        COUNT(DISTINCT se.StudentId) AS Enrolled,
        COUNT(DISTINCT se.StudentId) - ISNULL(s.MaxEnrollments, 70) AS Overbooked
    FROM 
        Subjects s
    LEFT JOIN 
        AssignedSubjects asub ON s.SubjectId = asub.SubjectId
    LEFT JOIN 
        StudentEnrollments se ON asub.AssignedSubjectId = se.AssignedSubjectId
    WHERE 
        s.Year = 2
        AND s.SubjectType = 'Core'
    GROUP BY 
        s.SubjectId,
        s.Name,
        s.MaxEnrollments
    HAVING 
        COUNT(DISTINCT se.StudentId) > ISNULL(s.MaxEnrollments, 70);
END
ELSE
BEGIN
    PRINT '? ALL GOOD!';
    PRINT 'All Year 2 subjects are within their enrollment limits.';
END
