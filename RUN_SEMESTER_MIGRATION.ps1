# ============================================
# RUN SEMESTER MIGRATION - QUICK SCRIPT
# ============================================
# This script runs the Semester column migration
# for the TutorLiveMentor database
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   SEMESTER MIGRATION SCRIPT" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$Server = "(LocalDb)\MSSQLLocalDB"
$Database = "TutorLiveMentor"
$MigrationScript = "Migrations\AddSemesterToStudents.sql"

# Check if migration script exists
if (-not (Test-Path $MigrationScript)) {
    Write-Host "ERROR: Migration script not found!" -ForegroundColor Red
    Write-Host "Expected location: $MigrationScript" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please ensure you are in the project root directory." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Migration script found!" -ForegroundColor Green
Write-Host "Server: $Server" -ForegroundColor Cyan
Write-Host "Database: $Database" -ForegroundColor Cyan
Write-Host ""

# Ask for confirmation
Write-Host "This will:" -ForegroundColor Yellow
Write-Host "  1. Add 'Semester' column to Students table" -ForegroundColor White
Write-Host "  2. Set all existing students to Semester 'I'" -ForegroundColor White
Write-Host "  3. Verify the changes" -ForegroundColor White
Write-Host ""

$confirmation = Read-Host "Do you want to proceed? (Y/N)"
if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
    Write-Host "Migration cancelled." -ForegroundColor Yellow
    pause
    exit 0
}

Write-Host ""
Write-Host "Running migration..." -ForegroundColor Cyan
Write-Host ""

try {
    # Run the migration using sqlcmd
    sqlcmd -S $Server -d $Database -i $MigrationScript -o "migration-output.log"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "   MIGRATION SUCCESSFUL!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        # Display the log
        Write-Host "Migration Output:" -ForegroundColor Cyan
        Write-Host "-----------------------------------" -ForegroundColor Gray
        Get-Content "migration-output.log" | Write-Host
        Write-Host "-----------------------------------" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "Next Steps:" -ForegroundColor Yellow
        Write-Host "  1. Restart your application" -ForegroundColor White
        Write-Host "  2. Test adding a new student with Semester" -ForegroundColor White
        Write-Host "  3. Test editing an existing student's Semester" -ForegroundColor White
        Write-Host "  4. Test filtering students by Semester" -ForegroundColor White
        Write-Host ""
        
        Write-Host "Documentation: SEMESTER_FUNCTIONALITY_COMPLETE_GUIDE.md" -ForegroundColor Cyan
    } else {
        throw "sqlcmd returned error code: $LASTEXITCODE"
    }
} catch {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "   MIGRATION FAILED!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Ensure SQL Server is running" -ForegroundColor White
    Write-Host "  2. Check if database 'TutorLiveMentor' exists" -ForegroundColor White
    Write-Host "  3. Verify server name: $Server" -ForegroundColor White
    Write-Host "  4. Try running migration manually in SSMS" -ForegroundColor White
    Write-Host ""
    Write-Host "Manual Steps:" -ForegroundColor Cyan
    Write-Host "  1. Open SQL Server Management Studio (SSMS)" -ForegroundColor White
    Write-Host "  2. Connect to: $Server" -ForegroundColor White
    Write-Host "  3. Open file: $MigrationScript" -ForegroundColor White
    Write-Host "  4. Execute the script (F5)" -ForegroundColor White
}

Write-Host ""
Write-Host "Log saved to: migration-output.log" -ForegroundColor Gray
Write-Host ""
pause
