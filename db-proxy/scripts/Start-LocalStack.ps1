[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$serverScript = Join-Path $PSScriptRoot "Start-DbProxyServer.ps1"
if (-not (Test-Path -LiteralPath $serverScript -PathType Leaf)) {
    throw "Cannot find db-proxy server script at $serverScript."
}

Start-Process -FilePath powershell.exe -ArgumentList ('-NoExit -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $serverScript)

Write-Output "SQL backend window started."
