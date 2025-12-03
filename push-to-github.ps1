# Push Year 2 Enrollment Fix to GitHub Repository
# This script commits and pushes all changes to the main branch

Write-Host "=== GitHub Push Script ===" -ForegroundColor Cyan
Write-Host ""

# Navigate to repository root
Set-Location "C:\Users\shahi\Source\Repos\tutor-livev1"

# Check Git status
Write-Host "Checking Git status..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "=== Staging all changes ===" -ForegroundColor Yellow
git add .

Write-Host ""
Write-Host "=== Creating commit ===" -ForegroundColor Yellow
$commitMessage = @"
Fix Year 2 Enrollment Limit Issue

- Applied database migrations for MaxEnrollments column
- Updated Year 2 subjects to have MaxEnrollments=60
- Fixed enrollment limit enforcement logic
- Added verification scripts and documentation
- Completed all pending fixes and standardizations
"@

git commit -m $commitMessage

Write-Host ""
Write-Host "=== Pushing to GitHub (origin/main) ===" -ForegroundColor Yellow
git push origin main

Write-Host ""
if ($LASTEXITCODE -eq 0) {
    Write-Host "=== SUCCESS: Code pushed to GitHub! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Repository: https://github.com/shahid-afrid/tutorlivework" -ForegroundColor Cyan
    Write-Host "Branch: main" -ForegroundColor Cyan
} else {
    Write-Host "=== ERROR: Push failed! ===" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "1. Need to pull first: git pull origin main" -ForegroundColor White
    Write-Host "2. Authentication required: Check your GitHub credentials" -ForegroundColor White
    Write-Host "3. Branch protection: May need to create a pull request" -ForegroundColor White
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
