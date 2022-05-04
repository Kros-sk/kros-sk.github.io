#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)][string]$UserName,
	[Parameter(Mandatory = $true)][string]$UserPassword
)

$trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At 8pm
$action = New-ScheduledTaskAction -Execute "PowerShell" -Argument "-file c:\tools\clean-docker.ps1"
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "KROS - Start Docker Clean Up" -Settings $settings -User $UserName -Password $UserPassword -RunLevel Highest