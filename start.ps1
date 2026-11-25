# AltDetectorX baslatici
# README'deki kisa komut bu dosyayi indirip calistirir. Yaptigi is:
#   1. GitHub'dan son commit'i sorar (GitHub'in 5 dakikalik onbellegine takilmamak icin)
#   2. AltDetectorX.ps1 ve AltDetectorX.bat dosyalarini o commit'ten %TEMP%\AltDetectorX klasorune indirir
#   3. AltDetectorX.bat'i ayni terminalde calistirir
# Internete veri gondermez; sadece bu repodaki iki dosyayi indirir.

$repo = 'Extez61/AltDetectorX'
$dir  = Join-Path ([IO.Path]::GetTempPath()) 'AltDetectorX'

function Stop-WithError([string]$Message) {
    Write-Host ''
    Write-Host "  AltDetectorX: $Message" -ForegroundColor Red
    Write-Host '  Komutu tekrar calistirin. Sorun devam ederse internet baglantinizi kontrol edin.' -ForegroundColor DarkGray
    Write-Host ''
    pause
    exit 1
}

if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
    Stop-WithError 'curl.exe bulunamadi (Windows 10 1803 ve sonrasi gerekir).'
}

Write-Host '  AltDetectorX indiriliyor...' -ForegroundColor Cyan

# Son commit (bulunamazsa 'main' kullanilir)
$sha = (& curl.exe -fsS --max-time 15 -H 'Accept: application/vnd.github.sha' "https://api.github.com/repos/$repo/commits/main" 2>$null)
if (-not $sha -or $sha -notmatch '^[0-9a-f]{40}$') { $sha = 'main' }

[void](New-Item -ItemType Directory -Force -Path $dir)
foreach ($name in 'AltDetectorX.ps1', 'AltDetectorX.bat') {
    $out = Join-Path $dir $name
    Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
    & curl.exe -fsSL --connect-timeout 10 --max-time 60 --retry 3 -o $out "https://raw.githubusercontent.com/$repo/$sha/$name" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $out) -or (Get-Item -LiteralPath $out).Length -eq 0) {
        Stop-WithError "$name indirilemedi."
    }
}

# Yeni pencere acmadan, ayni terminalde calistir
& (Join-Path $dir 'AltDetectorX.bat') @args
exit $LASTEXITCODE
