<#
.SYNOPSIS
Delete Terraform files from Temp folders of all users.
#>

param (
	[Parameter(Mandatory = $false)][string]$BaseFolder,
	[Parameter(Mandatory = $false)][string]$TempSubfolder,
	[Parameter(Mandatory = $false)][switch]$SaveTranscript
)

if ($SaveTranscript) {
	$transcriptFile = [IO.Path]::ChangeExtension($PSCommandPath, "log")
	Start-Transcript -Path $transcriptFile -UseMinimalHeader
}

if ([string]::IsNullOrWhiteSpace($BaseFolder)) {
	$BaseFolder = "C:\Users"
}
if ([string]::IsNullOrWhiteSpace($TempSubfolder)) {
	$TempSubfolder = "AppData\Local\Temp"
}

$MB = 1024 * 1024
$today = [DateTime]::Now.Date
$nowDate = [DateTime]::Now.ToString("d.M.yyyy")
$nowTime = [DateTime]::Now.ToString("H:mm")
$totalCount = 0
[double] $totalSize = 0

Write-Output "Script started $nowDate at $nowTime"
Write-Output "Using base folder '$BaseFolder'"
Write-Output "Using temp subfolder '$TempSubfolder'"
Write-Output "Cleaning temp folders:"
Get-ChildItem -Path $BaseFolder -Directory | ForEach-Object {
	$userFolder = $_
	$tempFolder = [IO.Path]::Join($userFolder.FullName, $TempSubfolder)
	Write-Output $tempFolder
	if (Test-Path -Path $tempFolder) {
		$tempFolder = [IO.Path]::Join($tempFolder, "*")
		$count = 0
		[double] $size = 0
		Get-ChildItem -Path $tempFolder -File -Include "terraform-log*", "terraform-provider*" |
		Where-Object -Property LastWriteTimeUtc -lt $today |
		ForEach-Object {
			$file = $_
			$count++
			$size += $file.Length
			Remove-Item $_ -ErrorAction Continue
		}
		$totalCount	+= $count
		$totalSize += $size
		$size /= $MB
		$msg = "  {0:n0} file(s) deleted, size {1:n2} MB" -f $count, $size
		Write-Output $msg
	}
}
$totalSize /= $MB
$msg = "Total: {0:n0} file(s) deleted, size {1:n2} MB" -f $totalCount, $totalSize
Write-Output ""
Write-Output $msg

if ($SaveTranscript) {
	Stop-Transcript
}
