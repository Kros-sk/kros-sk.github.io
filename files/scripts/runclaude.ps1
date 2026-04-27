$proxyUrl = "http://127.0.0.1:9801"
$proxyPort = 9801

Write-Host "Running Claude with 'claude-code-cache-fix' proxy: https://github.com/cnighswonger/claude-code-cache-fix" -ForegroundColor Green
Write-Host "[runclaude] Checking if Claude proxy is running on port $proxyPort..."

$listening = Get-NetTCPConnection -LocalPort $proxyPort -State Listen -ErrorAction SilentlyContinue

if ($listening) {
	Write-Host "[runclaude] Proxy already running on port $proxyPort. Skipping startup." -ForegroundColor Yellow
}
else {
	Write-Host "[runclaude] Proxy not detected. Starting claude-code-cache-fix proxy in background..."
	node "$(npm root -g)/claude-code-cache-fix/proxy/server.mjs" &
	Write-Host "[runclaude] Proxy process launched. Waiting for it to bind on port $proxyPort..."

	$timeout = 10
	$elapsed = 0
	do {
		Start-Sleep -Milliseconds 500
		$elapsed += 0.5
		$listening = Get-NetTCPConnection -LocalPort $proxyPort -State Listen -ErrorAction SilentlyContinue
	} while (-not $listening -and $elapsed -lt $timeout)

	if ($listening) {
		Write-Host "[runclaude] Proxy is up and listening on port $proxyPort." -ForegroundColor Yellow
	}
	else {
		Write-Host "[runclaude] WARNING: Proxy did not bind to port $proxyPort within ${timeout}s. Clearing ANTHROPIC_BASE_URL and launching Claude without proxy." -ForegroundColor Yellow
	}
}

if ($listening) {
	Write-Host "[runclaude] Setting ANTHROPIC_BASE_URL to $proxyUrl"
	$env:ANTHROPIC_BASE_URL = $proxyUrl
}
else {
	Write-Host "[runclaude] Clearing ANTHROPIC_BASE_URL (proxy not available)."
	$env:ANTHROPIC_BASE_URL = ""
}

Write-Host "[runclaude] Launching Claude..."
Write-Host
claude
