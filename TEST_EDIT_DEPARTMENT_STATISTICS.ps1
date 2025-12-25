# =====================================================
# TEST EDIT DEPARTMENT STATISTICS FIX
# =====================================================
# This script verifies that department statistics
# display correctly on the Edit Department page
# =====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST: EDIT DEPARTMENT STATISTICS FIX" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if app is running
$appProcess = Get-Process -Name "TutorLiveMentor10" -ErrorAction SilentlyContinue
if ($appProcess) {
    Write-Host "? App is RUNNING" -ForegroundColor Green
    Write-Host "  Process ID: $($appProcess.Id)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "If you just made code changes:" -ForegroundColor Yellow
    Write-Host "1. Try HOT RELOAD first (Visual Studio should detect changes)" -ForegroundColor White
    Write-Host "2. If that doesn't work, STOP (Shift+F5) and REBUILD" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "?  App is NOT running" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To test the fix:" -ForegroundColor Yellow
    Write-Host "1. START the application (F5 in Visual Studio)" -ForegroundColor White
    Write-Host "2. Login as Super Admin" -ForegroundColor White
    Write-Host "3. Go to Manage Departments" -ForegroundColor White
    Write-Host "4. Click Edit on CSEDS department" -ForegroundColor White
    Write-Host ""
    exit
}

Write-Host "Checking database for CSEDS department..." -ForegroundColor Yellow
Write-Host ""

$checkQuery = @"
-- Check CSEDS department statistics
DECLARE @DeptCode VARCHAR(50);

-- Get the actual department code from database
SELECT @DeptCode = DepartmentCode 
FROM Departments 
WHERE DepartmentName LIKE '%Computer Science%Data Science%' 
   OR DepartmentCode IN ('CSEDS', 'CSE(DS)', 'CSDS');

IF @DeptCode IS NULL
BEGIN
    PRINT 'ERROR: CSEDS department not found in database!';
END
ELSE
BEGIN
    PRINT 'Department Code in DB: ' + @DeptCode;
    PRINT '';
    
    -- Check statistics using the ACTUAL department code
    SELECT 
        'Total Students' AS Statistic,
        COUNT(*) AS Count
    FROM Students
    WHERE Department = @DeptCode
    
    UNION ALL
    
    SELECT 
        'Total Faculty',
        COUNT(*)
    FROM Faculties
    WHERE Department = @DeptCode
    
    UNION ALL
    
    SELECT 
        'Total Subjects',
        COUNT(*)
    FROM Subjects
    WHERE Department = @DeptCode
    
    UNION ALL
    
    SELECT 
        'Total Admins',
        COUNT(*)
    FROM Admins
    WHERE Department = @DeptCode;
    
    PRINT '';
    PRINT 'These numbers should now appear on Edit Department page!';
END
"@

try {
    $results = sqlcmd -S "localhost" -d "Working5Db" -Q $checkQuery
    Write-Host $results -ForegroundColor White
    Write-Host ""
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "TESTING INSTRUCTIONS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "1. Open browser to:" -ForegroundColor Yellow
    Write-Host "   http://localhost:5000/SuperAdmin/Login" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "2. Login with Super Admin credentials" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "3. Click 'Manage Departments' from dashboard" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "4. Find CSEDS department and click 'Edit'" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "5. Scroll down to 'Statistics' section" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "6. VERIFY the numbers match what's shown above" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Expected Result:" -ForegroundColor Green
    Write-Host "? Total Students: (number from above, NOT zero)" -ForegroundColor White
    Write-Host "? Total Faculty: (number from above, NOT zero)" -ForegroundColor White
    Write-Host "? Total Subjects: (number from above, NOT zero)" -ForegroundColor White
    Write-Host "? Total Admins: (number from above, NOT zero)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "If you still see zeros:" -ForegroundColor Red
    Write-Host "1. STOP the app (Shift+F5)" -ForegroundColor Yellow
    Write-Host "2. REBUILD (Ctrl+Shift+B)" -ForegroundColor Yellow
    Write-Host "3. START again (F5)" -ForegroundColor Yellow
    Write-Host "4. Test again" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "ERROR: Could not connect to database!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
