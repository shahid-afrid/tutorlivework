# COMPREHENSIVE FIX FOR ALL DYNAMIC MANAGEMENT PAGES

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "FIXING ALL DYNAMIC MANAGEMENT ISSUES" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Issues Found:" -ForegroundColor Yellow
Write-Host "1. ManageDynamicSubjects - Wrong ViewModel passed" -ForegroundColor Red
Write-Host "2. Views missing @model directives" -ForegroundColor Red
Write-Host "3. Controller needs to match CSEDS pattern" -ForegroundColor Red
Write-Host ""

# Fix 1: Add @model directive to ManageDynamicSubjects.cshtml
Write-Host "Step 1: Adding @model directive to ManageDynamicSubjects..." -ForegroundColor Green
$subjectsView = "Views\Admin\ManageDynamicSubjects.cshtml"
$content = Get-Content $subjectsView -Raw

# Add model directive at the top
if (-not ($content -match '^\s*@model')) {
    $content = "@model List<TutorLiveMentor.Models.Subject>`r`n" + $content
    Set-Content $subjectsView $content
    Write-Host "  ? Added @model List<Subject> to ManageDynamicSubjects" -ForegroundColor Green
} else {
    Write-Host "  ? Model directive already exists" -ForegroundColor Gray
}

# Fix 2: Update controller to pass correct model type
Write-Host "`nStep 2: Fixing ManageDynamicSubjects controller..." -ForegroundColor Green
Write-Host "  This needs manual code edit in AdminController.cs" -ForegroundColor Yellow
Write-Host "  Change from: SubjectManagementViewModel" -ForegroundColor Red
Write-Host "  Change to: List<Subject>" -ForegroundColor Green

# Fix 3: Check and fix ManageDynamicStudents
Write-Host "`nStep 3: Checking ManageDynamicStudents view..." -ForegroundColor Green
$studentsView = "Views\Admin\ManageDynamicStudents.cshtml"
$content = Get-Content $studentsView -Raw

# Check if model directive exists and is correct
if ($content -match '^\s*@model\s+TutorLiveMentor\.Models\.StudentManagementViewModel') {
    Write-Host "  ? ManageDynamicStudents has correct model" -ForegroundColor Green
} else {
    Write-Host "  ! ManageDynamicStudents needs model fix" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "MANUAL FIXES REQUIRED" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "You need to make these changes in AdminController.cs:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. ManageDynamicSubjects method (around line 1534):" -ForegroundColor White
Write-Host "   CHANGE FROM:" -ForegroundColor Red
Write-Host @"
   var viewModel = new SubjectManagementViewModel
   {
       Department = department,
       AdminEmail = HttpContext.Session.GetString("AdminEmail") ?? "",
       DepartmentSubjects = await GetSubjectsWithAssignmentsDynamic(normalizedDept),
       AvailableFaculty = await _context.Faculties
           .Where(f => f.Department == normalizedDept)
           .OrderBy(f => f.Name)
           .ToListAsync()
   };
   
   ViewBag.DepartmentName = deptInfo?.DepartmentName ?? department;
   return View(viewModel);
"@ -ForegroundColor Red

Write-Host ""
Write-Host "   CHANGE TO:" -ForegroundColor Green
Write-Host @"
   var subjects = await _context.Subjects
       .Where(s => s.Department == normalizedDept)
       .OrderBy(s => s.Year)
       .ThenBy(s => s.Name)
       .ToListAsync();
   
   ViewBag.DepartmentName = deptInfo?.DepartmentName ?? department;
   ViewBag.AdminEmail = HttpContext.Session.GetString("AdminEmail") ?? "";
   return View(subjects);
"@ -ForegroundColor Green

Write-Host ""
Write-Host "2. ManageDynamicStudents method (around line 1689):" -ForegroundColor White
Write-Host "   Check if it returns the correct model" -ForegroundColor Yellow

Write-Host ""
Write-Host "3. ManageDynamicAssignments method:" -ForegroundColor White
Write-Host "   Check if it returns the correct model" -ForegroundColor Yellow

Write-Host ""
Write-Host "4. DynamicReports method:" -ForegroundColor White
Write-Host "   Check if it returns the correct model" -ForegroundColor Yellow

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "NEXT STEPS" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "1. Open AdminController.cs" -ForegroundColor White
Write-Host "2. Find ManageDynamicSubjects method (line ~1534)" -ForegroundColor White
Write-Host "3. Apply the code change shown above" -ForegroundColor White
Write-Host "4. Save file" -ForegroundColor White
Write-Host "5. Build project" -ForegroundColor White
Write-Host "6. Test all management cards" -ForegroundColor White

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
