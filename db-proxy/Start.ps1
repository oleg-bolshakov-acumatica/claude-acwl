[CmdletBinding()]
param()

# Thin wrapper: run the DB proxy HTTP server in the current process (foreground).
# Logs go to stderr. Stop with Ctrl+C. For auto-start before a Claude session,
# scripts/Start-Claude.ps1 launches this server in a separate window.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "scripts\Start-DbProxyServer.ps1")
