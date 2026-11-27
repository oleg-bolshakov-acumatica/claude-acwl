powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "scripts\Start-LocalStack.ps1")
exit $LASTEXITCODE
