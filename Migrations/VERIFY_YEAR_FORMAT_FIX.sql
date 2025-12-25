-- VERIFY YEAR FORMAT FIX FOR CSEDS STUDENTS
-- This shows the actual year formats in the database and counts
-- =====================================================

USE [Working5Db];
GO

PRINT '========================================';
PRINT 'YEAR FORMAT VERIFICATION FOR CSEDS';
PRINT 'Date: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- Check all unique year formats in Students_CSEDS
PRINT '=== UNIQUE YEAR FORMATS IN DATABASE ===';
PRINT '';

SELECT 
    Year,
    COUNT(*) AS StudentCount,
    CASE 
        WHEN Year = '1' OR Year = 'I Year' THEN 'Year 1'
        WHEN Year = '2' OR Year = 'II Year' THEN 'Year 2'
        WHEN Year = '3' OR Year = 'III Year' THEN 'Year 3'
        WHEN Year = '4' OR Year = 'IV Year' THEN 'Year 4'
        ELSE 'Unknown'
    END AS MapsTo
FROM Students_CSEDS
GROUP BY Year
ORDER BY 
    CASE 
        WHEN Year LIKE '%I%' OR Year = '1' THEN 1
        WHEN Year LIKE '%II%' OR Year = '2' THEN 2
        WHEN Year LIKE '%III%' OR Year = '3' THEN 3
        WHEN Year LIKE '%IV%' OR Year = '4' THEN 4
        ELSE 5
    END;

PRINT '';
PRINT '=== EXPECTED COUNTS PER YEAR (AFTER FIX) ===';
PRINT '';

-- Year 1 (should match "I Year" OR "1")
DECLARE @Year1Count INT;
SELECT @Year1Count = COUNT(*) FROM Students_CSEDS WHERE Year = 'I Year' OR Year = '1';
PRINT 'Year 1 Students: ' + CAST(@Year1Count AS VARCHAR);

-- Year 2 (should match "II Year" OR "2")
DECLARE @Year2Count INT;
SELECT @Year2Count = COUNT(*) FROM Students_CSEDS WHERE Year = 'II Year' OR Year = '2';
PRINT 'Year 2 Students: ' + CAST(@Year2Count AS VARCHAR);

-- Year 3 (should match "III Year" OR "3")
DECLARE @Year3Count INT;
SELECT @Year3Count = COUNT(*) FROM Students_CSEDS WHERE Year = 'III Year' OR Year = '3';
PRINT 'Year 3 Students: ' + CAST(@Year3Count AS VARCHAR);

-- Year 4 (should match "IV Year" OR "4")
DECLARE @Year4Count INT;
SELECT @Year4Count = COUNT(*) FROM Students_CSEDS WHERE Year = 'IV Year' OR Year = '4';
PRINT 'Year 4 Students: ' + CAST(@Year4Count AS VARCHAR);

PRINT '';
PRINT '=== TOTAL STUDENTS ===';
DECLARE @TotalCount INT;
SELECT @TotalCount = COUNT(*) FROM Students_CSEDS;
PRINT 'Total CSEDS Students: ' + CAST(@TotalCount AS VARCHAR);

PRINT '';
PRINT '========================================';
PRINT 'VERIFICATION COMPLETE';
PRINT '========================================';
PRINT '';
PRINT 'Expected Results:';
PRINT '  Year 1: Should show count for "I Year" + "1"';
PRINT '  Year 2: Should show count for "II Year" + "2"';
PRINT '  Year 3: Should show count for "III Year" + "3"';
PRINT '  Year 4: Should show count for "IV Year" + "4"';
PRINT '';
PRINT 'After restarting the app, the Year Statistics page should show these counts!';
GO
