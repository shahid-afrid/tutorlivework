# Documentation Cleanup Script
# This script removes redundant MD files while keeping essential ones

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Documentation Cleanup Script" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Files to KEEP (essential documentation)
$filesToKeep = @(
    "README.md",
    "COMPREHENSIVE_DOCUMENTATION.md",
    "PROJECT_SUMMARY.md"
)

# Get all MD files in current directory
$allMdFiles = Get-ChildItem -Path . -Filter *.md -File | Where-Object { $_.Name -notin $filesToKeep }

Write-Host "Found $($allMdFiles.Count) documentation files to review" -ForegroundColor Yellow
Write-Host ""

# Group files by category for review
$categories = @{
    "Faculty" = @()
    "Modal" = @()
    "Subject" = @()
    "Enrollment" = @()
    "Azure" = @()
    "Admin" = @()
    "Student" = @()
    "Other" = @()
}

foreach ($file in $allMdFiles) {
    $name = $file.Name
    
    if ($name -like "*FACULTY*") { $categories["Faculty"] += $file }
    elseif ($name -like "*MODAL*") { $categories["Modal"] += $file }
    elseif ($name -like "*SUBJECT*") { $categories["Subject"] += $file }
    elseif ($name -like "*ENROLLMENT*") { $categories["Enrollment"] += $file }
    elseif ($name -like "*AZURE*" -or $name -like "*DEPLOYMENT*") { $categories["Azure"] += $file }
    elseif ($name -like "*ADMIN*") { $categories["Admin"] += $file }
    elseif ($name -like "*STUDENT*") { $categories["Student"] += $file }
    else { $categories["Other"] += $file }
}

# Display files by category
Write-Host "Files organized by category:" -ForegroundColor Green
Write-Host ""

foreach ($category in $categories.Keys | Sort-Object) {
    $files = $categories[$category]
    if ($files.Count -gt 0) {
        Write-Host "[$category] - $($files.Count) files" -ForegroundColor Cyan
        foreach ($file in $files) {
            Write-Host "  - $($file.Name)" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Files that will be KEPT:" -ForegroundColor Green
foreach ($file in $filesToKeep) {
    Write-Host "  ? $file" -ForegroundColor Green
}
Write-Host ""

# Ask for confirmation
Write-Host "==================================" -ForegroundColor Yellow
Write-Host "WARNING: This will DELETE $($allMdFiles.Count) files!" -ForegroundColor Yellow
Write-Host "All content has been consolidated into COMPREHENSIVE_DOCUMENTATION.md" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "Do you want to proceed? (yes/no)"

if ($confirmation -eq "yes") {
    Write-Host ""
    Write-Host "Deleting files..." -ForegroundColor Yellow
    
    $deletedCount = 0
    foreach ($file in $allMdFiles) {
        try {
            Remove-Item $file.FullName -Force
            Write-Host "  ? Deleted: $($file.Name)" -ForegroundColor Gray
            $deletedCount++
        }
        catch {
            Write-Host "  ? Failed to delete: $($file.Name)" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "Cleanup Complete!" -ForegroundColor Green
    Write-Host "Deleted: $deletedCount files" -ForegroundColor Green
    Write-Host "Kept: $($filesToKeep.Count) essential files" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your documentation is now in:" -ForegroundColor Cyan
    Write-Host "  - COMPREHENSIVE_DOCUMENTATION.md (All consolidated docs)" -ForegroundColor Cyan
    Write-Host "  - README.md (Quick start guide)" -ForegroundColor Cyan
    Write-Host "  - PROJECT_SUMMARY.md (Project overview)" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "Cleanup cancelled. No files were deleted." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
