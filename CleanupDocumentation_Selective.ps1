# Selective Documentation Cleanup Script
# Keeps: Azure guides, Scripts (.ps1, .bat), Essential docs
# Deletes: Only redundant fix/implementation docs

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Selective Documentation Cleanup" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Files to KEEP (will NOT be deleted)
$filesToKeep = @(
    # Essential Documentation
    "README.md",
    "COMPREHENSIVE_DOCUMENTATION.md",
    "QUICK_REFERENCE.md",
    "DOCUMENTATION_CONSOLIDATION_SUMMARY.md",
    "_START_HERE_DOCUMENTATION_CLEANUP.md",
    "PROJECT_SUMMARY.md",
    
    # Azure Deployment Guides (KEEP ALL)
    "COMPLETE_AZURE_DEPLOYMENT_GUIDE.md",
    "AZURE_DEPLOYMENT_ADMIN_GUIDE.md",
    "AZURE_HEALTH_CHECK_SETUP.md",
    "AZURE_QUICK_REFERENCE.md",
    "DEPLOYMENT_READINESS_REPORT.md",
    "HEALTH_CHECKS_GUIDE.md",
    
    # Scripts (KEEP ALL - these are NOT deleted)
    "CleanupDocumentation.ps1",
    "CleanupDocumentation_Selective.ps1"
)

# Get all MD files
$allMdFiles = Get-ChildItem -Path . -Filter *.md -File

# Separate into keep and delete
$filesToDelete = $allMdFiles | Where-Object { $_.Name -notin $filesToKeep }

Write-Host "Total MD files found: $($allMdFiles.Count)" -ForegroundColor Cyan
Write-Host "Files to KEEP: $($filesToKeep.Count)" -ForegroundColor Green
Write-Host "Files to DELETE: $($filesToDelete.Count)" -ForegroundColor Yellow
Write-Host ""

# Group files to delete by category
$categories = @{
    "Faculty Management" = @()
    "Modal Fixes" = @()
    "Subject Management" = @()
    "Student Enrollment" = @()
    "Admin Features" = @()
    "UI/Reports" = @()
    "Other" = @()
}

foreach ($file in $filesToDelete) {
    $name = $file.Name
    
    if ($name -like "*FACULTY*") { 
        $categories["Faculty Management"] += $file 
    }
    elseif ($name -like "*MODAL*") { 
        $categories["Modal Fixes"] += $file 
    }
    elseif ($name -like "*SUBJECT*" -or $name -like "*ELECTIVE*") { 
        $categories["Subject Management"] += $file 
    }
    elseif ($name -like "*ENROLLMENT*" -or $name -like "*STUDENT*") { 
        $categories["Student Enrollment"] += $file 
    }
    elseif ($name -like "*ADMIN*") { 
        $categories["Admin Features"] += $file 
    }
    elseif ($name -like "*UI*" -or $name -like "*REPORT*" -or $name -like "*COMPARISON*") { 
        $categories["UI/Reports"] += $file 
    }
    else { 
        $categories["Other"] += $file 
    }
}

Write-Host "Files to DELETE (by category):" -ForegroundColor Red
Write-Host ""

