#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()][string]$Proxy = "",
	[Parameter()][string]$ToolsPath = "C:\tools",
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
Write-Host "Set rights for 'Users' group for cache folder."
$acl = Get-Acl -Path $CachePath
$usersRule = New-Object Security.AccessControl.FileSystemAccessRule 'BUILTIN\Users', 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
$acl.SetAccessRule($usersRule)
Set-Acl -Path $CachePath -AclObject $acl

$cypressCachePath = [System.IO.Path]::Join($CachePath, "cypress")
CreateFolder $cypressCachePath "CYPRESS_CACHE_FOLDER"
$npmCachePath = [System.IO.Path]::Join($CachePath, "npm")
CreateFolder $npmCachePath "NPM_CONFIG_CACHE"
$nugetCachePath = [System.IO.Path]::Join($CachePath, "nuget")
CreateFolder $nugetCachePath "NUGET_PACKAGES"
$nugetCachePath = [System.IO.Path]::Join($CachePath, "nx")
CreateFolder $nugetCachePath

Write-Host "Set proxy" -ForegroundColor Green
$proxyUri = $null
$proxyValue = ""
if ([string]::IsNullOrWhiteSpace($Proxy)) {
	Write-Host "  Proxy is empty, so no proxy environment variables will be set."
}
else {
	$proxyUri = New-Object -TypeName System.Uri $Proxy
	$proxyValue = $proxyUri.ToString().TrimEnd("/")
	Write-Host "  Proxy is $proxyValue"

	Write-Host "  Set environment variables HTTP_PROXY and HTTPS_PROXY."
	SetEnvVariable "HTTP_PROXY" $proxyValue
	SetEnvVariable "HTTPS_PROXY" $proxyValue

	Write-Host "  Set proxy for NPM"
	npm config set proxy $proxyValue
	npm config set https-proxy $proxyValue
}

# Azure Artifacts Credential Provider
Write-Host "Install Azure Artifacts Credential Provider" -ForegroundColor Green
Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-artifacts-credprovider.ps1) }"

# .NET global tools
Write-Host "Add NuGet source nuget.org" -ForegroundColor Green
dotnet nuget add source "https://api.nuget.org/v3/index.json" --name "nuget.org"

Write-Host "Install .NET tool Kros.DummyData.Initializer" -ForegroundColor Green
dotnet tool install Kros.DummyData.Initializer --tool-path $ToolsPath
Write-Host "Install .NET tool Kros.VariableSubstitution" -ForegroundColor Green
dotnet tool install Kros.VariableSubstitution --tool-path $ToolsPath
Write-Host "Install .NET tool dotnet-affected" -ForegroundColor Green
dotnet tool install dotnet-affected --tool-path $ToolsPath

# Write-Host ".NET WebAssembly build tools for .NET 6 projects" -ForegroundColor Green
# dotnet workload install wasm-tools-net6

# Newman
$NewmanPath = [System.IO.Path]::Join($ToolsPath, "newman")
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

Write-Host "  Copy scripts to '$ToolsPath' folder"
Copy-Item -Path "clean-temp.ps1" -Destination $ToolsPath -Force
Copy-Item -Path "clean-nx-cache.ps1" -Destination $ToolsPath -Force

$scheduledTask = "BuildAgents\Clean Temp"
Write-Host "  Create scheduled task '{$scheduledTask}'"
$script = [System.IO.Path]::Join($ToolsPath, "clean-temp.ps1")
schtasks /create /f /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /sc daily /st 02:00 /tn $scheduledTask /tr "pwsh -File '$script' -SaveTranscript"

$scheduledTask = "BuildAgents\Clean Cypress artifacts"
Write-Host "  Create scheduled task '{$scheduledTask}'"
$script = [System.IO.Path]::Join($ToolsPath, "clean-temp.ps1")
schtasks /create /f /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /sc weekly /d SUN /st 22:00 /tn $scheduledTask /tr "pwsh -File '$script' -TempSubfolder 'AppData\Roaming\Cypress\cy\production\projects' -OlderThanDays 5 -SaveTranscript -TranscriptFile 'cypress'"

$scheduledTask = "BuildAgents\Clean NX cache"
Write-Host "  Create scheduled task '{$scheduledTask}'"
$script = [System.IO.Path]::Join($ToolsPath, "clean-nx-cache.ps1")
schtasks /create /f /ru "NT AUTHORITY\SYSTEM" /rl HIGHEST /sc daily /st 02:30 /tn $scheduledTask /tr "pwsh -File '$script' -SaveTranscript"
