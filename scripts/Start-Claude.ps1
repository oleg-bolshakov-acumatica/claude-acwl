[CmdletBinding()]
param(
    [switch]$SkipProxy,
    [switch]$ProxyOnly,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ClaudeArgs
)

# Convenience launcher for this workspace.
#
# Claude Code reads .mcp.json natively, so there is no MCP registration step.
# This wrapper (1) ensures the local read-only SQL backend (db-proxy) is running
# before the session, and (2) starts Claude with the workspace root as the
# working directory, which is what the relative MCP startup paths in .mcp.json
# rely on.
#
#   -SkipProxy   do not touch the db-proxy (assume it is managed elsewhere).
#   -ProxyOnly   only ensure the db-proxy is up, then exit (do not start Claude).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$expectedDbProxyBackendVersion = "db-proxy-0.2.0"

function Get-DbProxyBaseUrl {
    param([Parameter(Mandatory)] [string]$ProjectRoot)

    $configPath = Join-Path $ProjectRoot "db-proxy/config/db-proxy.config.json"
    if (-not (Test-Path -LiteralPath $configPath)) {
        return "http://127.0.0.1:8765"
    }

    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if ($null -ne $config.http -and -not [string]::IsNullOrWhiteSpace([string]$config.http.baseUrl)) {
        return ([string]$config.http.baseUrl).TrimEnd("/")
    }

    return "http://127.0.0.1:8765"
}

function Get-DbProxyStatus {
    param([Parameter(Mandatory)] [string]$BaseUrl)

    try {
        $status = Invoke-RestMethod -Uri ("{0}/status" -f $BaseUrl) -Method Get -TimeoutSec 3 -ErrorAction Stop
        if ($null -ne $status -and [bool]$status.ok) {
            return $status
        }

        return $null
    }
    catch {
        return $null
    }
}

function Assert-ExpectedDbProxy {
    param(
        [Parameter(Mandatory)] $Status,
        [Parameter(Mandatory)] [string]$BaseUrl,
        [Parameter(Mandatory)] [string]$ExpectedBackendVersion
    )

    $backendVersion = ""
    if ($null -ne $Status.result -and $null -ne $Status.result.backendVersion) {
        $backendVersion = [string]$Status.result.backendVersion
    }

    if ($backendVersion -ne $ExpectedBackendVersion) {
        throw ("[db-proxy] {0}/status reports backendVersion='{1}', expected '{2}'. Stop the process using that endpoint or update db-proxy/config/db-proxy.config.json before starting Claude Code." -f $BaseUrl, $backendVersion, $ExpectedBackendVersion)
    }
}

function Ensure-DbProxy {
    param(
        [Parameter(Mandatory)] [string]$ProjectRoot,
        [int]$TimeoutSec = 15
    )

    $baseUrl = Get-DbProxyBaseUrl -ProjectRoot $ProjectRoot

    $status = Get-DbProxyStatus -BaseUrl $baseUrl
    if ($null -ne $status) {
        Assert-ExpectedDbProxy -Status $status -BaseUrl $baseUrl -ExpectedBackendVersion $expectedDbProxyBackendVersion
        Write-Host ("[db-proxy] already running on {0}." -f $baseUrl)
        return
    }

    $proxyLauncher = Join-Path $ProjectRoot "db-proxy/Start.ps1"
    if (-not (Test-Path -LiteralPath $proxyLauncher -PathType Leaf)) {
        throw "Cannot find db-proxy launcher at $proxyLauncher."
    }

    Write-Host ("[db-proxy] not responding on {0}; starting it in a new window..." -f $baseUrl)
    & $proxyLauncher
    if ($LASTEXITCODE -ne 0) {
        throw "The db-proxy launcher exited with code $LASTEXITCODE."
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        $status = Get-DbProxyStatus -BaseUrl $baseUrl
        if ($null -ne $status) {
            Assert-ExpectedDbProxy -Status $status -BaseUrl $baseUrl -ExpectedBackendVersion $expectedDbProxyBackendVersion
            Write-Host ("[db-proxy] is up on {0}." -f $baseUrl)
            return
        }
    }

    Write-Warning ("[db-proxy] did not report healthy on {0} within {1}s. SQL tools may fail until it is up." -f $baseUrl, $TimeoutSec)
}

try {
    if (-not $SkipProxy) {
        Ensure-DbProxy -ProjectRoot $projectRoot
    }

    if ($ProxyOnly) {
        exit 0
    }

    $claudeCommand = Get-Command claude.cmd -ErrorAction SilentlyContinue
    if ($null -eq $claudeCommand) {
        $claudeCommand = Get-Command claude -ErrorAction Stop
    }

    Push-Location $projectRoot
    try {
        & $claudeCommand.Source @ClaudeArgs
    }
    finally {
        Pop-Location
    }
    exit $LASTEXITCODE
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
