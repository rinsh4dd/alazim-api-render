@echo off
setlocal

set "MSG=%~1"
if "%MSG%"=="" set "MSG=Auto commit and push"

echo ========================================================
echo   Pushing to both TSForceTech (admin) and Render
echo   Commit Message: "%MSG%"
echo ========================================================

git add -A
git commit -m "%MSG%"

echo.
echo [1/2] Pushing to admin (tsforcetech/al_azima_backend)...
git push admin main
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to push to admin remote.
)

echo.
echo [2/2] Pushing to render (rinsh4dd/alazim-api-render)...
git push render main
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to push to render remote.
)

echo.
echo ========================================================
echo   Done! Both remotes updated.
echo ========================================================
