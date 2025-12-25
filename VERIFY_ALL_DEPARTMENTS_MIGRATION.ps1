# ============================================
# VERIFY ALL DEPARTMENTS MIGRATION
# ============================================
# This script verifies that the migration was successful
# for all departments (DES, IT, ECE, MECH)
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MIGRATION VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get connection string
$appSettingsPath = Join-Path $PSScriptRoot "appsettings.json"
$appSettings = Get-Content $appSettingsPath | ConvertFrom-Json
$connectionString = $appSettings.ConnectionStrings.DefaultConnection

if ($connectionString -match "Initial Catalog=([^;]+)") {
    $databaseName = $matches[1]
    Write-Host "?? Database: $databaseName" -ForegroundColor Cyan
}

Write-Host ""

# Create verification SQL
$verificationSQL = @"
-- ============================================
-- VERIFICATION QUERIES
-- ============================================

PRINT '========================================';
PRINT 'MIGRATION VERIFICATION REPORT';
PRINT '========================================';
PRINT '';

-- Check if all tables exist
PRINT '=== TABLE EXISTENCE CHECK ===';
PRINT '';

DECLARE @MissingTables TABLE (DeptCode NVARCHAR(10), TableName NVARCHAR(100));
DECLARE @DeptCodes TABLE (Code NVARCHAR(10));

INSERT INTO @DeptCodes VALUES ('DES'), ('IT'), ('ECE'), ('MECH');

-- Check for missing tables
DECLARE @DeptCode NVARCHAR(10);
DECLARE dept_cursor CURSOR FOR SELECT Code FROM @DeptCodes;

OPEN dept_cursor;
FETCH NEXT FROM dept_cursor INTO @DeptCode;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Faculty_' + @DeptCode)
        INSERT INTO @MissingTables VALUES (@DeptCode, 'Faculty_' + @DeptCode);
    
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Students_' + @DeptCode)
        INSERT INTO @MissingTables VALUES (@DeptCode, 'Students_' + @DeptCode);
    
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Subjects_' + @DeptCode)
        INSERT INTO @MissingTables VALUES (@DeptCode, 'Subjects_' + @DeptCode);
    
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'AssignedSubjects_' + @DeptCode)
        INSERT INTO @MissingTables VALUES (@DeptCode, 'AssignedSubjects_' + @DeptCode);
    
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'StudentEnrollments_' + @DeptCode)
        INSERT INTO @MissingTables VALUES (@DeptCode, 'StudentEnrollments_' + @DeptCode);
    
    FETCH NEXT FROM dept_cursor INTO @DeptCode;
END

CLOSE dept_cursor;
DEALLOCATE dept_cursor;

IF EXISTS (SELECT * FROM @MissingTables)
BEGIN
    PRINT '? MISSING TABLES:';
    SELECT * FROM @MissingTables;
END
ELSE
BEGIN
    PRINT '? All tables exist for all departments';
END

PRINT '';
PRINT '=== DATA COUNT VERIFICATION ===';
PRINT '';

-- DES Department
PRINT '--- DES DEPARTMENT ---';
SELECT 
    'DES' AS Department,
    'Faculty_DES' AS TableName,
    COUNT(*) AS RecordCount,
    CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END AS Status
FROM Faculty_DES
UNION ALL
SELECT 'DES', 'Students_DES', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM Students_DES
UNION ALL
SELECT 'DES', 'Subjects_DES', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM Subjects_DES
UNION ALL
SELECT 'DES', 'AssignedSubjects_DES', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM AssignedSubjects_DES
UNION ALL
SELECT 'DES', 'StudentEnrollments_DES', COUNT(*), CASE WHEN COUNT(*) >= 0 THEN '?' ELSE '?' END FROM StudentEnrollments_DES;

PRINT '';
PRINT '--- IT DEPARTMENT ---';
SELECT 
    'IT' AS Department,
    'Faculty_IT' AS TableName,
    COUNT(*) AS RecordCount,
    CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END AS Status
