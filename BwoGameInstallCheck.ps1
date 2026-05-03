# Shared by bundled game-config scripts: exit early if no install path matches (OR semantics).
function Assert-BwoGameInstalled {
    param(
        [Parameter(Mandatory)][string]$BundleRoot,
        [Parameter(Mandatory)][string]$ScriptRelativeKey
    )
    $jsonPath = Join-Path $BundleRoot 'game-config-install-paths.json'
    if (-not (Test-Path -LiteralPath $jsonPath)) {
        return
    }
    $j = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $j.scripts) {
        return
    }
    $normKey = $ScriptRelativeKey -replace '\\', '/'
    $prop = $null
    foreach ($p in $j.scripts.PSObject.Properties) {
        $n = $p.Name -replace '\\', '/'
        if ($n -ceq $normKey) {
            $prop = $p
            break
        }
    }
    if ($null -eq $prop) {
        return
    }
    $val = $prop.Value
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($null -eq $val) {
        return
    }
    if ($val -is [System.Array]) {
        foreach ($x in $val) {
            if ($null -ne $x -and -not [string]::IsNullOrWhiteSpace([string]$x)) {
                $candidates.Add([string]$x)
            }
        }
    }
    else {
        $s = [string]$val
        if (-not [string]::IsNullOrWhiteSpace($s)) {
            $candidates.Add($s)
        }
    }
    if ($candidates.Count -eq 0) {
        return
    }
    foreach ($raw in $candidates) {
        $expanded = [Environment]::ExpandEnvironmentVariables($raw.Trim())
        if (Test-Path -LiteralPath $expanded) {
            return
        }
    }
    Write-Host "Spiel nicht installiert" -ForegroundColor Red
    exit 2
}
