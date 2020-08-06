#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()][string]$ProxyHost,
	[Parameter()][int]$ProxyPort
)

if ([string]::IsNullOrWhiteSpace($ProxyHost)) {
	$ProxyHost = Read-Host -Prompt 'Proxy host'
}
if ($ProxyPort -eq 0) {
	$ProxyPort = [int](Read-Host -Prompt 'Proxy port')
}

function SetEnvVariable($name, $value) {
	Write-Host "Try to set '$name' to '$value'"
	$currentValue = [System.Environment]::GetEnvironmentVariable($name, [System.EnvironmentVariableTarget]::Machine)
	if ([string]::IsNullOrEmpty($currentValue)) {
		Write-Host "Setting '$name' to '$value'"
		[System.Environment]::SetEnvironmentVariable($name, $value, [System.EnvironmentVariableTarget]::Machine)
	}
	else {
		Write-Host "'$name' is already set to '$currentValue'. Will not change it."
	}
}

$pathValue = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
if ($pathValue -match "c:(\\|/)newman") {
	Write-Host "'PATH' variable already contains 'c:\newman'."
}
else {
	$pathValue += ";c:\newman"
	Write-Host "Adding 'c:\newman' to 'PATH'."
	[System.Environment]::SetEnvironmentVariable("PATH", $pathValue, [System.EnvironmentVariableTarget]::Machine)
}

$proxy = $ProxyHost
if ($ProxyPort -gt 0) {
	$proxy += ":$ProxyPort"
}

if ([string]::IsNullOrWhiteSpace($ProxyHost)) {
	Write-Host "Proxy host is empty. Nothing to do."
}
else {
	SetEnvVariable "HTTP_PROXY" $proxy
	SetEnvVariable "HTTPS_PROXY" $proxy

	$javaHomeValue = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", [System.EnvironmentVariableTarget]::Machine)
	if ([string]::IsNullOrEmpty($javaHomeValue)) {
		Write-Host "'JAVA_HOME' is not set, so Java variables will not be set ('JAVA', 'JAVA_FLAGS', 'SONAR_SCANNER_OPTS')."
	}
	else {
		SetEnvVariable "JAVA" $javaHomeValue
		$javaFlags = "-Dhttps.proxyHost=$ProxyHost -Dhttps.proxyPort=$ProxyPort -Dhttp.nonProxyHosts=""localhost|127.0.0.1"""
		SetEnvVariable "JAVA_FLAGS" $javaFlags
		SetEnvVariable "SONAR_SCANNER_OPTS" $javaFlags
	}
}
