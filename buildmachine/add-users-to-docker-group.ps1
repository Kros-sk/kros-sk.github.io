#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)][string]$UserName,
	[Parameter(Mandatory = $true)][int]$NumberOfUsers,
	[Parameter()][int]$StartUserNumber = 1
)

$userNameMaxLength = 15
if (-not ($UserName -match "^[a-z0-9_-]{1,$userNameMaxLength}$")) {
	throw "Invalid user name. It must be a string containig only letters, numbers, underscore (_) and hyphen (-) and its maximum length can be $userNameMaxLength characters."
}

Write-Host "UserName = $UserName"
Write-Host "NumberOfUsers = $NumberOfUsers"
$StartUserNumber..($StartUserNumber + $NumberOfUsers - 1) | ForEach-Object {
	$localUserName = "a-{0}-{1:d2}" -f $UserName, $_
	Write-Host "Add user '$localUserName' to 'docker-users' group."
	Add-LocalGroupMember -Group docker-users -Member $localUserName -ErrorAction Stop
}