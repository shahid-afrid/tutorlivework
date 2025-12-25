# FIX DYNAMIC DEPARTMENT FACULTY AND NAVIGATION ISSUES

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FIXING DYNAMIC DEPARTMENT ISSUES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Issues to fix:" -ForegroundColor Yellow
Write-Host "1. Faculty not adding - wrong API endpoint" -ForegroundColor Yellow
Write-Host "2. Other cards not opening - @ViewBag in URLs" -ForegroundColor Yellow
Write-Host ""

# Fix 1: ManageDynamicFaculty.cshtml - Fix Add Faculty endpoint
Write-Host "Fixing ManageDynamicFaculty Add Faculty endpoint..." -ForegroundColor Green
$facultyFile = "Views\Admin\ManageDynamicFaculty.cshtml"
$content = Get-Content $facultyFile -Raw

# Fix the Add Faculty fetch URL
$content = $content -replace '@Url\.Action\("Add@ViewBag\.DepartmentNameFaculty", "Admin"\)', '@Url.Action("AddDynamicFaculty", "Admin")'

# Fix Update Faculty fetch URL
$content = $content -replace '@Url\.Action\("Update@ViewBag\.DepartmentNameFaculty", "Admin"\)', '@Url.Action("UpdateDynamicFaculty", "Admin")'

# Fix Delete Faculty fetch URL
$content = $content -replace '@Url\.Action\("Delete@ViewBag\.DepartmentNameFaculty", "Admin"\)', '@Url.Action("DeleteDynamicFaculty", "Admin")'

# Fix back to dashboard link
$content = $content -replace '@Url\.Action\("@ViewBag\.DepartmentNameDashboard", "Admin"\)', '@Url.Action("DynamicDashboard", "Admin")'

Set-Content $facultyFile $content
Write-Host "  ? Fixed ManageDynamicFaculty.cshtml" -ForegroundColor Green

# Fix 2: ManageDynamicSubjects.cshtml
Write-Host "Fixing ManageDynamicSubjects..." -ForegroundColor Green
$subjectsFile = "Views\Admin\ManageDynamicSubjects.cshtml"
if (Test-Path $subjectsFile) {
    $content = Get-Content $subjectsFile -Raw
    
    # Fix Add Subject
    $content = $content -replace '@Url\.Action\("Add@ViewBag\.DepartmentNameSubject", "Admin"\)', '@Url.Action("AddDynamicSubject", "Admin")'
    
    # Fix Update Subject
    $content = $content -replace '@Url\.Action\("Update@ViewBag\.DepartmentNameSubject", "Admin"\)', '@Url.Action("UpdateDynamicSubject", "Admin")'
    
    # Fix Delete Subject
    $content = $content -replace '@Url\.Action\("Delete@ViewBag\.DepartmentNameSubject", "Admin"\)', '@Url.Action("DeleteDynamicSubject", "Admin")'
    
    # Fix back to dashboard
    $content = $content -replace '@Url\.Action\("@ViewBag\.DepartmentNameDashboard", "Admin"\)', '@Url.Action("DynamicDashboard", "Admin")'
    
    Set-Content $subjectsFile $content
    Write-Host "  ? Fixed ManageDynamicSubjects.cshtml" -ForegroundColor Green
}

# Fix 3: ManageDynamicStudents.cshtml
Write-Host "Fixing ManageDynamicStudents..." -ForegroundColor Green
$studentsFile = "Views\Admin\ManageDynamicStudents.cshtml"
if (Test-Path $studentsFile) {
    $content = Get-Content $studentsFile -Raw
    
    # Fix Add Student
    $content = $content -replace '@Url\.Action\("Add@ViewBag\.DepartmentNameStudent", "Admin"\)', '@Url.Action("AddDynamicStudent", "Admin")'
    
    # Fix Edit Student
    $content = $content -replace '@Url\.Action\("Edit@ViewBag\.DepartmentNameStudent"', '@Url.Action("EditDynamicStudent"'
    
    # Fix Delete Student
    $content = $content -replace '@Url\.Action\("Delete@ViewBag\.DepartmentNameStudent", "Admin"\)', '@Url.Action("DeleteDynamicStudent", "Admin")'
    
    # Fix back to dashboard
    $content = $content -replace '@Url\.Action\("@ViewBag\.DepartmentNameDashboard", "Admin"\)', '@Url.Action("DynamicDashboard", "Admin")'
    
    Set-Content $studentsFile $content
    Write-Host "  ? Fixed ManageDynamicStudents.cshtml" -ForegroundColor Green
}

