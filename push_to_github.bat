@echo off
title Push SonicPulse to GitHub
cd /d "%~dp0"

echo ========================================================
echo   Pushing SonicPulse Android to GitHub for Cloud APK Build
echo ========================================================
echo.

git remote remove origin 2>nul
git remote add origin https://github.com/WalidBenmaou/sonicpulse-android.git
git branch -M main

echo [*] Pushing code to GitHub...
git push -u origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo [OK] SUCCESS! Your code is uploaded to GitHub!
    echo.
    echo GitHub Actions is now compiling your APK in the cloud.
    echo In ~2 minutes, open this link on your phone or PC:
    echo https://github.com/WalidBenmaou/sonicpulse-android/actions
    echo ========================================================
) else (
    echo.
    echo [!] Push failed. 
    echo Please make sure:
    echo 1. You opened https://github.com/new and created the repository 'sonicpulse-android'.
    echo 2. You are logged into GitHub.
)
echo.
pause
