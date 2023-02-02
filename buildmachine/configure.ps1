#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()][string]$Proxy = "",
	[Parameter()][string]$NewmanPath = "C:\newman",
	[Parameter()][string]$ToolsPath = "C:\tools",
	[Parameter()][string]$ScriptsPath = "C:\scripts",
	[Parameter()][string]$CachePath = "C:\cache"
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

function CreateFolder($folder, $envVar = "") {
	Write-Host "Create folder '$folder'" -ForegroundColor Green
	if (Test-Path $folder) {
		Write-Host "  Folder already exists."
	}
	else {
		New-Item -Path $folder -ItemType Directory
	}
	if (-not [string]::IsNullOrWhiteSpace($envVar)) {
		SetEnvVariable $envVar $folder
	}
}

# Tools folder
CreateFolder $ToolsPath
AddToPath $ToolsPath

# Cache folders
CreateFolder $CachePath
$cypressCachePath = [System.IO.Path]::Join($CachePath, "cypress")
CreateFolder $cypressCachePath "CYPRESS_CACHE_FOLDER"
$npmCachePath = [System.IO.Path]::Join($CachePath, "npm")
CreateFolder $npmCachePath "NPM_CONFIG_CACHE"
$nugetCachePath = [System.IO.Path]::Join($CachePath, "nuget")
CreateFolder $nugetCachePath "NUGET_PACKAGES"

$proxyUri = $null
if ([string]::IsNullOrWhiteSpace($Proxy)) {
	Write-Host "  Proxy is empty, so no proxy environment variables will be set."
}
else {
	$proxyUri = New-Object -TypeName System.Uri $Proxy
	Write-Host "  Proxy is $proxyUri"
	$proxyValue = $proxyUri.ToString().TrimEnd("/")

	SetEnvVariable "HTTP_PROXY" $proxyValue
	SetEnvVariable "HTTPS_PROXY" $proxyValue
}


# .NET global tools
Write-Host "Install .NET tool Kros.DummyData.Initializer" -ForegroundColor Green
dotnet tool install Kros.DummyData.Initializer --tool-path $ToolsPath
Write-Host "Install .NET tool Kros.VariableSubstitution" -ForegroundColor Green
dotnet tool install Kros.VariableSubstitution --tool-path $ToolsPath
Write-Host ".NET WebAssembly build tools for .NET 6 projects" -ForegroundColor Green
dotnet workload install wasm-tools-net6

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
Copy-Item -Path "clean-temp.ps1" -Destination $ScriptsPath -Force

Write-Host "  Create scheduled task 'BuildAgents\CleanTemp'"
$script = [System.IO.Path]::Join($ScriptsPath, "clean-temp.ps1")
schtasks /create /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /sc daily /st 03:30 /tn "BuildAgents\CleanTemp" /tr "pwsh -File '$script' -SaveTranscript"
