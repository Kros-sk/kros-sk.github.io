<#
.SYNOPSIS
Delete old files and directories from Temp folders of all users.
#>
param (
	[Parameter(Mandatory = $false)][string]$BaseFolder = "C:\Users",
	[Parameter(Mandatory = $false)][string]$TempSubfolder = "AppData\Local\Temp",
	[Parameter(Mandatory = $false)][int]$OlderThanDays = 4,
	[Parameter(Mandatory = $false)][switch]$SaveTranscript
)

if ($SaveTranscript) {
	$transcriptFile = [IO.Path]::ChangeExtension($PSCommandPath, "log")
	Start-Transcript -Path $transcriptFile -UseMinimalHeader
}

$nowDate = [DateTime]::Now.ToString("d.M.yyyy")
$nowTime = [DateTime]::Now.ToString("H:mm")

Write-Output "Script started $nowDate at $nowTime"
Write-Output "Using base folder '$BaseFolder'"
Write-Output "Using temp subfolder '$TempSubfolder'"
Write-Output "Cleaning folders from files and folders older than $OlderThanDays days:"

Get-ChildItem -Path $BaseFolder -Directory | ForEach-Object {
	$userFolder = $_
	$tempFolder = [IO.Path]::Join($userFolder.FullName, $TempSubfolder)
	Write-Output $tempFolder
	if (Test-Path -Path $tempFolder) {
		Get-ChildItem -Path $tempFolder
		| Where-Object {
			$_.CreationTime -lt (Get-Date).AddDays(-$OlderThanDays)
		}
		| ForEach-Object {
			Write-Output "  $_"
			Remove-Item $_ -Recurse -ErrorAction Continue
		}
	}
}

if ($SaveTranscript) {
	Stop-Transcript
}
