#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()][string]$Proxy,
	[Parameter()][string]$NewmanPath = "C:\newman",
	[Parameter()][string]$ToolsPath = "C:\tools",
	[Parameter()][string]$ScriptsPath = "C:\scripts"
)

function AddToPath([string]$path) {
	Write-Host "Add '$path' to environment variable PATH" -ForegroundColor Yellow
	$pathValue = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
	$pattern = $path.Replace("\", "\\")
	if ($pathValue -match $pattern) {
		Write-Host "  PATH variable already contains '$path'."
	}
	else {
		$pathValue = "$path;" + $pathValue
		[System.Environment]::SetEnvironmentVariable("PATH", $pathValue, [System.EnvironmentVariableTarget]::Machine)
		Write-Host "  '$path' added to PATH variable."
	}
}

function SetEnvVariable($name, $value) {
	Write-Host "Try to set environment variable '$name' to '$value'" -ForegroundColor Yellow
	$currentValue = [System.Environment]::GetEnvironmentVariable($name, [System.EnvironmentVariableTarget]::Machine)
	if ([string]::IsNullOrEmpty($currentValue)) {
		Write-Host "  Setting '$name' to '$value'"
		[System.Environment]::SetEnvironmentVariable($name, $value, [System.EnvironmentVariableTarget]::Machine)
	}
	else {
		Write-Host "  '$name' is already set to '$currentValue'. Will not change it."
	}
}


# 'tools' folder
Write-Host "Create '$ToolsPath' folder"
if (-not (Test-Path $ToolsPath)) {
	New-Item -Path $ToolsPath -ItemType Directory
}
AddToPath $ToolsPath


# Proxy environment variables
$proxyUri = $null
Write-Host "Set proxy environment variables" -ForegroundColor Green
if ([string]::IsNullOrWhiteSpace($Proxy)) {
	Write-Host "  Proxy is empty. Nothing to do."
}
else {
	$proxyUri = New-Object -TypeName System.Uri $Proxy
	Write-Host "  Proxy is $proxyUri"
	$proxyValue = $proxyUri.ToString().TrimEnd("/")
	$proxyHost = $proxyUri.Host
	$proxyPort = $proxyUri.Port

	SetEnvVariable "HTTP_PROXY" $proxyValue
	SetEnvVariable "HTTPS_PROXY" $proxyValue

	$javaHomeValue = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", [System.EnvironmentVariableTarget]::Machine)
	if ([string]::IsNullOrEmpty($javaHomeValue)) {
		Write-Host "  'JAVA_HOME' is not set, so Java variables will not be set ('JAVA', 'JAVA_FLAGS', 'SONAR_SCANNER_OPTS')."
	}
	else {
		SetEnvVariable "JAVA" $javaHomeValue
		$javaFlags = "-Dhttps.proxyHost=$proxyHost -Dhttps.proxyPort=$proxyPort -Dhttp.nonProxyHosts=""localhost|127.0.0.1"""
		SetEnvVariable "JAVA_FLAGS" $javaFlags
		SetEnvVariable "SONAR_SCANNER_OPTS" $javaFlags
	}
}


# .NET global tools
Write-Host "Install .NET tool Kros.DummyData.Initializer" -ForegroundColor Green
dotnet tool install --global Kros.DummyData.Initializer


# NPM proxy
if (-not $proxyUri -eq $null) {
	Write-Host "Set proxy for NPM: $proxyUri" -ForegroundColor Green
	npm config set proxy $proxyUri
	npm config set https-proxy $proxyUri
}


# Newman
Write-Host "Install 'newman' to '$NewmanPath'" -ForegroundColor Green
Write-Host "  Install 'newman' globally"
npm install -g newman

if (Test-Path $NewmanPath) {
	Write-Host "  Delete existing folder '$NewmanPath'"
	Remove-Item $NewmanPath -Recurse
}
$NewmanNodeModulesPath = [System.IO.Path]::Join($NewmanPath, "node_modules")
Write-Host "  Create folder '$NewmanPath'"
New-Item -Path $NewmanPath -ItemType Directory
Write-Host "  Create folder '$NewmanNodeModulesPath'"
New-Item -Path $NewmanNodeModulesPath -ItemType Directory
Write-Host "  Copy 'newman' files to '$NewmanPath'"
Copy-Item -Path "$env:APPDATA\npm\newman*" -Destination $NewmanPath
Copy-Item -Path "$env:APPDATA\npm\node_modules\newman" -Destination $NewmanNodeModulesPath -Recurse

Write-Host "  Uninstall 'newman' globally"
npm uninstall -g newman
AddToPath $NewmanPath


# Scheduled tasks
Write-Host "Create scheduled tasks" -ForegroundColor Green

if (-not (Test-Path $ScriptsPath)) {
	Write-Host "  Create '$ScriptsPath' folder"
	New-Item -Path $ScriptsPath -ItemType Directory
}

Write-Host "  Copy scripts to '$ScriptsPath' folder"
Copy-Item -Path "clean-npm-cache.ps1" -Destination $ScriptsPath -Force
Copy-Item -Path "clean-terraform-temp.ps1" -Destination $ScriptsPath -Force

Write-Host "  Create scheduled task 'BuildAgents\CleanNpmCache'"
$script = [System.IO.Path]::Join($ScriptsPath, "clean-npm-cache.ps1")
schtasks /create /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /sc weekly /d sat /st 03:00 /tn "BuildAgents\CleanNpmCache" /tr "pwsh -File '$script' -SaveTranscript"

Write-Host "  Create scheduled task 'BuildAgents\CleanTerraformTemp'"
$script = [System.IO.Path]::Join($ScriptsPath, "clean-terraform-temp.ps1")
schtasks /create /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /sc daily /st 03:30 /tn "BuildAgents\CleanTerraformTemp" /tr "pwsh -File '$script' -SaveTranscript"
