# The done gate on Windows PowerShell. Run from this folder: ./check.ps1
# Same four checks as check.sh; see that file for what each one proves.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Invoke-Step($name, $block) {
    Write-Host "== $name"
    & $block
    if ($LASTEXITCODE -ne 0) { throw "$name failed" }
}

Invoke-Step "rojo sourcemap" { rojo sourcemap default.project.json -o sourcemap.json }

$types = "globalTypes.None.d.luau"
$lspVersion = [regex]::Match((luau-lsp --version), "\d+\.\d+\.\d+").Value
$have = ""
if (Test-Path .types-version) { $have = (Get-Content .types-version -Raw).Trim() }
if (-not (Test-Path $types) -or $have -ne $lspVersion) {
    Write-Host "Downloading Roblox API types for luau-lsp $lspVersion (once per version)..."
    Invoke-WebRequest -UseBasicParsing -OutFile $types "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$lspVersion/scripts/globalTypes.None.d.luau"
    Set-Content -Path .types-version -Value $lspVersion -Encoding ascii
}

Invoke-Step "luau-lsp analyze" { luau-lsp analyze --sourcemap=sourcemap.json "--definitions=$types" --ignore "Packages/**" --ignore "ServerPackages/**" --ignore "src/server/Vendor/**" src }
Invoke-Step "selene" { selene src }
Invoke-Step "stylua --check" { stylua --check --respect-ignores src }
Remove-Item sourcemap.json -ErrorAction SilentlyContinue
Write-Host "All checks passed."
