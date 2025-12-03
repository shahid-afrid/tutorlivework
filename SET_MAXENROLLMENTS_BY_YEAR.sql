-- SET CORRECT MaxEnrollments FOR ALL YEARS
-- Run this AFTER the migration has been applied

PRINT '========================================';
PRINT 'SETTING ENROLLMENT LIMITS BY YEAR';
PRINT '========================================';
PRINT '';

-- Check if MaxEnrollments column exists
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Subjects' 
    AND COLUMN_NAME = 'MaxEnrollments'
)
BEGIN
    PRINT '? ERROR: MaxEnrollments column does not exist!';
    PRINT '   You MUST run the migration first:';
    PRINT '   dotnet ef database update';
    PRINT '';
    RETURN;
END

PRINT '? MaxEnrollments column exists!';
PRINT '';

-- Set Year 2 Core subjects to 60-student limit
PRINT 'Setting Year 2 Core subjects to 60-student limit...';
UPDATE Subjects
SET MaxEnrollments = 60
WHERE Year = 2 
  AND SubjectType = 'Core';
PRINT CONCAT('? Updated ', @@ROWCOUNT, ' Year 2 subjects');
PRINT '';

-- Set Year 3 and Year 4 Core subjects to 70-student limit
PRINT 'Setting Year 3 Core subjects to 70-student limit...';
UPDATE Subjects
SET MaxEnrollments = 70
WHERE Year = 3 
  AND SubjectType = 'Core';
PRINT CONCAT('? Updated ', @@ROWCOUNT, ' Year 3 subjects');
PRINT '';

PRINT 'Setting Year 4 Core subjects to 70-student limit...';
UPDATE Subjects
SET MaxEnrollments = 70
WHERE Year = 4 
  AND SubjectType = 'Core';
PRINT CONCAT('? Updated ', @@ROWCOUNT, ' Year 4 subjects');
PRINT '';

-- Set default limits for Professional Electives (if any exist)
PRINT 'Setting Professional Electives to 70-student limit...';
UPDATE Subjects
SET MaxEnrollments = 70
WHERE SubjectType LIKE 'ProfessionalElective%'
  AND MaxEnrollments IS NULL;
PRINT CONCAT('? Updated ', @@ROWCOUNT, ' Professional Elective subjects');
PRINT '';

PRINT '========================================';
PRINT 'VERIFICATION - CURRENT LIMITS';
PRINT '========================================';
PRINT '';

-- Show all subjects with their limits
SELECT 
    Year,
    SubjectType,
    Name AS SubjectName,
    MaxEnrollments AS Limit,
    CASE 
        WHEN Year = 2 AND SubjectType = 'Core' AND MaxEnrollments = 60 THEN '? Correct'
        WHEN Year IN (3, 4) AND SubjectType = 'Core' AND MaxEnrollments = 70 THEN '? Correct'
        WHEN SubjectType LIKE 'ProfessionalElective%' AND MaxEnrollments = 70 THEN '? Correct'
        WHEN MaxEnrollments IS NULL THEN '??  No Limit Set'
        ELSE '? Wrong Limit'
    END AS Status
FROM 
    Subjects
WHERE 
    SubjectType IN ('Core', 'ProfessionalElective1', 'ProfessionalElective2', 'ProfessionalElective3')
ORDER BY 
    Year, SubjectType, Name;

PRINT '';
PRINT '========================================';
PRINT 'CURRENT ENROLLMENT COUNTS';
PRINT '========================================';
PRINT '';

-- Show enrollment counts for each subject
SELECT 
    s.Year,
    s.Name AS SubjectName,
    s.MaxEnrollments AS Limit,
    COUNT(DISTINCT se.StudentId) AS CurrentEnrollments,
    s.MaxEnrollments - COUNT(DISTINCT se.StudentId) AS SpotsLeft,
    CASE 
        WHEN COUNT(DISTINCT se.StudentId) > ISNULL(s.MaxEnrollments, 9999) THEN '? OVER LIMIT!'
        WHEN COUNT(DISTINCT se.StudentId) = s.MaxEnrollments THEN '??  FULL'
        ELSE '? Available'
    END AS Status
FROM 
    Subjects s
    LEFT JOIN AssignedSubjects asub ON s.SubjectId = asub.SubjectId
    LEFT JOIN StudentEnrollments se ON asub.AssignedSubjectId = se.AssignedSubjectId
WHERE 
    s.SubjectType = 'Core'
GROUP BY 
    s.SubjectId, s.Year, s.Name, s.MaxEnrollments
ORDER BY 
    s.Year, s.Name;

PRINT '';
PRINT '========================================';
PRINT 'DONE!';
PRINT '========================================';
