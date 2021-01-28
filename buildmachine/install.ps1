#Requires -RunAsAdministrator

Write-Host "Set execution policy to 'ByPass'" -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine

Write-Host "Install chocolatey" -ForegroundColor Yellow
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

Write-Host "Install software" -ForegroundColor Yellow
choco install buildmachine-packages.config --yes

Write-Host
Write-Host "Everything is installed. If you want install software for load testing, then run the 'install-load-tests.ps1' otherwise  run the 'configure.ps1' script." -ForegroundColor Green