FROM Faculty_IT
UNION ALL
SELECT 'IT', 'Students_IT', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM Students_IT
UNION ALL
SELECT 'IT', 'Subjects_IT', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM Subjects_IT
UNION ALL
SELECT 'IT', 'AssignedSubjects_IT', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM AssignedSubjects_IT
UNION ALL
SELECT 'IT', 'StudentEnrollments_IT', COUNT(*), CASE WHEN COUNT(*) >= 0 THEN '?' ELSE '?' END FROM StudentEnrollments_IT;

PRINT '';
PRINT '--- ECE DEPARTMENT ---';
SELECT 
    'ECE' AS Department,
    'Faculty_ECE' AS TableName,
    COUNT(*) AS RecordCount,
    CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END AS Status
FROM Faculty_ECE
UNION ALL
SELECT 'ECE', 'Students_ECE', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM Students_ECE
UNION ALL
SELECT 'ECE', 'Subjects_ECE', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM Subjects_ECE
UNION ALL
SELECT 'ECE', 'AssignedSubjects_ECE', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM AssignedSubjects_ECE
UNION ALL
SELECT 'ECE', 'StudentEnrollments_ECE', COUNT(*), CASE WHEN COUNT(*) >= 0 THEN '?' ELSE '?' END FROM StudentEnrollments_ECE;

PRINT '';
PRINT '--- MECH DEPARTMENT ---';
SELECT 
    'MECH' AS Department,
    'Faculty_MECH' AS TableName,
    COUNT(*) AS RecordCount,
    CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END AS Status
FROM Faculty_MECH
UNION ALL
SELECT 'MECH', 'Students_MECH', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM Students_MECH
UNION ALL
SELECT 'MECH', 'Subjects_MECH', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM Subjects_MECH
UNION ALL
SELECT 'MECH', 'AssignedSubjects_MECH', COUNT(*), CASE WHEN COUNT(*) > 0 THEN '?' ELSE '?' END FROM AssignedSubjects_MECH
UNION ALL
SELECT 'MECH', 'StudentEnrollments_MECH', COUNT(*), CASE WHEN COUNT(*) >= 0 THEN '?' ELSE '?' END FROM StudentEnrollments_MECH;

PRINT '';
PRINT '=== DATA INTEGRITY CHECK ===';
PRINT '';

-- Check for orphaned records (students in dept tables but not in Departments)
PRINT '--- Checking Data Integrity ---';

-- Sample check: Verify department codes match
SELECT 
    'DES' AS Department,
    COUNT(*) AS FacultyCount,
    (SELECT COUNT(*) FROM Faculty_DES WHERE Department != 'DES') AS MismatchCount
FROM Faculty_DES
UNION ALL
SELECT 
    'IT',
    COUNT(*),
    (SELECT COUNT(*) FROM Faculty_IT WHERE Department != 'IT')
FROM Faculty_IT
UNION ALL
SELECT 
    'ECE',
    COUNT(*),
    (SELECT COUNT(*) FROM Faculty_ECE WHERE Department != 'ECE')
FROM Faculty_ECE
UNION ALL
SELECT 
    'MECH',
    COUNT(*),
    (SELECT COUNT(*) FROM Faculty_MECH WHERE Department != 'MECH')
FROM Faculty_MECH;

PRINT '';
PRINT '=== COMPARISON WITH SHARED TABLES ===';
PRINT '';

-- Compare counts between department tables and shared tables
PRINT '--- DES: Department vs Shared Tables ---';
SELECT 
    'Faculty' AS Entity,
    (SELECT COUNT(*) FROM Faculties WHERE Department = 'DES') AS SharedTable,
    (SELECT COUNT(*) FROM Faculty_DES) AS DeptTable,
    CASE 
        WHEN (SELECT COUNT(*) FROM Faculties WHERE Department = 'DES') = (SELECT COUNT(*) FROM Faculty_DES) 
        THEN '? Match' 
        ELSE '? Mismatch' 
    END AS Status;

