#Requires -RunAsAdministrator

[CmdletBinding()]
param (
	[Parameter()][string]$Pat,
	[Parameter()][string]$AgentsBaseFolder = "C:/agents",
	[Parameter()][string]$AgentZipFile = "vsts-agent-win-x64.zip",
	[Parameter()][string]$WindowsUser = "buildAgent",
	[Parameter()][string]$WindowsPassword = "buildAgent"
)

if ([string]::IsNullOrWhiteSpace($Pat)) {
	Write-Host "PAT is not set. Exiting." -ForegroundColor Red
	Write-Host "PAT must have 'Read & manage' rights in 'Agent Pools' scope."
	exit 1
}
$scriptFolder = [IO.Path]::GetDirectoryName($PSCommandPath)
$agentZip = [IO.Path]::Combine($scriptFolder, $AgentZipFile)
if (-not (Test-Path $agentZip)) {
	Write-Host "Agent zip file '$agentZip' not found. Exiting." -ForegroundColor Red
	exit 2
}
$configFile = [IO.Path]::ChangeExtension($PSCommandPath, "json")
Write-Host "Reading configuration from '$configFile'"
if (-not (Test-Path $configFile)) {
	Write-Host "Configuration file '$configFile' not found. Exiting." -ForegroundColor Red
	exit 3
}

Write-Host "Checking local user '$WindowsUser'."
net user $WindowsUser
if ($LASTEXITCODE -eq 0) {
	Write-Host "Local user '$WindowsUser' already exist."
}
else {
	Write-Host "Local user '$WindowsUser' does not exist."
	net user $WindowsUser $WindowsPassword /add /passwordchg:no /expires:never
	Write-Host "Local user '$WindowsUser' was craeted."
}

if (-not (Test-Path $AgentsBaseFolder)) {
	Write-Host "Creating base folder for agents '$AgentsBaseFolder'."
	New-Item -Path $AgentsBaseFolder -ItemType Directory
}

$devOpsServerUrl = "https://dev.azure.com/krossk/"

$agents = Get-Content -Raw -Path $configFile | ConvertFrom-Json
$agents.pools | ForEach-Object {
	$pool = $_
	$poolName = $pool.name
	$pool.agents | ForEach-Object {
		$agentName = $_
		Write-Host "Configuring agent '$agentName' in agent pool '$poolName'" -ForegroundColor Green
		$agentFolder = [IO.Path]::Combine($AgentsBaseFolder, $agentName)
		Write-Host "Agent folder is '$agentFolder'"
		if (Test-Path $agentFolder) {
			Write-Host "Agent folder already exists. Configuration of this agent is skipped."
			Write-Host
			continue
		}
		else {
			New-Item -Path $agentFolder -ItemType Directory
			Write-Host "Unzipping agent to folder."
			Expand-Archive -LiteralPath $agentZip -DestinationPath $agentFolder
			$proxyFile = [IO.Path]::Combine($scriptFolder, ".proxy")
			if (Test-Path -Path $proxyFile) {
				Write-Host "Copying proxy settings '$proxyFile' to agent folder."
				Copy-Item -Path $proxyFile -Destination $agentFolder -Force
			} else {
				Write-Host "Proxy settings file '$proxyFile' not found." -ForegroundColor Yellow
				Write-Host "If agent is behind proxy, create file '$proxyFile' with proxy settings, otherwise the agent may not work correctly." -ForegroundColor Yellow
			}
			$proxyBypassFile = [IO.Path]::Combine($scriptFolder, ".proxybypass")
			if (Test-Path -Path $proxyBypassFile) {
				Write-Host "Copying proxy settings '$proxyBypassFile' to agent folder."
				Copy-Item -Path $proxyBypassFile -Destination $agentFolder -Force
			}

			$agentConfig = [IO.Path]::Combine($agentFolder, "config.cmd")
			Write-Host "Running agent configuration file '$agentConfig'."
			& $agentConfig --unattended --url $devOpsServerUrl --auth pat --token $Pat --runAsService --pool $poolName --agent $agentName --windowsLogonAccount $WindowsUser --windowsLogonPassword $WindowsPassword
			Write-Host "Agent '$agentName' is configured." -ForegroundColor Green
			Write-Host
		}
	}
}
