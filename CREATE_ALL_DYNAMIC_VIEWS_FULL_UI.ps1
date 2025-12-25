# COMPLETE A-Z DYNAMIC FUNCTIONALITY CREATOR
# This script copies ALL CSEDS views and makes them dynamic

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CREATING FULL A-Z DYNAMIC FUNCTIONALITY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Copy ManageCSEDSSubjects to ManageDynamicSubjects
Write-Host "1. Creating ManageDynamicSubjects with FULL UI..." -ForegroundColor Yellow
Copy-Item "Views\Admin\ManageCSEDSSubjects.cshtml" "Views\Admin\ManageDynamicSubjects.cshtml" -Force
$content = Get-Content "Views\Admin\ManageDynamicSubjects.cshtml" -Raw
$content = $content -replace 'Manage CSEDS Subjects', 'Manage @ViewBag.DepartmentName Subjects'
$content = $content -replace 'CSEDS Subjects', '@ViewBag.DepartmentName Subjects'
$content = $content -replace 'CSEDS', '@ViewBag.DepartmentName'
$content = $content -replace 'CSE\(DS\)', '@ViewBag.DepartmentName'
$content = $content -replace 'AddCSEDSSubject', 'AddDynamicSubject'
$content = $content -replace 'UpdateCSEDSSubject', 'UpdateDynamicSubject'
$content = $content -replace 'DeleteCSEDSSubject', 'DeleteDynamicSubject'
$content = $content -replace 'CSEDSDashboard', 'DynamicDashboard'
Set-Content "Views\Admin\ManageDynamicSubjects.cshtml" $content
Write-Host "  ? ManageDynamicSubjects.cshtml created with FULL UI!" -ForegroundColor Green

# Step 2: Copy ManageCSEDSStudents to ManageDynamicStudents
Write-Host "2. Creating ManageDynamicStudents with FULL UI..." -ForegroundColor Yellow
Copy-Item "Views\Admin\ManageCSEDSStudents.cshtml" "Views\Admin\ManageDynamicStudents.cshtml" -Force
$content = Get-Content "Views\Admin\ManageDynamicStudents.cshtml" -Raw
$content = $content -replace 'Manage CSEDS Students', 'Manage @ViewBag.DepartmentName Students'
$content = $content -replace 'CSEDS Students', '@ViewBag.DepartmentName Students'
$content = $content -replace 'CSEDS', '@ViewBag.DepartmentName'
$content = $content -replace 'CSE\(DS\)', '@ViewBag.DepartmentName'
$content = $content -replace 'AddCSEDSStudent', 'AddDynamicStudent'
$content = $content -replace 'UpdateCSEDSStudent', 'UpdateDynamicStudent'
$content = $content -replace 'DeleteCSEDSStudent', 'DeleteDynamicStudent'
$content = $content -replace 'CSEDSDashboard', 'DynamicDashboard'
Set-Content "Views\Admin\ManageDynamicStudents.cshtml" $content
Write-Host "  ? ManageDynamicStudents.cshtml created with FULL UI!" -ForegroundColor Green

# Step 3: Copy ManageSubjectAssignments to ManageDynamicAssignments
Write-Host "3. Creating ManageDynamicAssignments with FULL UI..." -ForegroundColor Yellow
Copy-Item "Views\Admin\ManageSubjectAssignments.cshtml" "Views\Admin\ManageDynamicAssignments.cshtml" -Force
$content = Get-Content "Views\Admin\ManageDynamicAssignments.cshtml" -Raw
$content = $content -replace 'CSEDS', '@ViewBag.DepartmentName'
$content = $content -replace 'CSE\(DS\)', '@ViewBag.DepartmentName'
$content = $content -replace 'ManageSubjectAssignments', 'ManageDynamicAssignments'
$content = $content -replace 'AssignFacultyToSubject', 'AssignFacultyToDynamicSubject'
$content = $content -replace 'RemoveFacultyAssignment', 'RemoveDynamicFacultyAssignment'
$content = $content -replace 'GetAvailableFacultyForSubject', 'GetAvailableFacultyForDynamicSubject'
$content = $content -replace 'CSEDSDashboard', 'DynamicDashboard'
Set-Content "Views\Admin\ManageDynamicAssignments.cshtml" $content
Write-Host "  ? ManageDynamicAssignments.cshtml created with FULL UI!" -ForegroundColor Green

# Step 4: Copy CSEDSReports to DynamicReports
Write-Host "4. Creating DynamicReports with FULL UI..." -ForegroundColor Yellow
Copy-Item "Views\Admin\CSEDSReports.cshtml" "Views\Admin\DynamicReports.cshtml" -Force
$content = Get-Content "Views\Admin\DynamicReports.cshtml" -Raw
$content = $content -replace 'CSEDS Reports', '@ViewBag.DepartmentName Reports'
$content = $content -replace 'CSEDS', '@ViewBag.DepartmentName'
$content = $content -replace 'CSE\(DS\)', '@ViewBag.DepartmentName'
$content = $content -replace 'GenerateCSEDSReport', 'GenerateDynamicReport'
$content = $content -replace 'ExportCSEDSReportToExcel', 'ExportDynamicReportToExcel'
$content = $content -replace 'ExportCSEDSReportToPDF', 'ExportDynamicReportToPDF'
$content = $content -replace 'CSEDSDashboard', 'DynamicDashboard'
Set-Content "Views\Admin\DynamicReports.cshtml" $content
Write-Host "  ? DynamicReports.cshtml created with FULL UI!" -ForegroundColor Green

# Step 5: Copy ManageFacultySelectionSchedule to ManageDynamicSchedule
Write-Host "5. Creating ManageDynamicSchedule with FULL UI..." -ForegroundColor Yellow
Copy-Item "Views\Admin\ManageFacultySelectionSchedule.cshtml" "Views\Admin\ManageDynamicSchedule.cshtml" -Force
$content = Get-Content "Views\Admin\ManageDynamicSchedule.cshtml" -Raw
$content = $content -replace 'CSEDS', '@ViewBag.DepartmentName'
$content = $content -replace 'CSE\(DS\)', '@ViewBag.DepartmentName'
$content = $content -replace 'ToggleSchedule', 'ToggleDynamicSchedule'
$content = $content -replace 'UpdateSchedule', 'UpdateDynamicSchedule'
$content = $content -replace 'CSEDSDashboard', 'DynamicDashboard'
Set-Content "Views\Admin\ManageDynamicSchedule.cshtml" $content
Write-Host "  ? ManageDynamicSchedule.cshtml created with FULL UI!" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "? ALL 5 VIEWS CREATED WITH FULL UI!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Now run: dotnet build" -ForegroundColor Yellow
Write-Host "Then test your app!" -ForegroundColor Cyan
