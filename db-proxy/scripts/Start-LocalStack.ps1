[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$expectedBackendVersion = "db-proxy-0.2.0"

$serverScript = Join-Path $PSScriptRoot "Start-DbProxyServer.ps1"
if (-not (Test-Path -LiteralPath $serverScript -PathType Leaf)) {
    throw "Cannot find db-proxy server script at $serverScript."
}

function Get-PropertyValue {
    param($Object, [string]$Name)

    if ($null -eq $Object -or $null -eq $Object.PSObject.Properties[$Name]) {
        return $null
    }

    return $Object.$Name
}

$baseUrl = "http://127.0.0.1:8765"
$configPath = Join-Path $PSScriptRoot "..\config\db-proxy.config.json"
if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    $configuredUrl = [string](Get-PropertyValue -Object (Get-PropertyValue -Object (Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json) -Name "http") -Name "baseUrl")
    if (-not [string]::IsNullOrWhiteSpace($configuredUrl)) {
        $baseUrl = $configuredUrl.TrimEnd("/")
    }
}

$status = $null
try {
    $status = Invoke-RestMethod -Uri ("{0}/status" -f $baseUrl) -Method Get -TimeoutSec 3 -ErrorAction Stop
}
catch {
    $status = $null
}

if ($null -ne $status) {
    $backendVersion = [string](Get-PropertyValue -Object (Get-PropertyValue -Object $status -Name "result") -Name "backendVersion")
    if ($backendVersion -ne $expectedBackendVersion) {
        throw ("{0}/status reports backendVersion='{1}', expected '{2}'. Stop the process using that endpoint or change db-proxy/config/db-proxy.config.json." -f $baseUrl, $backendVersion, $expectedBackendVersion)
    }

    Write-Output ("SQL backend is already running on {0}." -f $baseUrl)
    return
}

Start-Process -FilePath powershell.exe -ArgumentList ('-NoExit -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $serverScript)

Write-Output "SQL backend window started."
