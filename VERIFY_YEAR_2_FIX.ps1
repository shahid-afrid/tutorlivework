# VERIFY YEAR 2 LIMIT FIX
# Run this AFTER you apply the migration

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  YEAR 2 ENROLLMENT LIMIT - VERIFICATION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if app is running
$appProcess = Get-Process -Name "TutorLiveMentor10" -ErrorAction SilentlyContinue
if ($appProcess) {
    Write-Host "??  WARNING: Application is RUNNING!" -ForegroundColor Yellow
    Write-Host "   Process ID: $($appProcess.Id)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   You MUST stop the app before running migrations!" -ForegroundColor Yellow
    Write-Host "   Press Shift+F5 in Visual Studio to stop." -ForegroundColor Yellow
    Write-Host ""
    exit
}

Write-Host "? App is not running - Good!" -ForegroundColor Green
Write-Host ""

# Check database schema
Write-Host "Checking database schema..." -ForegroundColor Yellow
Write-Host ""

$schemaCheck = @"
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Subjects' 
ORDER BY ORDINAL_POSITION;
"@

try {
    $columns = sqlcmd -S "localhost" -d "Working5Db" -Q $schemaCheck -h -1 -W
    
    if ($columns -match "MaxEnrollments") {
        Write-Host "? MaxEnrollments column EXISTS in database!" -ForegroundColor Green
        Write-Host ""
        
        # Check Year 2 subject limits
        Write-Host "Checking Year 2 subject limits..." -ForegroundColor Yellow
        Write-Host ""
        
        $limitCheck = @"
SELECT 
    s.Name AS SubjectName,
    s.Year,
    s.SubjectType,
    s.MaxEnrollments,
    COUNT(DISTINCT se.StudentId) AS CurrentEnrollments
FROM 
    Subjects s
    LEFT JOIN AssignedSubjects asub ON s.SubjectId = asub.SubjectId
    LEFT JOIN StudentEnrollments se ON asub.AssignedSubjectId = se.AssignedSubjectId
WHERE 
    s.Year = 2 
    AND s.SubjectType = 'Core'
GROUP BY 
    s.SubjectId, s.Name, s.Year, s.SubjectType, s.MaxEnrollments
ORDER BY 
    s.Name;
"@
        
        $results = sqlcmd -S "localhost" -d "Working5Db" -Q $limitCheck
        Write-Host $results
        Write-Host ""
        
        # Check if any Year 2 subjects are missing MaxEnrollments
        $missingLimits = @"
SELECT COUNT(*) AS MissingCount
FROM Subjects
WHERE Year = 2 
  AND SubjectType = 'Core'
  AND MaxEnrollments IS NULL;
"@
        
        $missing = sqlcmd -S "localhost" -d "Working5Db" -Q $missingLimits -h -1 -W
        $missingCount = [int]($missing -replace '\s+','')
        
        if ($missingCount -gt 0) {
            Write-Host "?  WARNING: $missingCount Year 2 subjects are missing MaxEnrollments!" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   Run this SQL to fix it:" -ForegroundColor Yellow
            Write-Host "   UPDATE Subjects SET MaxEnrollments = 60 WHERE Year = 2 AND SubjectType = 'Core';" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "? All Year 2 subjects have MaxEnrollments set!" -ForegroundColor Green
            Write-Host ""
        }
        
        # Check if any are set to wrong value (should be 60, not 70)
        $wrongLimit = @"
SELECT COUNT(*) AS WrongCount
FROM Subjects
WHERE Year = 2 
  AND SubjectType = 'Core'
  AND MaxEnrollments != 60;
"@
        
        $wrong = sqlcmd -S "localhost" -d "Working5Db" -Q $wrongLimit -h -1 -W
        $wrongCount = [int]($wrong -replace '\s+','')
        
        if ($wrongCount -gt 0) {
            Write-Host "?  WARNING: $wrongCount Year 2 subjects have WRONG limit (should be 60)!" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   Run this SQL to fix it:" -ForegroundColor Yellow
            Write-Host "   UPDATE Subjects SET MaxEnrollments = 60 WHERE Year = 2 AND SubjectType = 'Core';" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "? All Year 2 subjects have correct limit (60)!" -ForegroundColor Green
            Write-Host ""
        }
        
    } else {
        Write-Host "? MaxEnrollments column DOES NOT EXIST!" -ForegroundColor Red
        Write-Host ""
        Write-Host "   Database schema is OUTDATED!" -ForegroundColor Red
        Write-Host ""
        Write-Host "   You MUST run the migration first:" -ForegroundColor Yellow
        Write-Host "   1. Stop the application (Shift+F5)" -ForegroundColor White
        Write-Host "   2. Run in Package Manager Console:" -ForegroundColor White
        Write-Host "      Update-Database -Verbose" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   OR in Command Prompt:" -ForegroundColor White
        Write-Host "      dotnet ef database update" -ForegroundColor Cyan
        Write-Host ""
    }
    
} catch {
    Write-Host "? ERROR: Could not connect to database!" -ForegroundColor Red
    Write-Host "   $_" -ForegroundColor Red
    Write-Host ""
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
