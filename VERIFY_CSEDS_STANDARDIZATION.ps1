# =====================================================
# Verify Complete CSEDS Standardization
# =====================================================
# This script verifies that ALL CSE(DS) variations
# have been successfully converted to "CSEDS"
# =====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "VERIFY CSEDS STANDARDIZATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$verificationSQL = @"
-- =====================================================
-- VERIFICATION: Check for any remaining variations
-- =====================================================

PRINT 'VERIFICATION REPORT';
PRINT '==================';
PRINT '';

-- Count all CSEDS records (should be the only format)
PRINT '1. CSEDS Record Counts (Standardized):';
PRINT '---------------------------------------';

SELECT 
    'Students' AS TableName,
    Department,
    COUNT(*) AS [Count]
FROM Students
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 
    'Faculties',
    Department,
    COUNT(*)
FROM Faculties
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 
    'Subjects',
    Department,
    COUNT(*)
FROM Subjects
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 
    'Admins',
    Department,
    COUNT(*)
FROM Admins
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 
    'SubjectAssignments',
    Department,
    COUNT(*)
FROM SubjectAssignments
WHERE Department LIKE '%DS%' OR Department LIKE '%CSED%'
GROUP BY Department

UNION ALL

SELECT 
    'Departments',
    DepartmentCode,
    COUNT(*)
FROM Departments
WHERE DepartmentCode LIKE '%DS%' OR DepartmentCode LIKE '%CSED%'
GROUP BY DepartmentCode

ORDER BY TableName, Department;

PRINT '';
PRINT '';

-- Check for any remaining variations (should return 0 rows)
PRINT '2. Check for Non-CSEDS Variations (Should be 0):';
PRINT '------------------------------------------------';

DECLARE @VariationCount INT = 0;

SELECT @VariationCount = COUNT(*)
FROM (
    SELECT 'Students' AS TableName, Department 
    FROM Students 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    
    UNION ALL
    
    SELECT 'Faculties', Department 
    FROM Faculties 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    
    UNION ALL
    
    SELECT 'Subjects', Department 
    FROM Subjects 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    
    UNION ALL
    
    SELECT 'Admins', Department 
    FROM Admins 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    
    UNION ALL
    
    SELECT 'SubjectAssignments', Department 
    FROM SubjectAssignments 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    
    UNION ALL
    
    SELECT 'Departments', DepartmentCode 
    FROM Departments 
    WHERE DepartmentCode IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
) AS Variations;

IF @VariationCount = 0
BEGIN
    PRINT 'SUCCESS: No variations found - All standardized to CSEDS!';
    PRINT '';
END
ELSE
BEGIN
    PRINT 'WARNING: ' + CAST(@VariationCount AS VARCHAR) + ' non-standard variations still exist!';
    PRINT 'Please review and run the migration again.';
    PRINT '';
    
    -- Show which variations remain
    SELECT 'Students' AS TableName, Department, COUNT(*) AS [Count]
    FROM Students 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    GROUP BY Department
    
    UNION ALL
    
    SELECT 'Faculties', Department, COUNT(*)
    FROM Faculties 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    GROUP BY Department
    
    UNION ALL
    
    SELECT 'Subjects', Department, COUNT(*)
    FROM Subjects 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    GROUP BY Department
    
    UNION ALL
    
    SELECT 'Admins', Department, COUNT(*)
    FROM Admins 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    GROUP BY Department
    
    UNION ALL
    
    SELECT 'SubjectAssignments', Department, COUNT(*)
    FROM SubjectAssignments 
    WHERE Department IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    GROUP BY Department
    
    UNION ALL
    
    SELECT 'Departments', DepartmentCode, COUNT(*)
    FROM Departments 
    WHERE DepartmentCode IN ('CSE(DS)', 'CSE (DS)', 'CSDS', 'CSE-DS', 'CSE_DS', 'Cse(Ds)', 'cse(ds)')
    GROUP BY DepartmentCode;
END

PRINT '';
PRINT '3. Summary:';
PRINT '-----------';

SELECT 
    'Total CSEDS Students' AS Metric,
    CAST(COUNT(*) AS VARCHAR) AS Value
FROM Students WHERE Department = 'CSEDS'

UNION ALL

SELECT 
    'Total CSEDS Faculties',
    CAST(COUNT(*) AS VARCHAR)
FROM Faculties WHERE Department = 'CSEDS'

UNION ALL

SELECT 
    'Total CSEDS Subjects',
    CAST(COUNT(*) AS VARCHAR)
FROM Subjects WHERE Department = 'CSEDS'

UNION ALL

SELECT 
    'Total CSEDS Admins',
    CAST(COUNT(*) AS VARCHAR)
FROM Admins WHERE Department = 'CSEDS'

UNION ALL

SELECT 
    'Total CSEDS SubjectAssignments',
    CAST(COUNT(*) AS VARCHAR)
FROM SubjectAssignments WHERE Department = 'CSEDS';

PRINT '';
PRINT 'VERIFICATION COMPLETE';
PRINT '=====================';
"@

try {
    Write-Host "Executing verification queries..." -ForegroundColor Yellow
    Write-Host ""

    # Save SQL to temp file
    $tempSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
    $verificationSQL | Out-File -FilePath $tempSqlFile -Encoding UTF8

    # Execute verification with correct database
    $output = sqlcmd -S "localhost" -d "Working5Db" -i $tempSqlFile -b

    # Display results
    Write-Host $output -ForegroundColor White
    Write-Host ""

    # Check if successful
    if ($output -match "SUCCESS: No variations found") {
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "VERIFICATION PASSED!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "All CSE(DS) variations have been successfully standardized to CSEDS." -ForegroundColor Green
        Write-Host ""
        Write-Host "Database Status: CLEAN" -ForegroundColor Green
        Write-Host "Format Used: CSEDS (consistent everywhere)" -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host "VERIFICATION INCOMPLETE" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Some non-standard variations may still exist." -ForegroundColor Yellow
        Write-Host "Review the output above and run the migration again if needed." -ForegroundColor Yellow
        Write-Host ""
    }

    # Cleanup
    Remove-Item $tempSqlFile -ErrorAction SilentlyContinue
}
catch {
    Write-Host ""
    Write-Host "ERROR: Verification failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
}
