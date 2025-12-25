# ========================================
# TEST EDIT DEPARTMENT ISSUE IN REAL-TIME
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EDIT DEPARTMENT STATISTICS BUG TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will help diagnose why statistics turn to zero when editing department" -ForegroundColor Yellow
Write-Host ""

# Instructions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TESTING PROCESS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. BEFORE EDITING:" -ForegroundColor Green
Write-Host "   - Run: TEST_EDIT_DEPARTMENT_BEFORE_AFTER.sql in SSMS" -ForegroundColor White
Write-Host "   - This captures the BEFORE state" -ForegroundColor White
Write-Host ""
Write-Host "2. EDIT THE DEPARTMENT:" -ForegroundColor Yellow
Write-Host "   - Go to: http://localhost:5000/SuperAdmin/EditDepartment/1" -ForegroundColor White
Write-Host "   - Add HOD name: Dr. Test" -ForegroundColor White
Write-Host "   - Add HOD email: test@test.com" -ForegroundColor White
Write-Host "   - Click 'Update Department'" -ForegroundColor White
Write-Host ""
Write-Host "3. AFTER EDITING:" -ForegroundColor Red
Write-Host "   - Run: TEST_EDIT_DEPARTMENT_BEFORE_AFTER.sql again" -ForegroundColor White
Write-Host "   - Compare the results with BEFORE" -ForegroundColor White
Write-Host ""
Write-Host "4. ANALYZE:" -ForegroundColor Magenta
Write-Host "   - Look for changes in DepartmentCode" -ForegroundColor White
Write-Host "   - Check if Student/Faculty/Subject codes changed" -ForegroundColor White
Write-Host "   - See if statistics match" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EXPECTED BEHAVIOR (WITH FIX):" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "BEFORE:" -ForegroundColor Green
Write-Host "  Departments.DepartmentCode = CSEDS (or CSE(DS))" -ForegroundColor White
Write-Host "  Students.Department = CSEDS" -ForegroundColor White
Write-Host "  Statistics = 5 students, 3 faculty, etc." -ForegroundColor White
Write-Host ""
Write-Host "AFTER:" -ForegroundColor Green
Write-Host "  Departments.DepartmentCode = CSEDS (NORMALIZED)" -ForegroundColor White
Write-Host "  Students.Department = CSEDS (UNCHANGED)" -ForegroundColor White
Write-Host "  Statistics = 5 students, 3 faculty, etc. (SAME)" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BROKEN BEHAVIOR (WITHOUT FIX):" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "BEFORE:" -ForegroundColor Red
Write-Host "  Departments.DepartmentCode = CSEDS" -ForegroundColor White
Write-Host "  Students.Department = CSEDS" -ForegroundColor White
Write-Host "  Statistics = 5 students, 3 faculty, etc." -ForegroundColor White
Write-Host ""
Write-Host "AFTER:" -ForegroundColor Red
Write-Host "  Departments.DepartmentCode = CSE(DS) (NOT NORMALIZED!)" -ForegroundColor White
Write-Host "  Students.Department = CSEDS (UNCHANGED)" -ForegroundColor White
Write-Host "  Statistics = 0 students, 0 faculty, etc. (MISMATCH!)" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "IMPORTANT CHECKS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Has the app been RESTARTED after code fix?" -ForegroundColor Yellow
Write-Host "   - If NO: Stop app (Shift+F5), then Start (F5)" -ForegroundColor White
Write-Host ""
Write-Host "2. Is DepartmentNormalizer being called?" -ForegroundColor Yellow
Write-Host "   - Check Services/SuperAdminService.cs line ~305" -ForegroundColor White
Write-Host "   - Should have: var normalizedDeptCode = DepartmentNormalizer.Normalize(...)" -ForegroundColor White
Write-Host ""
Write-Host "3. Are Students under CSEDS or CSE(DS)?" -ForegroundColor Yellow
Write-Host "   - Run: SELECT Department, COUNT(*) FROM Students GROUP BY Department" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "QUICK FIX OPTIONS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1: NORMALIZE DATABASE (Recommended)" -ForegroundColor Green
Write-Host "  - Run: FIX_DEPARTMENT_CODE_NORMALIZATION.sql" -ForegroundColor White
Write-Host "  - This converts all CSE(DS) to CSEDS in database" -ForegroundColor White
Write-Host ""
Write-Host "Option 2: RESTART APP" -ForegroundColor Yellow
Write-Host "  - Stop debugging (Shift+F5)" -ForegroundColor White
Write-Host "  - Start debugging (F5)" -ForegroundColor White
Write-Host "  - Code fix takes effect" -ForegroundColor White
Write-Host ""
Write-Host "Option 3: VERIFY CODE FIX" -ForegroundColor Cyan
Write-Host "  - Open: Services/SuperAdminService.cs" -ForegroundColor White
Write-Host "  - Go to line ~305 (UpdateDepartment method)" -ForegroundColor White
Write-Host "  - Verify: var normalizedDeptCode = DepartmentNormalizer.Normalize(model.DepartmentCode.ToUpper());" -ForegroundColor White
Write-Host "  - Verify: department.DepartmentCode = normalizedDeptCode;" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FILES TO USE:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Diagnosis:" -NoNewline; Write-Host " TEST_EDIT_DEPARTMENT_BEFORE_AFTER.sql" -ForegroundColor Yellow
Write-Host "Full check:" -NoNewline; Write-Host " DIAGNOSE_EDIT_DEPARTMENT_ISSUE.sql" -ForegroundColor Yellow
Write-Host "Quick fix:" -NoNewline; Write-Host " FIX_DEPARTMENT_CODE_NORMALIZATION.sql" -ForegroundColor Yellow
Write-Host ""

Write-Host "Ready to test! Follow the steps above." -ForegroundColor Green
Write-Host ""
