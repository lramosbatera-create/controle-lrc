Set-Location "C:\Users\maste\controle-lrc"

Write-Host "Commitando no GitHub..." -ForegroundColor Cyan
git add index.html
$msg = "Deploy $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
git commit -m $msg
git push

Write-Host "Deploy concluido! Cloudflare Pages publica automaticamente a cada push na main." -ForegroundColor Green
Write-Host "Site: https://controle-lrc.pages.dev" -ForegroundColor Green
