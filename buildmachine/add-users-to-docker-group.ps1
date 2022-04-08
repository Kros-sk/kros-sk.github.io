#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()][string]$UserName,
	[Parameter()][int]$NumberOfUsers,
	[Parameter()][int]$StartUserNumber = 1
)

$userNameMaxLength = 15
if ([string]::IsNullOrWhiteSpace($UserName)) {
	$UserName = Read-Host -Prompt 'User name'
}
if (-not ($UserName -match "^[a-z0-9_-]{1,$userNameMaxLength}$")) {
	throw "Invalid user name. It must be a string containig only letters, numbers, underscore (_) and hyphen (-) and its maximum length can be $userNameMaxLength characters."
}
if ($NumberOfUsers -lt 1) {
	$NumberOfUsers = [int](Read-Host -Prompt 'Number of users')
	if ($NumberOfUsers -lt 1) {
		throw "Invalid number of users. It must be number greater or equal to 1."
	}
}
else {
	Write-Host "UserName = $UserName"
	Write-Host "NumberOfUsers = $NumberOfUsers"
	$StartUserNumber..($StartUserNumber + $NumberOfUsers - 1) | ForEach-Object {
		$localUserName = "a-{0}-{1:d2}" -f $UserName, $_
		Write-Host "Add user '$localUserName' to 'docker-users' group."
        Add-LocalGroupMember -Group docker-users -Member $localUserName -ErrorAction Stop
	}
}