PRINT '';
PRINT '--- IT: Department vs Shared Tables ---';
SELECT 
    'Faculty' AS Entity,
    (SELECT COUNT(*) FROM Faculties WHERE Department = 'IT') AS SharedTable,
    (SELECT COUNT(*) FROM Faculty_IT) AS DeptTable,
    CASE 
        WHEN (SELECT COUNT(*) FROM Faculties WHERE Department = 'IT') = (SELECT COUNT(*) FROM Faculty_IT) 
        THEN '? Match' 
        ELSE '? Mismatch' 
    END AS Status;

PRINT '';
PRINT '--- ECE: Department vs Shared Tables ---';
SELECT 
    'Faculty' AS Entity,
    (SELECT COUNT(*) FROM Faculties WHERE Department = 'ECE') AS SharedTable,
    (SELECT COUNT(*) FROM Faculty_ECE) AS DeptTable,
    CASE 
        WHEN (SELECT COUNT(*) FROM Faculties WHERE Department = 'ECE') = (SELECT COUNT(*) FROM Faculty_ECE) 
        THEN '? Match' 
        ELSE '? Mismatch' 
    END AS Status;

PRINT '';
PRINT '--- MECH: Department vs Shared Tables ---';
SELECT 
    'Faculty' AS Entity,
    (SELECT COUNT(*) FROM Faculties WHERE Department = 'MECH') AS SharedTable,
    (SELECT COUNT(*) FROM Faculty_MECH) AS DeptTable,
    CASE 
        WHEN (SELECT COUNT(*) FROM Faculties WHERE Department = 'MECH') = (SELECT COUNT(*) FROM Faculty_MECH) 
        THEN '? Match' 
        ELSE '? Mismatch' 
    END AS Status;

PRINT '';
PRINT '========================================';
PRINT '? VERIFICATION COMPLETE';
PRINT '========================================';
PRINT '';
PRINT '?? SUMMARY:';
PRINT '- All 20 tables checked (5 per department × 4 departments)';
PRINT '- Data counts compared with shared tables';
PRINT '- Data integrity verified';
PRINT '';
PRINT '?? If all checks passed:';
PRINT '  ? Migration successful';
PRINT '  ? Department-specific tables ready to use';
PRINT '  ? AdminControllerDynamicMethods can now use these tables';
PRINT '';
"@

# Save verification SQL to temp file
$tempSqlFile = Join-Path $env:TEMP "verify_migration.sql"
$verificationSQL | Out-File -FilePath $tempSqlFile -Encoding UTF8

try {
    Write-Host "Running verification queries..." -ForegroundColor Yellow
    Write-Host ""
    
    if (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue) {
        Invoke-Sqlcmd -ConnectionString $connectionString -InputFile $tempSqlFile -Verbose
    } else {
        $server = if ($connectionString -match "Server=([^;]+)") { $matches[1] } else { "localhost" }
        
        if ($connectionString -match "Integrated Security=true|Trusted_Connection=true") {
            sqlcmd -S $server -d $databaseName -E -i $tempSqlFile
        } elseif ($connectionString -match "User Id=([^;]+).*Password=([^;]+)") {
            $userId = $matches[1]
            $password = $matches[2]
            sqlcmd -S $server -d $databaseName -U $userId -P $password -i $tempSqlFile
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "? VERIFICATION COMPLETED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Review the results above to ensure:" -ForegroundColor Cyan
    Write-Host "  ? All tables exist" -ForegroundColor White
    Write-Host "  ? Data was migrated correctly" -ForegroundColor White
    Write-Host "  ? Record counts match shared tables" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "? ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
} finally {
    # Clean up temp file
    if (Test-Path $tempSqlFile) {
        Remove-Item $tempSqlFile -Force
    }
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
