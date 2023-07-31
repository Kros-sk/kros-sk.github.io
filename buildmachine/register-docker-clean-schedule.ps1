#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)][string]$UserName,
	[Parameter(Mandatory = $true)][string]$UserPassword
)

$trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At 8pm
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-file c:\tools\clean-docker.ps1"
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries
Register-ScheduledTask -Action $action -Trigger $trigger -TaskPath "\BuildAgents\" -TaskName "KROS - Start Docker Clean Up" -Settings $settings -User $UserName -Password $UserPassword -RunLevel Highest
