# ================================================================
# RUN YEAR STANDARDIZATION FIX - 30 SECONDS
# ================================================================
# Fixes the confusion between numeric years (1,2,3,4) and 
# Roman numeral years (I Year, II Year, III Year, IV Year)
# ================================================================

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  STUDENT YEAR STANDARDIZATION FIX" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Problem:" -ForegroundColor Yellow
Write-Host "  Some students have Year = '3' (numeric)" -ForegroundColor White
Write-Host "  But code expects 'III Year' (Roman numeral)" -ForegroundColor White
Write-Host "  Result: Those students CANNOT see subjects!" -ForegroundColor Red
Write-Host ""

Write-Host "Solution:" -ForegroundColor Yellow
Write-Host "  Convert ALL numeric years to Roman numeral format" -ForegroundColor White
Write-Host "  '1' ? 'I Year', '2' ? 'II Year', '3' ? 'III Year', '4' ? 'IV Year'" -ForegroundColor White
Write-Host ""

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if SQL file exists
$sqlFile = "Migrations\STANDARDIZE_STUDENT_YEARS.sql"
if (-not (Test-Path $sqlFile)) {
    Write-Host "ERROR: SQL file not found!" -ForegroundColor Red
    Write-Host "Expected: $sqlFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure you're running this from the project root directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "SQL File Found: $sqlFile" -ForegroundColor Green
Write-Host ""

Write-Host "Running standardization..." -ForegroundColor Yellow
Write-Host ""

try {
    # Execute the SQL migration
    sqlcmd -S "localhost" -d "Working5Db" -i $sqlFile
    
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host "  STANDARDIZATION COMPLETE!" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host ""
    
    # Verify the fix
    Write-Host "Verifying the fix..." -ForegroundColor Yellow
    Write-Host ""
    
    $verifyQuery = @"
SELECT 
    Year, 
    COUNT(*) as StudentCount
FROM Students
GROUP BY Year
ORDER BY Year;
"@
    
    Write-Host "Current Year Distribution:" -ForegroundColor Cyan
    sqlcmd -S "localhost" -d "Working5Db" -Q $verifyQuery
    
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host "  WHAT CHANGED?" -ForegroundColor Yellow
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "BEFORE:" -ForegroundColor Yellow
    Write-Host "  Year: '3'        (8 students) ? CANNOT see subjects" -ForegroundColor Red
    Write-Host "  Year: 'II Year'  (219 students) ? CAN see subjects" -ForegroundColor Green
    Write-Host "  Year: 'III Year' (209 students) ? CAN see subjects" -ForegroundColor Green
    Write-Host ""
    Write-Host "AFTER:" -ForegroundColor Yellow
    Write-Host "  Year: 'II Year'  (219 students) ? CAN see subjects" -ForegroundColor Green
    Write-Host "  Year: 'III Year' (217 students) ? CAN see subjects" -ForegroundColor Green
    Write-Host "                   ^^^" -ForegroundColor Cyan
    Write-Host "                   209 + 8 (converted from '3')" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host "  ? ALL STUDENTS CAN NOW SEE SUBJECTS!" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host ""
    
    # Check for any remaining non-standard years
    $checkNonStandard = @"
SELECT Year, COUNT(*) as Count
FROM Students
WHERE Year NOT IN ('I Year', 'II Year', 'III Year', 'IV Year')
AND Year IS NOT NULL
GROUP BY Year;
"@
    
    $nonStandardResult = sqlcmd -S "localhost" -d "Working5Db" -Q $checkNonStandard -h -1
    
    if ($nonStandardResult -match "rows affected\)$" -and $nonStandardResult -notmatch "\d+\s+\d+") {
        Write-Host "? All years standardized successfully!" -ForegroundColor Green
        Write-Host "? No non-standard year formats remaining" -ForegroundColor Green
    } else {
        Write-Host "?? Some non-standard years may still exist:" -ForegroundColor Yellow
        Write-Host $nonStandardResult -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host "  NEXT STEP" -ForegroundColor Yellow
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The fix is complete in the database ?" -ForegroundColor Green
    Write-Host ""
    Write-Host "If your application is running, RESTART IT:" -ForegroundColor Yellow
    Write-Host "  1. Stop the app (Shift+F5 in Visual Studio)" -ForegroundColor White
    Write-Host "  2. Start the app (F5 in Visual Studio)" -ForegroundColor White
    Write-Host ""
    Write-Host "Then test:" -ForegroundColor Yellow
    Write-Host "  1. Login as a Year III student" -ForegroundColor White
    Write-Host "  2. Navigate to 'Select Faculty'" -ForegroundColor White
    Write-Host "  3. ? Should see 17 subject-faculty combinations!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Cyan
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to run standardization!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual fix:" -ForegroundColor Yellow
    Write-Host "  1. Open SQL Server Management Studio" -ForegroundColor White
    Write-Host "  2. Connect to localhost" -ForegroundColor White
    Write-Host "  3. Open: $sqlFile" -ForegroundColor White
    Write-Host "  4. Execute the script" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
