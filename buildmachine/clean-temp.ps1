<#
.SYNOPSIS
Delete old files and directories from Temp folders of all users.
#>
param (
	[Parameter(Mandatory = $false)][string]$BaseFolder = "C:\Users",
	[Parameter(Mandatory = $false)][string]$TempSubfolder = "AppData\Local\Temp",
	[Parameter(Mandatory = $false)][int]$OlderThanDays = 4,
	[Parameter(Mandatory = $false)][switch]$SaveTranscript,
	[Parameter(Mandatory = $false)][string]$TranscriptFile = "",
	[Parameter(Mandatory = $false)][switch]$DryRun
)

if ($SaveTranscript) {
	if ($TranscriptFile -eq "") {
		$TranscriptFile = [IO.Path]::ChangeExtension($PSCommandPath, "log")
	} else {
		$scriptFolder = [IO.Path]::GetDirectoryName($PSCommandPath)
		$TranscriptFile = [IO.Path]::Join($scriptFolder, "clean-temp-$TranscriptFile.log")
	}
	Start-Transcript -Path $TranscriptFile -UseMinimalHeader
}

$nowDate = [DateTime]::Now.ToString("d.M.yyyy")
$nowTime = [DateTime]::Now.ToString("H:mm")

Write-Output "Script started $nowDate at $nowTime"
Write-Output "Using base folder '$BaseFolder'"
Write-Output "Using temp subfolder '$TempSubfolder'"
Write-Output "Cleaning folders from files and folders older than $OlderThanDays days:"
if ($DryRun) {
	Write-Output "  Dry run only, nothing will be really deleted."
}

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
			if (-not $DryRun) {
				Remove-Item $_ -Recurse -ErrorAction Continue
			}
		}
	}
}

if ($SaveTranscript) {
	Stop-Transcript
}
