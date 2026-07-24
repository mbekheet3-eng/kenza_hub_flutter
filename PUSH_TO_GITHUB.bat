@echo off
REM ============================================
REM Kenza Hub Flutter - Push to GitHub Script (Windows)
REM ============================================
REM 
REM Double-click this file to push to GitHub
REM Or run in Command Prompt:
REM   PUSH_TO_GITHUB.bat
REM ============================================

setlocal enabledelayedexpansion

cls
echo.
echo 🚀 Kenza Hub Flutter - GitHub Push Script (Windows)
echo ==============================================
echo.

REM Step 1: Check if git is installed
git --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Git is not installed!
    echo Please download and install from: https://git-scm.com/download/win
    pause
    exit /b 1
)

echo ✅ Git found
echo.

REM Step 2: Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Error: pubspec.yaml not found!
    echo Please run this script from kenza_hub_flutter directory
    pause
    exit /b 1
)

echo ✅ In correct directory
echo.

REM Step 3: Check if .git exists
if not exist ".git" (
    echo ⚠️  Git repository not found. Initializing...
    git init
    git config user.name "Kenza Hub Developer"
    git config user.email "kenza@example.com"
    git add .
    git commit -m "Initial commit: Kenza Hub Flutter Phase 1"
    echo ✅ Git repository initialized
) else (
    echo ✅ Git repository exists
)

echo.
echo ==============================================
echo NEXT STEP: Connect to GitHub
echo ==============================================
echo.
echo Your GitHub repository URL:
echo https://github.com/mbekheet3-eng/kenza_hub_flutter
echo.
echo About to run:
echo   git branch -M main
echo   git remote add origin https://github.com/mbekheet3-eng/kenza_hub_flutter.git
echo   git push -u origin main
echo.
pause

REM Step 4: Set branch to main
cls
echo.
echo Renaming branch to main...
git branch -M main
if errorlevel 1 goto error
echo ✅ Branch renamed to main
echo.

REM Step 5: Add remote origin
echo Adding remote origin...
git remote add origin https://github.com/mbekheet3-eng/kenza_hub_flutter.git 2>nul
echo ✅ Remote origin configured
echo.

REM Step 6: Push to GitHub
echo ==============================================
echo Pushing to GitHub...
echo ==============================================
echo.
echo You may be prompted for credentials:
echo - GitHub username
echo - Personal Access Token (NOT password)
echo.
echo To create a token: https://github.com/settings/tokens
echo.
pause

git push -u origin main

if errorlevel 1 goto error

echo.
echo ==============================================
echo ✅ SUCCESS!
echo ==============================================
echo.
echo Your project is now on GitHub:
echo https://github.com/mbekheet3-eng/kenza_hub_flutter
echo.
echo Next steps:
echo 1. Visit the repository URL above
echo 2. Read README.md
echo 3. Read MIGRATION_REPORT.md (current status)
echo 4. Read PROJECT_ROADMAP.md (future plans)
echo 5. Schedule team review meeting
echo.
echo Happy coding! 🚀
echo.
pause
exit /b 0

:error
echo.
echo ==============================================
echo ❌ PUSH FAILED
echo ==============================================
echo.
echo Possible reasons:
echo 1. Network issues
echo 2. Invalid credentials
echo 3. Repository URL incorrect
echo.
echo Try again with:
echo   git push -u origin main
echo.
pause
exit /b 1
