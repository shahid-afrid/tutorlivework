-- ============================================
-- Script: Set Max Enrollments for Core Subjects
-- Purpose: Update existing core subjects to have proper enrollment limits
--          - 2nd Year (Year 2): 60 students
--          - 3rd Year (Year 3): 70 students
--          - 4th Year (Year 4): 70 students
-- ============================================

-- Enable transaction for safety
BEGIN TRANSACTION;

-- Update 2nd Year Core Subjects to have MaxEnrollments = 60
UPDATE Subjects
SET MaxEnrollments = 60
WHERE SubjectType = 'Core' 
  AND Year = 2
  AND (MaxEnrollments IS NULL OR MaxEnrollments = 70); -- Only update if not already set correctly

-- Update 3rd Year Core Subjects to have MaxEnrollments = 70
UPDATE Subjects
SET MaxEnrollments = 70
WHERE SubjectType = 'Core' 
  AND Year = 3
  AND MaxEnrollments IS NULL; -- Only update if not set

-- Update 4th Year Core Subjects to have MaxEnrollments = 70
UPDATE Subjects
SET MaxEnrollments = 70
WHERE SubjectType = 'Core' 
  AND Year = 4
  AND MaxEnrollments IS NULL; -- Only update if not set

-- Show results
SELECT 
    SubjectId,
    Name,
    Year,
    SubjectType,
    MaxEnrollments,
    Department
FROM Subjects
WHERE SubjectType = 'Core'
ORDER BY Year, Name;

-- If everything looks good, commit the transaction
COMMIT TRANSACTION;

-- If you need to rollback, use this instead:
-- ROLLBACK TRANSACTION;
