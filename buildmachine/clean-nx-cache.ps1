<#
.SYNOPSIS
Delete old files and directories from NX cache folder.
#>
param (
	[Parameter(Mandatory = $false)][string]$CacheFolder = "e:\cache\nx\",
	[Parameter(Mandatory = $false)][int]$OlderThanDays = 10,
	[Parameter(Mandatory = $false)][switch]$SaveTranscript,
	[Parameter(Mandatory = $false)][string]$TranscriptFile = "",
	[Parameter(Mandatory = $false)][switch]$DryRun
)

if ($SaveTranscript) {
	if ($TranscriptFile -eq "") {
		$TranscriptFile = [IO.Path]::ChangeExtension($PSCommandPath, "log")
	} else {
		$scriptFolder = [IO.Path]::GetDirectoryName($PSCommandPath)
		$TranscriptFile = [IO.Path]::Join($scriptFolder, "clean-nx-cache-$TranscriptFile.log")
	}
	Start-Transcript -Path $TranscriptFile -UseMinimalHeader
}

if ($OlderThanDays -lt 1) {
	$OlderThanDays = 1
}

$nowDate = [DateTime]::Now.ToString("d.M.yyyy")
$nowTime = [DateTime]::Now.ToString("H:mm")

Write-Host "Script started $nowDate at $nowTime"
Write-Host "Using NX cache folder '$CacheFolder'"
Write-Host "Cleaning NX cache folder from files and folders older than $OlderThanDays days:"
if ($DryRun) {
	Write-Host "  Dry run only, nothing will be really deleted."
}

Write-Host

$olderThan = (Get-Date).Date.AddDays(-$OlderThanDays)

Get-ChildItem -Path $CacheFolder
	| Where-Object {
		$_.CreationTime -lt $olderThan
	}
	| ForEach-Object {
		Write-Host "  $_"
		if (-not $DryRun) {
			Remove-Item $_ -Recurse -ErrorAction Continue
		}
}

Write-Host ""
Write-Host "Remove empty folders"
Get-ChildItem -Path $CacheFolder -Directory | ForEach-Object {
	$folder = $_
	$count = (Get-ChildItem -Path $folder).Count
	if ($count -eq 0) {
		Write-Host "$folder - EMPTY → deleting"
		if (-not $DryRun) {
			Remove-Item $folder -ErrorAction Continue
		}
	}
}

if ($SaveTranscript) {
	Stop-Transcript
}
