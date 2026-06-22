# PreToolUse guard for the powershell-mcp-facade SQL tool.
#
# Defense-in-depth only: the resource-proxy backend already enforces read-only
# SQL. This hook gives Claude immediate, local feedback if a non-SELECT query is
# ever attempted, before it reaches the facade.
#
# Contract (Claude Code PreToolUse hook):
#   - stdin  : JSON with { tool_name, tool_input: { query, ... }, ... }
#   - exit 0 : allow the tool call
#   - exit 2 : block the tool call; stderr is returned to the model
#
# Keep this conservative. When in doubt, allow (exit 0) and let the backend be
# the final authority, so legitimate read-only analysis is never stalled.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        exit 0
    }

    $payload = $raw | ConvertFrom-Json
    $query = $null
    if ($payload.PSObject.Properties.Name -contains "tool_input" -and $null -ne $payload.tool_input) {
        if ($payload.tool_input.PSObject.Properties.Name -contains "query") {
            $query = [string]$payload.tool_input.query
        }
    }

    # No query field to inspect -> nothing to guard; let the facade handle it.
    if ([string]::IsNullOrWhiteSpace($query)) {
        exit 0
    }

    # Strip line and block comments so commented-out keywords do not trigger.
    $stripped = [regex]::Replace($query, "(?s)/\*.*?\*/", " ")
    $stripped = [regex]::Replace($stripped, "(?m)--.*$", " ")
    $trimmed = $stripped.Trim()

    # A read-only query must begin with SELECT or a WITH (CTE) clause.
    if ($trimmed -notmatch "^(?is)\s*(SELECT|WITH)\b") {
        [Console]::Error.WriteLine("Blocked: database-access is read-only. Only a single SELECT (optionally a WITH/CTE) is allowed. The query must begin with SELECT or WITH.")
        exit 2
    }

    # Reject statement-changing keywords anywhere in the query body.
    $forbidden = "\b(INSERT|UPDATE|DELETE|MERGE|DROP|ALTER|TRUNCATE|CREATE|GRANT|REVOKE|EXEC|EXECUTE|BACKUP|RESTORE|sp_[A-Za-z]|xp_[A-Za-z])\b"
    $match = [regex]::Match($stripped, "(?i)$forbidden")
    if ($match.Success) {
        [Console]::Error.WriteLine("Blocked: database-access is read-only. Detected a state-changing or administrative SQL keyword ('$($match.Value)'). Use SELECT-only diagnostic queries.")
        exit 2
    }

    exit 0
}
catch {
    # Never let a guard error stall legitimate analysis; defer to the backend.
    exit 0
}
