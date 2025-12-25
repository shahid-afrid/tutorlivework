# Quick Script to Create All Dynamic Views
# Run this in PowerShell from the project root directory

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Creating Dynamic Department Views" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$viewsPath = "Views\Admin"

# 1. Create ManageDynamicFaculty.cshtml
Write-Host "1. Creating ManageDynamicFaculty.cshtml..." -ForegroundColor Yellow
$csedsFacultyPath = "$viewsPath\ManageCSEDSFaculty.cshtml"
$dynamicFacultyPath = "$viewsPath\ManageDynamicFaculty.cshtml"

if (Test-Path $csedsFacultyPath) {
    $content = Get-Content $csedsFacultyPath -Raw
    
    # Replace CSEDS-specific text with dynamic versions
    $content = $content -replace 'Manage CSEDS Faculty', 'Manage @ViewBag.DepartmentName Faculty'
    $content = $content -replace 'CSEDS Faculty Management', '@ViewBag.DepartmentName Faculty Management'
    $content = $content -replace 'CSE\(DS\) department', '@ViewBag.DepartmentName department'
    $content = $content -replace 'CSEDS', '@ViewBag.DepartmentName'
    $content = $content -replace 'CSE\(DS\)', '@ViewBag.DepartmentName'
    $content = $content -replace 'ManageCSEDSFaculty', 'ManageDynamicFaculty'
    $content = $content -replace 'AddCSEDSFaculty', 'AddDynamicFaculty'
    $content = $content -replace 'UpdateCSEDSFaculty', 'UpdateDynamicFaculty'
    $content = $content -replace 'DeleteCSEDSFaculty', 'DeleteDynamicFaculty'
    $content = $content -replace 'GetDepartmentFaculty', 'GetDynamicDepartmentFaculty'
    
    Set-Content -Path $dynamicFacultyPath -Value $content
    Write-Host "   ? Created $dynamicFacultyPath" -ForegroundColor Green
} else {
    Write-Host "   ? Source file not found: $csedsFacultyPath" -ForegroundColor Red
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Run this script to create ManageDynamicFaculty view" -ForegroundColor White
Write-Host "2. Test faculty management with DES department" -ForegroundColor White
Write-Host "3. Repeat same pattern for:" -ForegroundColor White
Write-Host "   - Subjects (ManageDynamicSubjects.cshtml)" -ForegroundColor Gray
Write-Host "   - Students (ManageDynamicStudents.cshtml)" -ForegroundColor Gray
Write-Host "   - Assignments (ManageDynamicAssignments.cshtml)" -ForegroundColor Gray
Write-Host "   - Reports (DynamicReports.cshtml)" -ForegroundColor Gray
Write-Host "   - Schedule (ManageDynamicSchedule.cshtml)" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
