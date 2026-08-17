param (
    [string]$Message = "Auto commit and push"
)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  Pushing to both TSForceTech (admin) and Render" -ForegroundColor Cyan
Write-Host "  Commit Message: $Message" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan

git add -A
git commit -m "$Message"

Write-Host "`n[1/2] Pushing to admin (tsforcetech/al_azima_backend)..." -ForegroundColor Green
git push admin main

Write-Host "`n[2/2] Pushing to render (rinsh4dd/alazim-api-render)..." -ForegroundColor Green
git push render main

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  Done! Both remotes updated." -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
