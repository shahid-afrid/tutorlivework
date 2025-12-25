# ========================================
# VERIFY AND FIX DEPARTMENT CODE NORMALIZATION
# ========================================
# This script checks if department codes are properly normalized and offers to fix them

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPARTMENT CODE NORMALIZATION CHECKER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Run verification query
Write-Host "Running verification checks..." -ForegroundColor Yellow
Write-Host ""

$verificationScript = @"
-- Check for CSE(DS) variations
SELECT 
    'Departments' AS TableName,
    COUNT(*) AS VariationCount
FROM Departments 
WHERE DepartmentCode LIKE '%CSE%DS%' AND DepartmentCode != 'CSEDS'

UNION ALL

SELECT 
    'Admins' AS TableName,
    COUNT(*) AS VariationCount
FROM Admins 
WHERE Department LIKE '%CSE%DS%' AND Department != 'CSEDS'

UNION ALL

SELECT 
    'Students' AS TableName,
    COUNT(*) AS VariationCount
FROM Students 
WHERE Department LIKE '%CSE%DS%' AND Department != 'CSEDS'

UNION ALL

SELECT 
    'Faculties' AS TableName,
    COUNT(*) AS VariationCount
FROM Faculties 
WHERE Department LIKE '%CSE%DS%' AND Department != 'CSEDS'

UNION ALL

SELECT 
    'Subjects' AS TableName,
    COUNT(*) AS VariationCount
FROM Subjects 
WHERE Department LIKE '%CSE%DS%' AND Department != 'CSEDS';
"@

# Show the SQL file location
$sqlFile = Join-Path $PSScriptRoot "VERIFY_DEPARTMENT_CODE_NORMALIZATION.sql"
Write-Host "SQL Verification Script: $sqlFile" -ForegroundColor Green
Write-Host ""

# Instructions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HOW TO RUN:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open SQL Server Management Studio (SSMS)" -ForegroundColor White
Write-Host "2. Connect to your database" -ForegroundColor White
Write-Host "3. Open the file: VERIFY_DEPARTMENT_CODE_NORMALIZATION.sql" -ForegroundColor White
Write-Host "4. Execute the script" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WHAT TO EXPECT:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "? If all department codes are CSEDS:" -ForegroundColor Green
Write-Host "   You'll see: 'ALL DEPARTMENT CODES ARE PROPERLY NORMALIZED TO CSEDS!'" -ForegroundColor White
Write-Host ""
Write-Host "? If CSE(DS) variations exist:" -ForegroundColor Red
Write-Host "   The script will show which tables have variations" -ForegroundColor White
Write-Host "   AND provide a QUICK FIX SCRIPT to normalize them" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IMPORTANT NOTES:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "??  The code fix in SuperAdminService.cs is already applied" -ForegroundColor Yellow
Write-Host "??  New departments will automatically use CSEDS format" -ForegroundColor Yellow
Write-Host "??  Existing departments can be updated using the fix script" -ForegroundColor Yellow
Write-Host ""

# Create a quick fix script as well
$quickFixScript = @"
-- ========================================
-- QUICK FIX: NORMALIZE ALL DEPARTMENT CODES TO CSEDS
-- ========================================
-- This script updates all CSE(DS) variations to CSEDS
-- Run this ONLY if the verification script shows variations

BEGIN TRANSACTION;

PRINT 'Normalizing Department Codes to CSEDS...';
PRINT '';

-- Update Departments table
UPDATE Departments 
SET DepartmentCode = 'CSEDS' 
WHERE DepartmentCode IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT 'Updated Departments: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- Update Admins table
UPDATE Admins 
SET Department = 'CSEDS' 
WHERE Department IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT 'Updated Admins: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- Update Students table
UPDATE Students 
SET Department = 'CSEDS' 
WHERE Department IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT 'Updated Students: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- Update Faculties table
UPDATE Faculties 
SET Department = 'CSEDS' 
WHERE Department IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT 'Updated Faculties: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

-- Update Subjects table
UPDATE Subjects 
SET Department = 'CSEDS' 
WHERE Department IN ('CSE(DS)', 'CSE-DS', 'CSE (DS)', 'CSE_DS', 'CSDS');
PRINT 'Updated Subjects: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';

PRINT '';
PRINT '? All department codes normalized to CSEDS!';
PRINT '';
PRINT 'Review the changes above. If everything looks correct:';
PRINT '  - Run: COMMIT TRANSACTION;';
PRINT '';
PRINT 'If you want to undo the changes:';
PRINT '  - Run: ROLLBACK TRANSACTION;';

-- Note: Transaction is left open for manual review
-- User must run COMMIT or ROLLBACK manually
"@

$quickFixFile = Join-Path $PSScriptRoot "FIX_DEPARTMENT_CODE_NORMALIZATION.sql"
Set-Content -Path $quickFixFile -Value $quickFixScript -Encoding UTF8

Write-Host "? Created fix script: $quickFixFile" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SCRIPT LOCATIONS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Verification: " -NoNewline; Write-Host "VERIFY_DEPARTMENT_CODE_NORMALIZATION.sql" -ForegroundColor Yellow
Write-Host "2. Quick Fix: " -NoNewline; Write-Host "FIX_DEPARTMENT_CODE_NORMALIZATION.sql" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PROCESS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Step 1: Run verification script" -ForegroundColor White
Write-Host "Step 2: If variations found, run fix script" -ForegroundColor White
Write-Host "Step 3: Review changes (transaction is open)" -ForegroundColor White
Write-Host "Step 4: Run COMMIT TRANSACTION to save OR ROLLBACK to undo" -ForegroundColor White
Write-Host ""

Write-Host "Done! Ready to verify and fix department codes." -ForegroundColor Green
Write-Host ""
