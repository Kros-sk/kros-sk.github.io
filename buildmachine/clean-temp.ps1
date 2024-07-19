<#
.SYNOPSIS
Delete old files and directories from Temp folders of all users.
#>
param (
	[Parameter(Mandatory = $false)][string]$BaseFolder = "C:\Users",
	[Parameter(Mandatory = $false)][string]$TempSubfolder = "AppData\Local\Temp",
	[Parameter(Mandatory = $false)][int]$OlderThanDays = 1,
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

if ($OlderThanDays -lt 0) {
	$OlderThanDays = 0
}

$nowDate = [DateTime]::Now.ToString("d.M.yyyy")
$nowTime = [DateTime]::Now.ToString("H:mm")

Write-Host "Script started $nowDate at $nowTime"
Write-Host "Using base folder '$BaseFolder'"
Write-Host "Using temp subfolder '$TempSubfolder'"
Write-Host "Cleaning folders from files and folders older than $OlderThanDays days:"
if ($DryRun) {
	Write-Host "  Dry run only, nothing will be really deleted."
}

Write-Host

Get-ChildItem -Path $BaseFolder -Directory | ForEach-Object {
	$userFolder = $_
	$tempFolder = [IO.Path]::Join($userFolder.FullName, $TempSubfolder)
	Write-Host $tempFolder
	if (Test-Path -Path $tempFolder) {
		Get-ChildItem -Path $tempFolder
		| Where-Object {
			$_.CreationTime -lt (Get-Date).Date.AddDays(-$OlderThanDays)
		}
		| ForEach-Object {
			Write-Host "  $_"
			if (-not $DryRun) {
				Remove-Item $_ -Recurse -ErrorAction Continue
			}
		}
	}
}

Write-Host ""
Write-Host "Remove empty folders"
Get-ChildItem -Path $BaseFolder -Directory | ForEach-Object {
	$userFolder = $_
	$tempFolder = [IO.Path]::Join($userFolder.FullName, $TempSubfolder)
	Write-Host $tempFolder
	if (Test-Path -Path $tempFolder) {
		Get-ChildItem -Path $tempFolder -Directory | ForEach-Object {
			$tempSubFolder = $_
			$count = (Get-ChildItem -Path $tempSubFolder).Count
			if ($count -eq 0) {
				Write-Host "$tempSubFolder - EMPTY → deleting"
				if (-not $DryRun) {
					Remove-Item $tempSubFolder -ErrorAction Continue
				}
			} else {
				Write-Host "$tempSubFolder - NOT EMPTY"
			}
		}
	}
}

if ($SaveTranscript) {
	Stop-Transcript
}
