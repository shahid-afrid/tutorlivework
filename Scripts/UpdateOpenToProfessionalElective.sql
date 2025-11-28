-- ============================================
-- Script: Update Open Elective to Professional Elective
-- Purpose: Rename all "OpenElective" subject types to "ProfessionalElective"
-- ============================================

BEGIN TRANSACTION;

-- Update OpenElective1 to ProfessionalElective1
UPDATE Subjects
SET SubjectType = 'ProfessionalElective1'
WHERE SubjectType = 'OpenElective1';

-- Update OpenElective2 to ProfessionalElective2
UPDATE Subjects
SET SubjectType = 'ProfessionalElective2'
WHERE SubjectType = 'OpenElective2';

-- Update OpenElective3 to ProfessionalElective3
UPDATE Subjects
SET SubjectType = 'ProfessionalElective3'
WHERE SubjectType = 'OpenElective3';

-- Show updated records
SELECT 
    SubjectId,
    Name,
    Year,
    Semester,
    SubjectType,
    MaxEnrollments,
    Department
FROM Subjects
WHERE SubjectType LIKE 'Professional%'
ORDER BY SubjectType, Year, Name;

-- Show count of changes
SELECT 
    'Total subjects changed' AS Status,
    COUNT(*) AS Count
FROM Subjects
WHERE SubjectType LIKE 'Professional%';

-- If everything looks good, commit the transaction
COMMIT TRANSACTION;

-- If you need to rollback, use this instead:
-- ROLLBACK TRANSACTION;