# Fix 4: ManageDynamicAssignments.cshtml
Write-Host "Fixing ManageDynamicAssignments..." -ForegroundColor Green
$assignmentsFile = "Views\Admin\ManageDynamicAssignments.cshtml"
if (Test-Path $assignmentsFile) {
    $content = Get-Content $assignmentsFile -Raw
    
    # Fix Assign Faculty
    $content = $content -replace '@Url\.Action\("AssignFacultyTo@ViewBag\.DepartmentNameSubject", "Admin"\)', '@Url.Action("AssignFacultyToDynamicSubject", "Admin")'
    
    # Fix Remove Assignment
    $content = $content -replace '@Url\.Action\("Remove@ViewBag\.DepartmentNameFacultyAssignment", "Admin"\)', '@Url.Action("RemoveDynamicFacultyAssignment", "Admin")'
    
    # Fix back to dashboard
    $content = $content -replace '@Url\.Action\("@ViewBag\.DepartmentNameDashboard", "Admin"\)', '@Url.Action("DynamicDashboard", "Admin")'
    
    Set-Content $assignmentsFile $content
    Write-Host "  ? Fixed ManageDynamicAssignments.cshtml" -ForegroundColor Green
}

# Fix 5: DynamicReports.cshtml
Write-Host "Fixing DynamicReports..." -ForegroundColor Green
$reportsFile = "Views\Admin\DynamicReports.cshtml"
if (Test-Path $reportsFile) {
    $content = Get-Content $reportsFile -Raw
    
    # Fix Generate Report
    $content = $content -replace '@Url\.Action\("Generate@ViewBag\.DepartmentNameReport", "AdminReports"\)', '@Url.Action("GenerateDynamicReport", "AdminReports")'
    
    # Fix Export Excel
    $content = $content -replace '@Url\.Action\("Export@ViewBag\.DepartmentNameReportToExcel", "AdminReports"\)', '@Url.Action("ExportDynamicReportToExcel", "AdminReports")'
    
    # Fix Export PDF
    $content = $content -replace '@Url\.Action\("Export@ViewBag\.DepartmentNameReportToPDF", "AdminReports"\)', '@Url.Action("ExportDynamicReportToPDF", "AdminReports")'
    
    # Fix back to dashboard
    $content = $content -replace '@Url\.Action\("@ViewBag\.DepartmentNameDashboard", "Admin"\)', '@Url.Action("DynamicDashboard", "Admin")'
    
    Set-Content $reportsFile $content
    Write-Host "  ? Fixed DynamicReports.cshtml" -ForegroundColor Green
}

# Fix 6: ManageDynamicSchedule.cshtml
Write-Host "Fixing ManageDynamicSchedule..." -ForegroundColor Green
$scheduleFile = "Views\Admin\ManageDynamicSchedule.cshtml"
if (Test-Path $scheduleFile) {
    $content = Get-Content $scheduleFile -Raw
    
    # Fix Toggle Schedule
    $content = $content -replace '@Url\.Action\("Toggle@ViewBag\.DepartmentNameSchedule", "Admin"\)', '@Url.Action("ToggleDynamicSchedule", "Admin")'
    
    # Fix Update Schedule
    $content = $content -replace '@Url\.Action\("Update@ViewBag\.DepartmentNameSchedule", "Admin"\)', '@Url.Action("UpdateDynamicSchedule", "Admin")'
    
    # Fix back to dashboard
    $content = $content -replace '@Url\.Action\("@ViewBag\.DepartmentNameDashboard", "Admin"\)', '@Url.Action("DynamicDashboard", "Admin")'
    
    Set-Content $scheduleFile $content
    Write-Host "  ? Fixed ManageDynamicSchedule.cshtml" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "? ALL FIXES APPLIED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "What was fixed:" -ForegroundColor Cyan
Write-Host "1. Faculty Add/Edit/Delete now uses correct endpoints" -ForegroundColor White
Write-Host "   - AddDynamicFaculty instead of Add@ViewBag.DepartmentNameFaculty" -ForegroundColor Gray
Write-Host ""
Write-Host "2. All other management pages fixed:" -ForegroundColor White
Write-Host "   - Subjects" -ForegroundColor Gray
Write-Host "   - Students" -ForegroundColor Gray
Write-Host "   - Assignments" -ForegroundColor Gray
Write-Host "   - Reports" -ForegroundColor Gray
Write-Host "   - Schedule" -ForegroundColor Gray
Write-Host ""
Write-Host "3. All 'Back to Dashboard' links now work" -ForegroundColor White
Write-Host "   - DynamicDashboard instead of @ViewBag.DepartmentNameDashboard" -ForegroundColor Gray
Write-Host ""

Write-Host "Now build and test:" -ForegroundColor Yellow
Write-Host "1. Build: dotnet build" -ForegroundColor White
Write-Host "2. Run: F5" -ForegroundColor White
Write-Host "3. Login as DES admin" -ForegroundColor White
Write-Host "4. Test adding faculty - should work now!" -ForegroundColor White
Write-Host "5. Test all other management cards - should open!" -ForegroundColor White
Write-Host ""

Write-Host "Press any key to build now..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host "Building project..." -ForegroundColor Yellow
dotnet build

Write-Host ""
Write-Host "Build complete! Press F5 to test!" -ForegroundColor Green
