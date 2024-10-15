#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter()][string]$ToolsPath = "C:/tools",
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

Write-Host "Install JMeter, this will also install Microsoft OpenJDK." -ForegroundColor Green
winget install --id DEVCOM.JMeter --exact

Write-Host "JMeter is installed in user scope, so copy it to the tools folder '$ToolsPath' and uninstall."
$installedJMeterPath = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Programs" -AdditionalChildPath "JMeter"
$jmeterPath = Join-Path -Path $ToolsPath -ChildPath "JMeter"
Write-Host "  Remove JMeter folder if exist ($jmeterPath)."
Remove-Item $jmeterPath -Recurse -ErrorAction Ignore
Write-Host "  Copy local JMeter to tools folder ($installedJMeterPath → $jmeterPath)."
Copy-Item $installedJMeterPath $jmeterPath -Recurse

Write-Host "  Uninstall local JMeter."
winget uninstall --id DEVCOM.JMeter

$jmeterBinPath = Join-Path -Path $jmeterPath -ChildPath "bin"
AddToPath $jmeterBinPath

# Add JAVA_HOME bin folder to Path. Installaton of OpenJDK adds this to PATH, but it is not visible in current
# session, so I need to add it manually.
$javaHome = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
$javaHomeBin = Join-Path -Path $javaHome -ChildPath "bin"
$env:Path = $env:Path + ";$javaHomeBin"

# Install JMeter plugins
Write-Host

$pluginsManagerFile = Join-Path -Path $jmeterPath -ChildPath "lib/ext/jmeter-plugins-manager.jar"
$pluginsManagerUri = "https://jmeter-plugins.org/get"
Write-Host "Install JMeter plugins" -ForegroundColor Green
Write-Host "  Download plugin manager from '$pluginsManagerUri' to '$pluginsManagerFile'"
Invoke-WebRequest -Uri $pluginsManagerUri -OutFile $pluginsManagerFile

$cmdRunnerVersion = "2.3"
$cmdRunnerFile = Join-Path -Path $jmeterPath -ChildPath "lib/cmdrunner-$cmdRunnerVersion.jar"
$cmdRunnerUri = "https://repo1.maven.org/maven2/kg/apc/cmdrunner/$cmdRunnerVersion/cmdrunner-$cmdRunnerVersion.jar"
Write-Host "  Download CMD runner from '$cmdRunnerUri' to '$cmdRunnerFile'"
Invoke-WebRequest -Uri $cmdRunnerUri -OutFile $cmdRunnerFile

Write-Host "Create Plugins Manager command script"
java -cp $pluginsManagerFile org.jmeterplugins.repository.PluginManagerCMDInstaller

if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
	$pluginsManagerScript = "PluginsManagerCMD.bat"
} else {
	$pluginsManagerScript = "PluginsManagerCMD.sh"
}
$pluginManagerCmd = Join-Path -Path $jmeterPath -ChildPath "bin" -AdditionalChildPath $pluginsManagerScript
Write-Host "  Install plugins using script '$pluginManagerCmd'" -ForegroundColor Yellow
& $pluginManagerCmd install $PluginsList

Write-Host
Write-Host "Everything is installed. Now run the 'configure.ps1' script." -ForegroundColor Green
