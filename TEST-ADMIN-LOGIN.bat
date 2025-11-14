@echo off
title TutorLiveMentor - Admin Login Test
color 0A
cls

echo.
echo ==========================================
echo   TutorLiveMentor - Admin Login Test
echo ==========================================
echo.
echo This will start your application and open
echo the admin login page.
echo.
echo ADMIN CREDENTIALS:
echo   Email:    cseds@rgmcet.edu.in
echo   Password: 9059530688
echo.
echo ==========================================
echo.
echo Starting application...
echo.

REM Start application
start "TutorLiveMentor" cmd /k "dotnet run"

echo Waiting for application to start (15 seconds)...
timeout /t 15 /nobreak >nul

echo.
echo Opening admin login page...
start http://localhost:5000/Admin/Login

echo.
echo ==========================================
echo   APPLICATION RUNNING!
echo ==========================================
echo.
echo The admin login page should open in your browser.
echo.
echo LOGIN WITH:
echo   Email:    cseds@rgmcet.edu.in  
echo   Password: 9059530688
echo.
echo To stop the application, close the other window.
echo.
echo ==========================================
echo.
pause
