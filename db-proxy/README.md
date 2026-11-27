# db-proxy - read-only SQL backend for the MCP facade

A light, SQL-only backend for the `powershell-mcp-facade` stdio MCP server in this
workspace. It is the trimmed successor of the full resource proxy backend: it keeps the
exact same HTTP contract the facade expects, but exposes **only** read-only SQL.

## What it is

The facade (`core/BackendClient.psm1`) forwards read-only SQL tool calls to this proxy
over localhost HTTP. This proxy uses `System.Data.SqlClient` with integrated authentication
for bounded reads and metadata discovery. Jira/Wiki/Bitbucket providers from the full proxy
are intentionally absent.

## HTTP contract

- `GET /health` -> `{ ok: true, status: "ok" }`
- `GET /status` -> `{ ok: true, result: { status, mode, backendAvailable, backendVersion } }`
- `POST /invoke` with one of `sql.select`, `sql.list_databases`, `sql.search_schema`, or
  `sql.describe_table` and its documented arguments.

Supported operations: `ping`, `get_status`, `sql.select`, `sql.list_databases`,
`sql.search_schema`, and `sql.describe_table`. Any other operation returns
`unknown_operation`.

The bind address is `http://127.0.0.1:8765`, matching the workspace
`config/server.config.json`
(`backend.http.baseUrl`) so the facade connects with no further changes.

## Layout

```text
db-proxy/
  Start.ps1                       # runs scripts/Start-LocalStack.ps1
  config/
    db-proxy.config.json          # http { baseUrl, requestTimeoutSec } + resourceProxy { serverName, logRequests }
    providers.config.json         # sql { aliases, optional allowlists, execution limits }
  core/
    Config.psm1                   # config loaders
    ResourceProxyTransport.psm1   # Get-ResourceProxySettings
  providers/
    Sql.Provider.psm1             # SELECT, database discovery, and schema metadata
  scripts/
    Start-LocalStack.ps1          # opens the backend window with PowerShell -NoExit
    Start-DbProxyServer.ps1       # HTTP listener for read-only SQL operations
    Smoke-Test-DbProxy.ps1        # direct POST /invoke sql.select smoke test
```

## Read-only enforcement

`Sql.Provider.psm1` (`Test-SqlSelectSafety`) allows a single `SELECT` statement only and
rejects multiple statements, `SELECT INTO`, and write/administrative keywords.
This mirrors the workspace's `PreToolUse` SQL guard hook (`scripts/hooks/Guard-Sql.ps1`),
giving defense-in-depth. SQL runs under the current Windows identity (integrated auth);
no credentials are stored here.

## Running

In File Explorer, right-click `db-proxy/Start.ps1` and select **Run with PowerShell**.
The launcher opens a separate PowerShell window for the backend logs. It stays
open after the backend script exits. Close the backend window to stop the server.

From an open PowerShell session, run the same launcher:

```powershell
.\db-proxy\Start.ps1
```

Start the backend once and keep its window open; every session reuses it, and
SQL calls succeed again without a client restart once it is up. The optional
`scripts/Start-Claude.ps1` launcher calls the same script when the proxy is down.

To keep the backend in the current window instead, for example while debugging
(logs on stderr; Ctrl+C to stop), run the server script directly:

```powershell
.\db-proxy\scripts\Start-DbProxyServer.ps1
```

Smoke test (proxy must be running):

```powershell
db-proxy/scripts/Smoke-Test-DbProxy.ps1                 # SELECT 1
db-proxy/scripts/Smoke-Test-DbProxy.ps1 -Database MyDb -Query "SELECT TOP 1 * FROM COMPANY"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Smoke-Test-Sql-Discovery.ps1
```

## Notes

- Only one process can bind `127.0.0.1:8765`. The light `db-proxy` and any other local
  proxy using that port are mutually exclusive; the auto-start logic does not start a second
  one if `/status` already responds.
- Configuration knobs live in `db-proxy/config/providers.config.json` (`sql` block): change
  `defaultServer`, add `aliases`, optionally configure server/database allowlists, or adjust
  the execution limits. Empty allowlists intentionally allow arbitrary SQL Server and database names.
- SQL uses `System.Data.SqlClient` and the current Windows identity; no SQL credentials or
  access tokens are stored in this workspace.
