@echo off
echo ========================================
echo Deploy Firebase Storage Rules
echo ========================================
echo.

echo Deploying Storage rules to Firebase...
firebase deploy --only storage

if %ERRORLEVEL% == 0 (
    echo.
    echo ========================================
    echo SUCCESS! Storage rules deployed
    echo ========================================
) else (
    echo.
    echo ========================================
    echo ERROR! Failed to deploy storage rules
    echo Please make sure:
    echo 1. Firebase CLI is installed
    echo 2. You are logged in (firebase login)
    echo 3. Firebase project is initialized
    echo ========================================
)

pause