foreach ($category in $categories.Keys | Sort-Object) {
    $files = $categories[$category]
    if ($files.Count -gt 0) {
        Write-Host "[$category] - $($files.Count) files" -ForegroundColor Yellow
        foreach ($file in $files) {
            Write-Host "  ? $($file.Name)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Files that will be KEPT:" -ForegroundColor Green
Write-Host ""

Write-Host "[Essential Documentation]" -ForegroundColor Cyan
Write-Host "  ? README.md" -ForegroundColor Green
Write-Host "  ? COMPREHENSIVE_DOCUMENTATION.md" -ForegroundColor Green
Write-Host "  ? QUICK_REFERENCE.md" -ForegroundColor Green
Write-Host "  ? DOCUMENTATION_CONSOLIDATION_SUMMARY.md" -ForegroundColor Green
Write-Host "  ? _START_HERE_DOCUMENTATION_CLEANUP.md" -ForegroundColor Green
if (Test-Path "PROJECT_SUMMARY.md") {
    Write-Host "  ? PROJECT_SUMMARY.md" -ForegroundColor Green
}
Write-Host ""

Write-Host "[Azure Deployment Guides - ALL KEPT]" -ForegroundColor Cyan
$azureFiles = $filesToKeep | Where-Object { $_ -like "*AZURE*" -or $_ -like "*DEPLOYMENT*" -or $_ -like "*HEALTH*" }
foreach ($file in $azureFiles) {
    if (Test-Path $file) {
        Write-Host "  ? $file" -ForegroundColor Green
    }
}
Write-Host ""

Write-Host "[Scripts - ALL .ps1 and .bat files are KEPT]" -ForegroundColor Cyan
$scriptFiles = Get-ChildItem -Path . -Include *.ps1,*.bat -File
foreach ($file in $scriptFiles) {
    Write-Host "  ? $($file.Name)" -ForegroundColor Green
}
Write-Host ""

# Ask for confirmation
Write-Host "==================================" -ForegroundColor Yellow
Write-Host "??  WARNING: This will DELETE $($filesToDelete.Count) redundant documentation files!" -ForegroundColor Yellow
Write-Host ""
Write-Host "?  All Azure guides will be KEPT" -ForegroundColor Green
Write-Host "?  All scripts (.ps1, .bat) will be KEPT" -ForegroundColor Green
Write-Host "?  Essential documentation will be KEPT" -ForegroundColor Green
Write-Host ""
Write-Host "?  Only redundant fix/implementation docs will be DELETED" -ForegroundColor Red
Write-Host ""
$confirmation = Read-Host "Do you want to proceed? (yes/no)"

if ($confirmation -eq "yes") {
    Write-Host ""
    Write-Host "Deleting redundant files..." -ForegroundColor Yellow
    Write-Host ""
    
    $deletedCount = 0
    $failedCount = 0
    
    foreach ($file in $filesToDelete) {
        try {
            Remove-Item $file.FullName -Force
            Write-Host "  ? Deleted: $($file.Name)" -ForegroundColor Gray
            $deletedCount++
        }
        catch {
            Write-Host "  ? Failed to delete: $($file.Name)" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Red
            $failedCount++
        }
    }
    
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "Cleanup Complete!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? Statistics:" -ForegroundColor Cyan
    Write-Host "  ? Successfully deleted: $deletedCount files" -ForegroundColor Green
    if ($failedCount -gt 0) {
        Write-Host "  ? Failed to delete: $failedCount files" -ForegroundColor Red
    }
    Write-Host "  ?? Files remaining: $($filesToKeep.Count + $scriptFiles.Count) files" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? Your documentation structure:" -ForegroundColor Cyan
    Write-Host "  ?? Essential Docs (5 files)" -ForegroundColor White
    Write-Host "  ?  ?? README.md" -ForegroundColor Gray
    Write-Host "  ?  ?? COMPREHENSIVE_DOCUMENTATION.md" -ForegroundColor Gray
    Write-Host "  ?  ?? QUICK_REFERENCE.md" -ForegroundColor Gray
    Write-Host "  ?? Azure Guides (6 files)" -ForegroundColor White
    Write-Host "  ?  ?? COMPLETE_AZURE_DEPLOYMENT_GUIDE.md" -ForegroundColor Gray
    Write-Host "  ?  ?? Other Azure guides..." -ForegroundColor Gray
    Write-Host "  ?? Scripts ($($scriptFiles.Count) files)" -ForegroundColor White
    foreach ($script in $scriptFiles | Select-Object -First 3) {
        Write-Host "     ?? $($script.Name)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "? Your workspace is now clean and organized!" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "? Cleanup cancelled. No files were deleted." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
