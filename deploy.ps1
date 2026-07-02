Write-Host "Copiando arquivo do Desktop..." -ForegroundColor Cyan
Copy-Item "C:\Users\maste\OneDrive\Desktop\CF\index.html.html" "C:\Users\maste\controle-lrc\index.html" -Force

Set-Location "C:\Users\maste\controle-lrc"

Write-Host "Commitando no GitHub..." -ForegroundColor Cyan
git add index.html
$msg = "Deploy $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
git commit -m $msg
git push

Write-Host "Fazendo deploy no Cloudflare Pages..." -ForegroundColor Cyan
wrangler pages deploy . --project-name=controle-lrc --branch=main

Write-Host "Deploy concluido! Site: https://controle-lrc.pages.dev" -ForegroundColor Green
