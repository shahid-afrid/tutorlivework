-- =============================================
-- Add Semester Column to Students Table
-- Date: 2025-01-28
-- Description: Add Semester field to Students table for semester-based filtering
-- =============================================

USE [TutorLiveMentor];
GO

-- Check if column exists before adding
IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Students' AND COLUMN_NAME = 'Semester'
)
BEGIN
    PRINT 'Adding Semester column to Students table...';
    
    ALTER TABLE Students
    ADD Semester NVARCHAR(50) NOT NULL DEFAULT '';
    
    PRINT 'Semester column added successfully.';
END
ELSE
BEGIN
    PRINT 'Semester column already exists in Students table.';
END
GO

-- Update existing students based on their Year
-- Since each year has only 2 semesters (I or II), we'll default to Semester I
PRINT 'Updating semester values for existing students...';

-- Default all students to Semester I (can be changed later by admin)
UPDATE Students
SET Semester = 'I'
WHERE Semester = '' OR Semester IS NULL;

PRINT 'Semester values updated successfully (all set to Semester I by default).';
PRINT 'Note: Each year has only 2 semesters (I and II). Admins can update individual students as needed.';
GO

-- Verify the changes
PRINT 'Verifying semester column and data...';
SELECT 
    Year,
    Semester,
    COUNT(*) as StudentCount
FROM Students
GROUP BY Year, Semester
ORDER BY Year, Semester;
GO

PRINT 'Migration completed successfully!';
