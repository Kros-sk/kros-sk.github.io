<#
.SYNOPSIS
Install winget on the machine.

.DESCRIPTION
This script installs winget on the machine. 
On Windows servers, winget is not installed by default. 
This script downloads and installs Microsoft.UI.Xaml and Microsoft.DesktopAppInstaller.WinGet.
Choose the version of winget to install by providing the version number as a parameter and its license file name.
https://github.com/microsoft/winget-cli/releases

.PARAMETER wingetVersion
Version of winget to install. Default is "1.8.1911".
.PARAMETER winGetLicenseFileName
Name of the license file for the winget version. Default is "76fba573f02545629706ab99170237bc_License1.xml" for version "1.8.1911".
#>
param (
	[Parameter(Mandatory = $false)][string]$wingetVersion = "1.8.1911",
    [Parameter(Mandatory = $false)][string]$winGetLicenseFileName = "76fba573f02545629706ab99170237bc_License1.xml"
)

$WinGetVer=$wingetVersion
$WinGetLicenseFile=$winGetLicenseFileName

$ProgressPreference = 'SilentlyContinue'

Invoke-WebRequest -Uri https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.7 -OutFile $env:TEMP\Microsoft.UI.Xaml.zip
Expand-Archive -Path $env:TEMP\Microsoft.UI.Xaml.zip -DestinationPath $env:TEMP\Microsoft.UI.Xaml -force
Add-AppxPackage -Path $env:TEMP\Microsoft.UI.Xaml\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.8.appx

Write-Host "Running url: https://github.com/microsoft/winget-cli/releases/download/v$WinGetVer/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle "
Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/v$WinGetVer/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile $env:TEMP\Microsoft.DesktopAppInstaller.WinGet.appx
Write-Host "Running url: https://github.com/microsoft/winget-cli/releases/download/v$WinGetVer/$WinGetLicenseFile"
Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/v$WinGetVer/$WinGetLicenseFile" -OutFile $env:TEMP\license.xml
Add-AppxProvisionedPackage -Online -PackagePath $env:TEMP\Microsoft.DesktopAppInstaller.WinGet.appx -LicensePath $env:TEMP\license.xml

$windowsAppsPath = "C:\Program Files\WindowsApps"
Write-Host "Adding permissions to $windowsAppsPath for $env:USERNAME..."
icacls $windowsAppsPath /grant "$env:USERNAME:F" /t /c /q

Write-Host "Looking for winget executable..."
$possiblePaths = @(
    "$env:LOCALAPPDATA\Microsoft\WindowsApps",
    "C:\Program Files\WindowsApps"
)
$wingetExe = $possiblePaths | ForEach-Object { Get-ChildItem -Path $_ -Filter "winget.exe" -Recurse -ErrorAction SilentlyContinue } | Select-Object -First 1 -ExpandProperty FullName

if ($wingetExe) {
    Write-Host "Winget executable found at $wingetExe."
    $wingetPath = [System.IO.Path]::GetDirectoryName($wingetExe)
    $existingPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)

    if ($existingPath -notlike "*$wingetPath*") {
        Write-Host "Adding winget to system PATH ($wingetPath)..."
        [System.Environment]::SetEnvironmentVariable("Path", "$existingPath;$wingetPath", [System.EnvironmentVariableTarget]::Machine)
    } else {
        Write-Host "Winget is already in the system PATH."
    }
} else {
    Write-Host "Winget executable not found. Check the installation."
}