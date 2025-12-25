-- ADD YEAR COLUMN TO FACULTYSELECTIONSCHEDULES TABLE
-- This enables year-based faculty selection toggles (Year 1, Year 2, Year 3, Year 4)
-- =====================================================

USE [Working5Db];
GO

PRINT '========================================';
PRINT 'ADDING YEAR COLUMN TO FACULTYSELECTIONSCHEDULES';
PRINT 'Started at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- Check if Year column already exists
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'FacultySelectionSchedules' 
               AND COLUMN_NAME = 'Year')
BEGIN
    PRINT 'Adding Year column to FacultySelectionSchedules table...';
    
    ALTER TABLE [dbo].[FacultySelectionSchedules]
    ADD [Year] INT NULL;
    
    PRINT '? Year column added successfully';
    PRINT '';
    PRINT 'Column Details:';
    PRINT '  - Name: Year';
    PRINT '  - Type: INT NULL';
    PRINT '  - Purpose: Year (1, 2, 3, 4) - NULL means applies to all years';
END
ELSE
BEGIN
    PRINT '? Year column already exists in FacultySelectionSchedules table';
END

PRINT '';
PRINT '========================================';
PRINT 'MIGRATION COMPLETE';
PRINT 'Completed at: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- Verify the column was added
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'FacultySelectionSchedules'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT 'Table structure verified above';
GO
