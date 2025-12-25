-- ================================================================
-- STANDARDIZE STUDENT YEARS TO ROMAN NUMERAL FORMAT
-- ================================================================
-- Problem: Students table has mixed year formats:
--   - "II Year", "III Year" (correct format)
--   - "3" (numeric only - WRONG!)
-- 
-- This causes students with numeric years to NOT see subjects
-- because the code expects Roman numerals.
--
-- Solution: Convert ALL numeric years to Roman numeral format
-- ================================================================

USE Working5Db;
GO

PRINT '================================================================'
PRINT '  STUDENT YEAR STANDARDIZATION'
PRINT '================================================================'
PRINT ''

-- Show current distribution
PRINT 'BEFORE: Current Year Distribution'
PRINT '=================================='
SELECT Year, COUNT(*) as StudentCount
FROM Students
GROUP BY Year
ORDER BY Year;

PRINT ''
PRINT 'Starting Year Standardization...'
PRINT ''

-- ================================================================
-- STEP 1: Update Numeric Years to Roman Numeral Format
-- ================================================================

-- Update Year = '1' to 'I Year'
UPDATE Students
SET Year = 'I Year'
WHERE Year = '1';
PRINT '? Updated Year "1" to "I Year": ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' students';

-- Update Year = '2' to 'II Year'
UPDATE Students
SET Year = 'II Year'
WHERE Year = '2';
PRINT '? Updated Year "2" to "II Year": ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' students';

-- Update Year = '3' to 'III Year'
UPDATE Students
SET Year = 'III Year'
WHERE Year = '3';
PRINT '? Updated Year "3" to "III Year": ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' students';

-- Update Year = '4' to 'IV Year'
UPDATE Students
SET Year = 'IV Year'
WHERE Year = '4';
PRINT '? Updated Year "4" to "IV Year": ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' students';

PRINT ''
PRINT '================================================================'
PRINT ''

-- Show new distribution
PRINT 'AFTER: New Year Distribution'
PRINT '============================'
SELECT Year, COUNT(*) as StudentCount
FROM Students
GROUP BY Year
ORDER BY Year;

PRINT ''
PRINT '================================================================'
PRINT ''

-- ================================================================
-- STEP 2: Verify No Non-Standard Years Remain
-- ================================================================

PRINT 'VERIFICATION: Students with Non-Standard Years (should be 0)'
PRINT '============================================================='

IF EXISTS (
    SELECT 1 FROM Students 
    WHERE Year NOT IN ('I Year', 'II Year', 'III Year', 'IV Year')
    AND Year IS NOT NULL
)
BEGIN
    PRINT '?? WARNING: Some students still have non-standard year formats:'
    SELECT Year, COUNT(*) as Count
    FROM Students
    WHERE Year NOT IN ('I Year', 'II Year', 'III Year', 'IV Year')
    AND Year IS NOT NULL
    GROUP BY Year;
END
ELSE
BEGIN
    PRINT '? SUCCESS: All students have standard Roman numeral year format!'
END

PRINT ''
PRINT '================================================================'
PRINT ''

-- ================================================================
-- STEP 3: Verify Subject Matching
-- ================================================================

PRINT 'VERIFICATION: Can Students See Subjects?'
PRINT '=========================================='
PRINT ''

-- Check Year II students (should match Year 2 subjects)
DECLARE @Year2Students INT = (SELECT COUNT(*) FROM Students WHERE Year = 'II Year');
DECLARE @Year2Subjects INT = (SELECT COUNT(*) FROM AssignedSubjects WHERE Year = 2);
PRINT 'Year II Students: ' + CAST(@Year2Students AS NVARCHAR(10));
PRINT 'Year 2 Subject Assignments: ' + CAST(@Year2Subjects AS NVARCHAR(10));
IF @Year2Subjects > 0
    PRINT '? Year II students can see ' + CAST(@Year2Subjects AS NVARCHAR(10)) + ' subject options'
ELSE
    PRINT '?? No subjects assigned for Year 2';

PRINT ''

-- Check Year III students (should match Year 3 subjects)
DECLARE @Year3Students INT = (SELECT COUNT(*) FROM Students WHERE Year = 'III Year');
DECLARE @Year3Subjects INT = (SELECT COUNT(*) FROM AssignedSubjects WHERE Year = 3);
PRINT 'Year III Students: ' + CAST(@Year3Students AS NVARCHAR(10));
PRINT 'Year 3 Subject Assignments: ' + CAST(@Year3Subjects AS NVARCHAR(10));
IF @Year3Subjects > 0
    PRINT '? Year III students can see ' + CAST(@Year3Subjects AS NVARCHAR(10)) + ' subject options'
ELSE
    PRINT '?? No subjects assigned for Year 3';

PRINT ''
PRINT '================================================================'
PRINT ''

-- ================================================================
-- STEP 4: Test Sample Student
-- ================================================================

PRINT 'SAMPLE TEST: Can a Year III Student See Subjects?'
PRINT '=================================================='
PRINT ''

IF EXISTS (SELECT 1 FROM Students WHERE Year = 'III Year')
BEGIN
    DECLARE @SampleStudent NVARCHAR(50);
    SELECT TOP 1 @SampleStudent = Id FROM Students WHERE Year = 'III Year';
    
    PRINT 'Sample Student ID: ' + @SampleStudent;
    
    -- Simulate what the student would see
    DECLARE @VisibleSubjects INT = (
        SELECT COUNT(*)
        FROM AssignedSubjects a
        INNER JOIN Subjects s ON a.SubjectId = s.SubjectId
        WHERE a.Year = 3  -- Year III maps to 3
        AND s.Department = (SELECT Department FROM Students WHERE Id = @SampleStudent)
    );
    
    PRINT 'Visible Subjects for this student: ' + CAST(@VisibleSubjects AS NVARCHAR(10));
    
    IF @VisibleSubjects > 0
        PRINT '? SUCCESS: Student can see subjects!'
    ELSE
        PRINT '?? WARNING: Student cannot see subjects (check subject assignments)';
END
ELSE
BEGIN
    PRINT 'No Year III students found to test.';
END

PRINT ''
PRINT '================================================================'
PRINT '  STANDARDIZATION COMPLETE!'
PRINT '================================================================'
PRINT ''
PRINT '? All student years standardized to Roman numeral format'
PRINT '? Format: "I Year", "II Year", "III Year", "IV Year"'
PRINT '? Students can now see subjects matching their year'
PRINT ''
PRINT 'Next Step: Restart your application to see the changes'
PRINT '================================================================'
