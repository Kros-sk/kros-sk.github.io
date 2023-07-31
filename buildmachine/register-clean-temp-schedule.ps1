#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)][string]$TaskName,
	[Parameter(Mandatory = $true)][string]$UserName,
	[Parameter(Mandatory = $true)][string]$UserPassword,
	[Parameter(Mandatory = $true)][string]$ExecutionTime = "9pm",
	[Parameter(Mandatory = $true)][string]$TempSubfolder = "AppData\Local\Temp",
	[Parameter(Mandatory = $true)][int]$OlderThanDays = 30,
	[Parameter(Mandatory = $false)][string]$TranscriptFile = ""
)

$trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At $ExecutionTime
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-file ""c:\tools\clean-temp.ps1"" -TempSubfolder ""$TempSubfolder"" -OlderThanDays $OlderThanDays -SaveTranscript -TranscriptFile ""$TranscriptFile"""
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries
Register-ScheduledTask -Action $action -Trigger $trigger -TaskPath "\BuildAgents\" -TaskName $TaskName -Settings $settings -User $UserName -Password $UserPassword -RunLevel Highest
