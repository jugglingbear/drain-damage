# Run from the extracted Windows package. No editor or repository is required.
$ErrorActionPreference = 'Stop'
$game = Join-Path $PSScriptRoot 'Drain Damage.exe'
$manifest = Get-Content (Join-Path $PSScriptRoot 'release-manifest.json') -Raw | ConvertFrom-Json
foreach ($file in $manifest.files.PSObject.Properties) {
    $actual = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $file.Name) -Algorithm SHA256).Hash
    if ($actual -ne $file.Value) { throw "Package checksum mismatch: $($file.Name)" }
}
$logs = Join-Path $PSScriptRoot ('test-results-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $logs | Out-Null
foreach ($target in @('1', '2', '2-landing', '2.1', '2-12', '2-13')) {
    foreach ($hero in @('tony', 'sean')) {
        $log = Join-Path $logs "$target-$hero.log"
        $arguments = @('--headless', '--log-file', "`"$log`"", '--', "--level=$target",
            "--hero=$hero", '--difficulty=normal', '--seed=42', '--verify-playtest-launch')
        $process = Start-Process -FilePath $game -ArgumentList $arguments -PassThru
        if (-not $process.WaitForExit(120000)) {
            $process.Kill()
            throw "Timed out: $target / $hero; see $logs"
        }
        $process.Refresh()
        $text = Get-Content -LiteralPath $log -Raw
        # Existing verification shutdown leaks are recorded separately from initialization failures.
        $errors = @($text -split '\r?\n' | Where-Object {
            $_ -match 'ERROR:' -and $_ -notmatch '^ERROR: [0-9]+ resources still in use at exit'
        })
        if ($text -match 'resources still in use at exit') {
            Write-Warning "Existing shutdown resource warning: $log"
        }
        if ($process.ExitCode -ne 0 -or $errors.Count -gt 0 -or $text -notmatch 'PASS: playtest launch') {
            throw "Failed: $target / $hero; see $log"
        }
        Write-Host "PASS: $target / $hero"
    }
}
Write-Host "Headless initialization checks passed. Logs: $logs"
Write-Host 'Graphics, audio, keyboard/controller input and full gameplay still require a playtest.'
