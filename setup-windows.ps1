param([switch]$NoLaunch)
$ErrorActionPreference = 'Stop'
try {
    $root = $PSScriptRoot
    $manifest = Get-Content -LiteralPath (Join-Path $root 'manifest.json') -Raw | ConvertFrom-Json
    $appDir = Join-Path $root 'LED-Button-Arcade'
    $exe = Join-Path $appDir 'LED Button Arcade.exe'
    if (-not (Test-Path -LiteralPath $exe)) {
        $zip = Join-Path $root 'LED-Button-Arcade.zip'
        Write-Host 'Preparing Windows game. Please wait...'
        $output = [System.IO.File]::Create($zip)
        try {
            foreach ($part in $manifest.parts) {
                $partPath = Join-Path $root $part
                if (-not (Test-Path -LiteralPath $partPath)) { throw "Missing file: $part. Download the entire repository ZIP and extract it first." }
                $inputFile = [System.IO.File]::OpenRead($partPath)
                try { $inputFile.CopyTo($output) } finally { $inputFile.Dispose() }
            }
        } finally { $output.Dispose() }
        if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $manifest.sha256) { throw 'Archive checksum mismatch. Please download again.' }
        $staging = Join-Path $root ('extract-' + [Guid]::NewGuid().ToString('N'))
        Expand-Archive -LiteralPath $zip -DestinationPath $staging
        if (Test-Path -LiteralPath $appDir) { throw 'LED-Button-Arcade folder already exists. Rename that folder and try again.' }
        Move-Item -LiteralPath $staging -Destination $appDir
    }
    if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne $manifest.exeSha256) { throw 'Executable checksum mismatch. Please download again.' }
    if (-not $NoLaunch) { Start-Process -FilePath $exe -WorkingDirectory $appDir }
    Write-Host 'Ready: LED Button Arcade.exe'
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
