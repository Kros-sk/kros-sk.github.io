#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter()][string]$JMeterVersion = "5.4.1",
    [Parameter()][string]$ToolsPath = "C:\tools",
    [Parameter()][string]$PluginsList = "jpgc-graphs-basic,jpgc-casutg,jpgc-prmctl,websocket-samplers,jpgc-wsc"
)

function AddToPath([string]$path) {
	Write-Host "  Add '$path' to environment variable PATH" -ForegroundColor Yellow
	$pathValue = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
	$pattern = $path.Replace("\", "\\")
	if ($pathValue -match $pattern) {
		Write-Host "    PATH variable already contains '$path'."
	}
	else {
		$pathValue = "$path;" + $pathValue
		[System.Environment]::SetEnvironmentVariable("PATH", $pathValue, [System.EnvironmentVariableTarget]::Machine)
		Write-Host "    '$path' added to PATH variable."
	}
}

# Choco install
Write-Host "Install software for load testing" -ForegroundColor Green
choco install load-tests-buildmachine-packages.config --yes

# Add JAVA folder to PATH
Write-Host "Add JAVA folder to PATH" -ForegroundColor Green
$javaHomeValue = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", [System.EnvironmentVariableTarget]::Machine)
if ([string]::IsNullOrEmpty($javaHomeValue)) {
    Write-Host "    'JAVA_HOME' is not set, so Java folder will not be set to the PATH."
}
else {
    $javaBinPath = Join-Path -Path $javaHomeValue -ChildPath "bin"
    AddToPath $javaBinPath
}

# Install JMeter
Write-Host "Install JMeter" -ForegroundColor Green

$jmeterPath = Join-Path -Path $ToolsPath -ChildPath "jmeter"
$jmeterZipFile = Join-Path -Path $env:TEMP -ChildPath "jmeter.zip"
$extractedFolder = Join-Path -Path $ToolsPath -ChildPath "apache-jmeter-$JMeterVersion"
$pluginManagerFile = Join-Path -Path $jmeterPath -ChildPath "lib/ext/jmeter-plugins-manage.jar"
$cmdRunnerFile = Join-Path -Path $jmeterPath -ChildPath "lib/cmdrunner-2.2.jar"

## Delete target folder
Write-Host "  Delete JMeter folder '$jmeterPath'" -ForegroundColor Yellow
Remove-Item $jmeterPath -Recurse -ErrorAction Ignore

## Download JMeter
Write-Host "  Download JMeter (v $JMeterVersion)" -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://downloads.apache.org/jmeter/binaries/apache-jmeter-$JMeterVersion.zip" -OutFile $jmeterZipFile

## Extract JMeter
Write-Host "  Extract downloaded JMeter" -ForegroundColor Green
Expand-Archive -Path $jmeterZipFile -DestinationPath $ToolsPath
Rename-Item $extractedFolder $jmeterPath

$jmeterBinPath = Join-Path -Path $jmeterPath -ChildPath "bin"
AddToPath $jmeterBinPath

## Delete source
Write-Host "  Delete source file '$jmeterZipFile'" -ForegroundColor Yellow
Remove-Item $jmeterZipFile -Recurse -ErrorAction Ignore

# Install JMeter plugins
## Download and install Plugin manager
Write-Host "Install JMeter plugins" -ForegroundColor Green
Write-Host "  Download and install Plugin manager" -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://jmeter-plugins.org/get/" -OutFile $pluginManagerFile
Invoke-WebRequest -Uri "https://search.maven.org/remotecontent?filepath=kg/apc/cmdrunner/2.2/cmdrunner-2.2.jar" -OutFile $cmdRunnerFile

## Create PluginManagerCMDInstaller
Write-Host "  Create PluginManagerCMDInstaller" -ForegroundColor Yellow
java -cp $pluginManagerFile org.jmeterplugins.repository.PluginManagerCMDInstaller

Write-Host "  Install plugins" -ForegroundColor Yellow
$pluginManagerCmd = Join-Path -Path $jmeterPath -ChildPath "bin/PluginsManagerCMD.bat"
$cmd = "$pluginManagerCmd install $PluginsList"
Invoke-Expression $cmd


Write-Host
Write-Host "  Everything is installed. Now run the 'configure.ps1' script." -ForegroundColor Yellow
