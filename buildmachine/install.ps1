#Requires -RunAsAdministrator

param (
	[Parameter()][string]$WingetJsonPath = ""
)

if ([string]::IsNullOrWhiteSpace($WingetJsonPath)) {
	$WingetJsonPath = [IO.Path]::ChangeExtension($PSCommandPath, "json")
}
Write-Host "JSON file with packages to install is '$WingetJsonPath'."
if (-not (Test-Path $WingetJsonPath)) {
	Write-Host "JSON file with packages to install not found. Exiting." -ForegroundColor Red
	exit 1
}

Write-Host "Installing packages from JSON file." -ForegroundColor Green
$json = Get-Content -Raw -Path $WingetJsonPath | ConvertFrom-Json
$json.Sources | ForEach-Object {
	$source = $_
	$source.Packages | ForEach-Object {
		$packageId = $_.PackageIdentifier
		Write-Host "Installing package '$packageId'" -ForegroundColor Yellow
		winget install --id $packageId --exact --scope machine
		Write-Host
	}
}

# Azure CLI can also be installed using WinGet, but it was very unreliable – the installation often failed.
Write-Host "Installing Azure CLI" -ForegroundColor Green
$ProgressPreference = 'SilentlyContinue'
Write-Host "Download Azure CLI installer."
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindowsx64 -OutFile .\AzureCLI.msi
Write-Host "Execute Azure CLI installer."
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
Write-Host "Remove Azure CLI installer."
Remove-Item .\AzureCLI.msi
Write-Host
