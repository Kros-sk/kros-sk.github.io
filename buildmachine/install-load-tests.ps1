#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter()][string]$JMeterVersion = "5.4.1",
    [Parameter()][string]$DownloadFolder = "C:\download",
    [Parameter()][string]$JMeterPath = "C:\tools\jmeter",
    [Parameter()][string]$PluginsList = "jpgc-graphs-basic,jpgc-casutg,jpgc-prmctl"
)

function ExtractArchive([string]$archiveFile, [string]$outputFolder) {
    Write-Host "    Extract archive '$archiveFile' to '$outputFolder'" -ForegroundColor Blue

    $extractCommand = "7z x $archiveFile -o$jmeterSource -r -aoa"
    Invoke-Expression $extractCommand
}

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
    Write-Host "    'JAVA_HOME' is not set, so Java variables will not be set ('JAVA', 'JAVA_FLAGS', 'SONAR_SCANNER_OPTS')."
}
else {
    $javaBinPath = Join-Path -Path $javaHomeValue -ChildPath "bin"
    AddToPath $javaBinPath
}

# Install JMeter
Write-Host "Install JMeter" -ForegroundColor Green

$jmeterSource = Join-Path -Path $DownloadFolder -ChildPath "jmeter"
$jmeterZipFile = Join-Path -Path $jmeterSource -ChildPath "jmeter.tgz"
$tarFile = Join-Path -Path $jmeterSource -ChildPath "jmeter.tar"
$extractedFolder = Join-Path -Path $jmeterSource -ChildPath "apache-jmeter-$JMeterVersion"
$pluginManagerFile = Join-Path -Path $JMeterPath -ChildPath "lib/ext/jmeter-plugins-manage.jar"
$cmdRunnerFile = Join-Path -Path $JMeterPath -ChildPath "lib/cmdrunner-2.2.jar"

## Delete source and target folder
Write-Host "  Delete JMeter folder '$JMeterPath'" -ForegroundColor Yellow
Remove-Item $JMeterPath -Recurse -ErrorAction Ignore
Remove-Item $jmeterSource -Recurse -ErrorAction Ignore

## Download JMeter
Write-Host "  Download JMeter (v $JMeterVersion)" -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://downloads.apache.org//jmeter/binaries/apache-jmeter-$JMeterVersion.tgz" -OutFile ( New-Item -Path $jmeterZipFile -Force)

## Extract JMeter
Write-Host "  Extract downloaded JMeter" -ForegroundColor Green
ExtractArchive $jmeterZipFile $jmeterSource
ExtractArchive $tarFile $jmeterSource

## Copy extracted JMeter to dest folder
Write-Host "  Copy JMeter from '$extractedFolder' to '$JMeterPath'" -ForegroundColor Green
Move-Item "$extractedFolder*" $JMeterPath

$jmeterBinPath = Join-Path -Path $JMeterPath -ChildPath "bin"
AddToPath $jmeterBinPath

## Delete source
Write-Host "  Delete source folder '$jmeterSource'" -ForegroundColor Yellow
Remove-Item $jmeterSource -Recurse -ErrorAction Ignore

# Install JMeter plugins
## Download and install Plugin manager
Write-Host "Install JMeter plugins" -ForegroundColor Green
Write-Host "  Download and install Plugin manager" -ForegroundColor Yellow
Invoke-WebRequest -Uri "https://jmeter-plugins.org/get/" -OutFile ( New-Item -Path $pluginManagerFile -Force)
Invoke-WebRequest -Uri "https://search.maven.org/remotecontent?filepath=kg/apc/cmdrunner/2.2/cmdrunner-2.2.jar" -OutFile ( New-Item -Path $cmdRunnerFile -Force)

## Create PluginManagerCMDInstaller
Write-Host "  Create PluginManagerCMDInstaller" -ForegroundColor Yellow
java -cp $JMeterPath/lib/ext/jmeter-plugins-manage.jar org.jmeterplugins.repository.PluginManagerCMDInstaller

Write-Host "  Install plugins" -ForegroundColor Yellow
$pluginManagerCmd = Join-Path -Path $JMeterPath -ChildPath "bin/PluginsManagerCMD.bat"
$cmd = "$pluginManagerCmd install $PluginsList"
Invoke-Expression $cmd


Write-Host
Write-Host "  Everything is installed. Now run the 'configure.ps1' script." -ForegroundColor Yellow
