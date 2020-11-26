<#
.SYNOPSIS
Delete NPM cache for all users.

.DESCRIPTION
Script deletes '_cacache' subfolder from NPM cache folder. NPM cache folder is in '%AppData%\npm-cache'.
#>

param (
	[Parameter(Mandatory = $false)][string]$BaseFolder,
	[Parameter(Mandatory = $false)][string]$NpmCacheSubfolder,
	[Parameter(Mandatory = $false)][switch]$SaveTranscript
)

if ($SaveTranscript) {
	$transcriptFile = [IO.Path]::ChangeExtension($PSCommandPath, "log")
	Start-Transcript -Path $transcriptFile -UseMinimalHeader
}

if ([string]::IsNullOrWhiteSpace($BaseFolder)) {
	$BaseFolder = "C:\Users"
}
if ([string]::IsNullOrWhiteSpace($NpmCacheSubfolder)) {
	$NpmCacheSubfolder = "AppData\Roaming\npm-cache\_cacache"
}

$MB = 1024 * 1024
$nowDate = [DateTime]::Now.ToString("d.M.yyyy")
$nowTime = [DateTime]::Now.ToString("H:mm")
$totalCount = 0
[double] $totalSize = 0
$totalTime = [TimeSpan]::Zero

Write-Output "Script started $nowDate at $nowTime"
Write-Output "Using base folder '$BaseFolder'"
Write-Output "Using NPM cache subfolder '$NpmCacheSubfolder'"
Write-Output "Cleaning NPM cache folders:"
Get-ChildItem -Path $BaseFolder -Directory | ForEach-Object {
	$userFolder = $_
	$cacheFolder = [IO.Path]::Join($userFolder.FullName, $NpmCacheSubfolder)
	Write-Output $cacheFolder
	if (Test-Path -Path $cacheFolder) {
		$cacheFolderForCount = [IO.Path]::Join($cacheFolder, "*")
		$calcTime = Measure-Command {
			$folderSize = Get-ChildItem $cacheFolderForCount -Recurse -ErrorAction Continue | Measure-Object -Property Length -Sum
		}
		$totalTime += $calcTime
		$totalCount	+= $folderSize.Count
		$totalSize += $folderSize.Sum
		$msg = "  Files: {0:n0}, Size: {1:n2} MB, Calc time: {2}:{3:00}" -f $folderSize.Count, ($folderSize.Sum / $MB), $calcTime.Minutes, $calcTime.Seconds
		Write-Output $msg
		Remove-Item $cacheFolder -Recurse -ErrorAction Continue
	}
}
$totalSize /= $MB
$msg = "Total: {0:n0} file(s) deleted, size {1:n2} MB, time {2}:{3:00}" -f $totalCount, $totalSize, $totalTime.Minutes, $totalTime.Seconds
Write-Output ""
Write-Output $msg

if ($SaveTranscript) {
	Stop-Transcript
}
