#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)][string]$UserName,
	[Parameter(Mandatory = $true)][SecureString]$UserPassword
)

$trigger = New-ScheduledTaskTrigger -AtStartup
$action = New-ScheduledTaskAction -Execute "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries
Register-ScheduledTask -Action $action -Trigger $trigger -TaskPath "\BuildAgents\" -TaskName "KROS - Start Docker on Start up" -Settings $settings -User $UserName -Password $UserPassword -RunLevel Highest
