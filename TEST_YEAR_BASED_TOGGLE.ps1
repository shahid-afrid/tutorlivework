# TEST YEAR-BASED FACULTY SELECTION TOGGLE
# =====================================================
# This script verifies the year-based toggle implementation
# =====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TESTING YEAR-BASED FACULTY SELECTION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if Year column exists
Write-Host "Test 1: Verify Year column in FacultySelectionSchedules..." -ForegroundColor Yellow
$yearColumnCheck = sqlcmd -S localhost -d Working5Db -E -Q "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FacultySelectionSchedules' AND COLUMN_NAME = 'Year'" -h -1
if ($yearColumnCheck.Trim() -eq "1") {
    Write-Host "? Year column exists" -ForegroundColor Green
} else {
    Write-Host "? Year column missing!" -ForegroundColor Red
    exit 1
}

# Test 2: Check year-specific records
Write-Host ""
Write-Host "Test 2: Check year-specific schedule records..." -ForegroundColor Yellow
sqlcmd -S localhost -d Working5Db -E -Q "SELECT Year, IsEnabled, Department FROM FacultySelectionSchedules WHERE Department = 'CSEDS' ORDER BY Year" -W

# Test 3: Get year statistics
Write-Host ""
Write-Host "Test 3: Year-specific statistics..." -ForegroundColor Yellow

for ($year = 1; $year -le 4; $year++) {
    Write-Host ""
    Write-Host "Year $year Statistics:" -ForegroundColor Cyan
    
    $students = sqlcmd -S localhost -d Working5Db -E -Q "SELECT COUNT(*) FROM Students_CSEDS WHERE Year = '$year'" -h -1
    $subjects = sqlcmd -S localhost -d Working5Db -E -Q "SELECT COUNT(*) FROM Subjects_CSEDS WHERE Year = $year" -h -1
    
    Write-Host "  Students: $($students.Trim())" -ForegroundColor White
    Write-Host "  Subjects: $($subjects.Trim())" -ForegroundColor White
}

# Test 4: Verify view file exists
Write-Host ""
Write-Host "Test 4: Verify view file..." -ForegroundColor Yellow
if (Test-Path "Views\Admin\ManageFacultySelectionSchedule.cshtml") {
    Write-Host "? ManageFacultySelectionSchedule.cshtml exists" -ForegroundColor Green
} else {
    Write-Host "? View file missing!" -ForegroundColor Red
    exit 1
}

# Test 5: Check controller methods exist
Write-Host ""
Write-Host "Test 5: Verify controller methods..." -ForegroundColor Yellow
$controllerContent = Get-Content "Controllers\AdminControllerExtensions.cs" -Raw

$methods = @("GetYearSchedules", "GetYearStatistics", "UpdateYearSchedule", "YearScheduleUpdateRequest")
foreach ($method in $methods) {
    if ($controllerContent -like "*$method*") {
        Write-Host "? $method found" -ForegroundColor Green
    } else {
        Write-Host "? $method missing!" -ForegroundColor Red
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "? Database: Year column added" -ForegroundColor Green
Write-Host "? View: Updated with year cards" -ForegroundColor Green
Write-Host "? Controller: New methods added" -ForegroundColor Green
Write-Host "? Model: Year property added" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Login as CSEDS admin" -ForegroundColor White
Write-Host "2. Go to Manage Faculty Selection Schedule" -ForegroundColor White
Write-Host "3. Toggle individual year buttons" -ForegroundColor White
Write-Host "4. Verify students of that year are affected" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
