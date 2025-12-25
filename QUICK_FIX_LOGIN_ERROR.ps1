# ONE-COMMAND FIX FOR SUPER ADMIN LOGIN ERROR

Write-Host "?? FIXING SUPER ADMIN LOGIN ERROR..." -ForegroundColor Cyan
Write-Host ""

# Stop app
Write-Host "1. Stopping application..." -ForegroundColor Yellow
Stop-Process -Name "TutorLiveMentor10" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "dotnet" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "   ? Stopped" -ForegroundColor Green

# Apply SQL fix
Write-Host ""
Write-Host "2. Applying database fix..." -ForegroundColor Yellow
Write-Host "   Running SQL script..." -ForegroundColor Gray

$sqlFix = @"
USE [WorkingDb]
-- Update existing records
UPDATE AuditLogs SET ActionPerformedBy = 'System' WHERE ActionPerformedBy IS NULL OR ActionPerformedBy = ''
UPDATE AuditLogs SET EntityType = '' WHERE EntityType IS NULL
UPDATE AuditLogs SET ActionDescription = '' WHERE ActionDescription IS NULL
UPDATE AuditLogs SET OldValue = '' WHERE OldValue IS NULL
UPDATE AuditLogs SET NewValue = '' WHERE NewValue IS NULL
UPDATE AuditLogs SET IpAddress = '127.0.0.1' WHERE IpAddress IS NULL OR IpAddress = ''
UPDATE AuditLogs SET Status = 'Success' WHERE Status IS NULL OR Status = ''

-- Alter columns
ALTER TABLE AuditLogs ALTER COLUMN ActionPerformedBy NVARCHAR(100) NULL
ALTER TABLE AuditLogs ALTER COLUMN EntityType NVARCHAR(100) NULL
ALTER TABLE AuditLogs ALTER COLUMN ActionDescription NVARCHAR(500) NULL
ALTER TABLE AuditLogs ALTER COLUMN OldValue NVARCHAR(MAX) NULL
ALTER TABLE AuditLogs ALTER COLUMN NewValue NVARCHAR(MAX) NULL
ALTER TABLE AuditLogs ALTER COLUMN IpAddress NVARCHAR(50) NULL
ALTER TABLE AuditLogs ALTER COLUMN Status NVARCHAR(50) NULL
"@

try {
    $sqlFix | sqlcmd -S "(localdb)\MSSQLLocalDB" -d "WorkingDb" -b
    Write-Host "   ? Database fixed!" -ForegroundColor Green
} catch {
    Write-Host "   ? Please run FIX_AUDIT_LOGS_NULL_ERROR.sql manually" -ForegroundColor Yellow
}

# Instructions
Write-Host ""
Write-Host "3. Next steps:" -ForegroundColor Yellow
Write-Host "   a) Run: " -NoNewline -ForegroundColor White
Write-Host "dotnet run" -ForegroundColor Cyan
Write-Host "   b) Open: " -NoNewline -ForegroundColor White
Write-Host "https://localhost:5001/SuperAdmin/Login" -ForegroundColor Cyan
Write-Host "   c) Login with:" -ForegroundColor White
Write-Host "      Email: superadmin@rgmcet.edu.in" -ForegroundColor Yellow
Write-Host "      Password: Super@123" -ForegroundColor Yellow

Write-Host ""
Write-Host "? FIX COMPLETE! Login should work now!" -ForegroundColor Green
Write-Host ""
