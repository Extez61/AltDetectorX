$repo = 'Extez61/AltDetectorX'
$dir  = Join-Path ([IO.Path]::GetTempPath()) 'AltDetectorX'

function Stop-WithError([string]$Message) {
    Write-Host ''
    Write-Host "  AltDetectorX: $Message" -ForegroundColor Red
    Write-Host '  Run the command again. If the problem persists, check your internet connection.' -ForegroundColor DarkGray
    Write-Host '  Komutu tekrar calistirin. Sorun devam ederse internet baglantinizi kontrol edin.' -ForegroundColor DarkGray
    Write-Host ''
    pause
    exit 1
}

if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
    Stop-WithError 'curl.exe not found (Windows 10 1803 or later required) / curl.exe bulunamadi (Windows 10 1803 ve sonrasi gerekir).'
}

Write-Host '  AltDetectorX: downloading / indiriliyor...' -ForegroundColor Cyan

$sha = (& curl.exe -fsS --max-time 15 -H 'Accept: application/vnd.github.sha' "https://api.github.com/repos/$repo/commits/main" 2>$null)
if (-not $sha -or $sha -notmatch '^[0-9a-f]{40}$') { $sha = 'main' }

[void](New-Item -ItemType Directory -Force -Path (Join-Path $dir 'lang'))
foreach ($name in 'AltDetectorX.ps1', 'AltDetectorX.bat') {
    $out = Join-Path $dir $name
    Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
    & curl.exe -fsSL --connect-timeout 10 --max-time 60 --retry 3 -o $out "https://raw.githubusercontent.com/$repo/$sha/$name" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $out) -or (Get-Item -LiteralPath $out).Length -eq 0) {
        Stop-WithError "$name could not be downloaded / indirilemedi."
    }
}

$lang = Join-Path $dir 'lang\en.json'
& curl.exe -fsSL --connect-timeout 10 --max-time 30 --retry 2 -o "$lang.part" "https://raw.githubusercontent.com/$repo/$sha/lang/en.json" 2>$null
if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath "$lang.part")) { Move-Item -LiteralPath "$lang.part" -Destination $lang -Force }
else { Remove-Item -LiteralPath "$lang.part" -Force -ErrorAction SilentlyContinue }

& (Join-Path $dir 'AltDetectorX.bat') @args
exit $LASTEXITCODE
