-- Check why new Year 2 subject is not showing up
-- Run this in SQL Server Management Studio

-- 1. Check if the new subject exists in Subjects table
SELECT 
    s.Id,
    s.Name,
    s.Department,
    s.SubjectType,
    s.MaxEnrollments,
    'Subject exists' as Status
FROM Subjects s
WHERE s.Department LIKE '%CSE%DS%'
    OR s.Department = 'CSEDS'
    OR s.Department = 'CSE DS'
    OR s.Department = 'CsEDs'
ORDER BY s.Id DESC;

-- 2. Check if it's assigned to faculty (AssignedSubjects)
SELECT 
    asub.Id,
    asub.SubjectId,
    s.Name AS SubjectName,
    asub.Year,
    asub.Department,
    f.FullName AS FacultyName,
    asub.SelectedCount,
    s.MaxEnrollments,
    CASE 
        WHEN asub.SelectedCount >= ISNULL(s.MaxEnrollments, 70) THEN 'FULL - This is why it is hidden'
        ELSE 'Available'
    END AS AvailabilityStatus
FROM AssignedSubjects asub
INNER JOIN Subjects s ON asub.SubjectId = s.Id
LEFT JOIN Faculties f ON asub.FacultyId = f.Id
WHERE asub.Year = 2
    AND (asub.Department LIKE '%CSE%DS%' 
        OR asub.Department = 'CSEDS'
        OR asub.Department = 'CSE DS'
        OR asub.Department = 'CsEDs')
ORDER BY asub.Id DESC;

-- 3. Check the exact issue with the newest subject
SELECT TOP 1
    asub.Id,
    s.Name,
    s.SubjectType,
    asub.SelectedCount,
    s.MaxEnrollments,
    CASE 
        WHEN asub.SelectedCount >= ISNULL(s.MaxEnrollments, 70) THEN 'HIDDEN: Subject is full (' + CAST(asub.SelectedCount AS VARCHAR) + ' >= ' + CAST(ISNULL(s.MaxEnrollments, 70) AS VARCHAR) + ')'
        WHEN s.MaxEnrollments IS NULL THEN 'ERROR: MaxEnrollments is NULL - should be 60 for Year 2'
        WHEN s.MaxEnrollments != 60 THEN 'ERROR: MaxEnrollments is ' + CAST(s.MaxEnrollments AS VARCHAR) + ' - should be 60 for Year 2'
        ELSE 'OK: Subject should be visible'
    END AS DiagnosisResult
FROM AssignedSubjects asub
INNER JOIN Subjects s ON asub.SubjectId = s.Id
WHERE asub.Year = 2
    AND (asub.Department LIKE '%CSE%DS%' 
        OR asub.Department = 'CSEDS'
        OR asub.Department = 'CSE DS'
        OR asub.Department = 'CsEDs')
ORDER BY asub.Id DESC;

-- 4. FIX: Set MaxEnrollments to 60 for all Year 2 subjects that don't have it
UPDATE s
SET s.MaxEnrollments = 60
FROM Subjects s
INNER JOIN AssignedSubjects asub ON s.Id = asub.SubjectId
WHERE asub.Year = 2
    AND (s.MaxEnrollments IS NULL OR s.MaxEnrollments != 60);

-- 5. Verify the fix worked
SELECT 
    'After Fix' AS CheckPoint,
    COUNT(*) AS Year2SubjectsWithCorrectLimit
FROM Subjects s
INNER JOIN AssignedSubjects asub ON s.Id = asub.SubjectId
WHERE asub.Year = 2
    AND s.MaxEnrollments = 60;
