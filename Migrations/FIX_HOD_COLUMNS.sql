-- =====================================================
-- FIX: Remove HeadOfDepartment columns from Departments table
-- =====================================================
-- Problem: Columns HeadOfDepartment and HeadOfDepartmentEmail still exist in database
-- but were removed from C# model, causing NULL insert errors
-- =====================================================

USE Working5Db;
GO

PRINT '?? Starting HeadOfDepartment columns removal...';
GO

-- Step 1: Check if columns exist
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = 'Departments' AND COLUMN_NAME = 'HeadOfDepartment')
BEGIN
    PRINT '? HeadOfDepartment column found - removing...';
    
    ALTER TABLE Departments
    DROP COLUMN HeadOfDepartment;
    
    PRINT '? HeadOfDepartment column removed successfully!';
END
ELSE
BEGIN
    PRINT '? HeadOfDepartment column does not exist (already removed)';
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_NAME = 'Departments' AND COLUMN_NAME = 'HeadOfDepartmentEmail')
BEGIN
    PRINT '? HeadOfDepartmentEmail column found - removing...';
    
    ALTER TABLE Departments
    DROP COLUMN HeadOfDepartmentEmail;
    
    PRINT '? HeadOfDepartmentEmail column removed successfully!';
END
ELSE
BEGIN
    PRINT '? HeadOfDepartmentEmail column does not exist (already removed)';
END
GO

-- Step 2: Verify the columns are gone
PRINT '';
PRINT '?? Verification - Current Departments table columns:';
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Departments'
ORDER BY ORDINAL_POSITION;
GO

PRINT '';
PRINT '? HOD columns removal complete!';
PRINT '? You can now create departments without HOD information';
GO
