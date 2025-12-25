-- ========================================
-- QUICK FIX: NORMALIZE ALL DEPARTMENT CODES TO CSEDS
-- ========================================
-- This script updates all CSE(DS) variations to CSEDS
-- Run this ONLY if the verification script shows variations

BEGIN TRANSACTION;

PRINT '========================================';
PRINT 'NORMALIZING DEPARTMENT CODES TO CSEDS';
PRINT '========================================';
PRINT '';

-- Update Departments table
PRINT '1. Updating Departments table...';
UPDATE Departments 
SET DepartmentCode = 'CSEDS' 
WHERE DepartmentCode IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT '   ? Updated Departments: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- Update Admins table
PRINT '2. Updating Admins table...';
UPDATE Admins 
SET Department = 'CSEDS' 
WHERE Department IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT '   ? Updated Admins: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- Update Students table
PRINT '3. Updating Students table...';
UPDATE Students 
SET Department = 'CSEDS' 
WHERE Department IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT '   ? Updated Students: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- Update Faculties table
PRINT '4. Updating Faculties table...';
UPDATE Faculties 
SET Department = 'CSEDS' 
WHERE Department IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT '   ? Updated Faculties: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

-- Update Subjects table
PRINT '5. Updating Subjects table...';
UPDATE Subjects 
SET Department = 'CSEDS' 
WHERE Department IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT '   ? Updated Subjects: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
PRINT '';

PRINT '========================================';
PRINT 'NORMALIZATION COMPLETE!';
PRINT '========================================';
PRINT '';
PRINT '? All department codes have been normalized to CSEDS!';
PRINT '';
PRINT '??  IMPORTANT: Transaction is open for review';
PRINT '';
PRINT 'To SAVE the changes:';
PRINT '   Run: COMMIT TRANSACTION;';
PRINT '';
PRINT 'To UNDO the changes:';
PRINT '   Run: ROLLBACK TRANSACTION;';
PRINT '';
PRINT '========================================';

-- Note: Transaction is left open for manual review
-- User must run COMMIT or ROLLBACK manually
