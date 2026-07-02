[CmdletBinding()]
param(
    [switch]$SkipSmokeTest
)

# Validates the workspace MCP configuration and smoke-tests the local stdio
# facade. This is a lightweight health check, not a registration step:
# Claude Code reads .mcp.json natively, so nothing here mutates global state.
#
#   - .mcp.json is parsed and every declared server is reported.
#   - the stdio server (powershell-mcp-facade) gets an initialize + tools/list
#     smoke test; the returned tool catalog is verified against the expected
#     trimmed tool set (sql.select, server.describe_capabilities).
#   - http servers (jira-internal, wiki-internal) are reported only; their
#     connectivity/OAuth is handled by Claude Code on use.
#   - the local db-proxy SQL backend gets an informational GET /status probe.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$mcpPath = Join-Path $projectRoot ".mcp.json"

if (-not (Test-Path -LiteralPath $mcpPath)) {
    Write-Error "Missing MCP configuration: .mcp.json was not found at the workspace root."
    exit 1
}

$config = Get-Content -LiteralPath $mcpPath -Raw | ConvertFrom-Json
if ($null -eq $config.mcpServers) {
    Write-Error ".mcp.json does not declare an 'mcpServers' object."
    exit 1
}

function Invoke-StdioSmokeTest {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory
    )

    $request = @(
        '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"claude-acw-check","version":"0"}}}',
        '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}',
        '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
    ) -join [Environment]::NewLine

    Push-Location $WorkingDirectory
    try {
        $output = $request | & $Command @Arguments
    }
    finally {
        Pop-Location
    }

    foreach ($line in $output) {
        if ($line -notmatch '^\s*\{') {
            continue
        }
        $message = $line | ConvertFrom-Json
        if ($message.id -eq 2 -and $null -ne $message.result -and $null -ne $message.result.tools) {
            return @(@($message.result.tools) | ForEach-Object { [string]$_.name })
        }
    }

    throw "tools/list did not return a tool catalog."
}

# Informational probe of the local db-proxy SQL backend (does not fail the check;
# the proxy may legitimately be down at config-check time and is auto-started by
# Start-Claude.ps1 before a session).
$dbProxyConfigPath = Join-Path $projectRoot "db-proxy/config/db-proxy.config.json"
if (Test-Path -LiteralPath $dbProxyConfigPath) {
    $dbProxyConfig = Get-Content -LiteralPath $dbProxyConfigPath -Raw | ConvertFrom-Json
    $dbProxyBaseUrl = if ($null -ne $dbProxyConfig.http -and -not [string]::IsNullOrWhiteSpace([string]$dbProxyConfig.http.baseUrl)) {
        ([string]$dbProxyConfig.http.baseUrl).TrimEnd("/")
    } else {
        "http://127.0.0.1:8765"
    }

    try {
        $dbStatus = Invoke-RestMethod -Uri ("{0}/status" -f $dbProxyBaseUrl) -Method Get -TimeoutSec 3 -ErrorAction Stop
        Write-Host ("[db   ] {0,-22} -> /status OK (backendVersion={1})" -f "db-proxy", $dbStatus.result.backendVersion)
    }
    catch {
        Write-Host ("[db   ] {0,-22} -> /status not reachable on {1} (start db-proxy/Start.ps1 or use scripts/Start-Claude.ps1)" -f "db-proxy", $dbProxyBaseUrl)
    }
}

# The powershell-mcp-facade now exposes exactly these tools.
$expectedFacadeTools = @("sql.select", "server.describe_capabilities")

$failures = 0
foreach ($property in $config.mcpServers.PSObject.Properties) {
    $name = $property.Name
    $server = $property.Value
    $type = if ($server.PSObject.Properties.Name -contains "type") { [string]$server.type } else { "stdio" }

    if ($type -eq "http") {
        Write-Host ("[http ] {0,-22} -> {1}" -f $name, $server.url)
        continue
    }

    if ($SkipSmokeTest) {
        Write-Host ("[stdio] {0,-22} -> {1} (smoke test skipped)" -f $name, $server.command)
        continue
    }

    $arguments = @()
    foreach ($arg in $server.args) { $arguments += [string]$arg }

    try {
        $toolNames = Invoke-StdioSmokeTest -Command ([string]$server.command) -Arguments $arguments -WorkingDirectory $projectRoot
        $toolNames = @($toolNames)

        $missing = @($expectedFacadeTools | Where-Object { $_ -notin $toolNames })
        $unexpected = @($toolNames | Where-Object { $_ -notin $expectedFacadeTools })

        if ($missing.Count -gt 0 -or $unexpected.Count -gt 0) {
            $failures++
            Write-Host ("[stdio] {0,-22} -> FAILED: unexpected tool set. Expected {1} tool(s): {2}; got {3}: {4}." -f `
                $name, $expectedFacadeTools.Count, ($expectedFacadeTools -join ", "), $toolNames.Count, ($toolNames -join ", "))
            if ($missing.Count -gt 0) {
                Write-Host ("         Missing: {0}" -f ($missing -join ", "))
            }
            if ($unexpected.Count -gt 0) {
                Write-Host ("         Unexpected: {0}" -f ($unexpected -join ", "))
            }
        }
        else {
            Write-Host ("[stdio] {0,-22} -> OK, tools/list returned {1} tool(s): {2}." -f $name, $toolNames.Count, ($toolNames -join ", "))
        }
    }
    catch {
        $failures++
        Write-Host ("[stdio] {0,-22} -> FAILED: {1}" -f $name, $_.Exception.Message)
        Write-Host ("         (For {0}, confirm its backend is running before treating this as a config error.)" -f $name)
    }
}

if ($failures -gt 0) {
    Write-Host ""
    Write-Host "$failures stdio facade(s) failed the smoke test. Check that the resource-proxy (127.0.0.1:8765) backend is running."
    exit 1
}

Write-Host ""
Write-Host "MCP configuration looks healthy. Start Claude Code from the workspace root and run /mcp to confirm all servers are connected."
exit 0
