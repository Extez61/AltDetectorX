param(
    [ValidateSet('Quick', 'Normal', 'Deep')]
    [string]$Mode = 'Normal',
    [switch]$Paths,
    [int]$Threads = 0,
    [string]$Export,
    [switch]$NoWsl,
    [switch]$NoMenu,
    [switch]$NoElevate
)
$script:EncProbe = 'ğüİ'
if ($script:EncProbe -cne ([string][char]0x011F + [char]0x00FC + [char]0x0130)) {
    if ($env:ALTDETECTORX_ENCFIX -ne '1') {
        $encRoot = {}.Ast
        while ($null -ne $encRoot.Parent) { $encRoot = $encRoot.Parent }
        $encText = [Text.Encoding]::UTF8.GetString([Text.Encoding]::Default.GetBytes($encRoot.Extent.Text))
        $env:ALTDETECTORX_ENCFIX = '1'
        $env:ALTDETECTORX_SELF = $PSCommandPath
        try { & ([scriptblock]::Create($encText)) @PSBoundParameters } finally { $env:ALTDETECTORX_ENCFIX = $null; $env:ALTDETECTORX_SELF = $null }
        return
    }
}
$script:ParamGiven = $false
$script:ForwardArgs = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
if ($null -ne $PSBoundParameters) {
    foreach ($kv in $PSBoundParameters.GetEnumerator()) {
        if ($kv.Key -eq 'NoElevate') { continue }
        $script:ParamGiven = $true
        if ($kv.Value -is [System.Management.Automation.SwitchParameter]) {
            if ($kv.Value.IsPresent) { $script:ForwardArgs.Add("-$($kv.Key)") }
        } else {
            $script:ForwardArgs.Add(("-{0} '{1}'" -f $kv.Key, ([string]$kv.Value -replace "'", "''")))
        }
    }
}
$script:ForwardArgs.Add('-NoElevate')

$script:OrigEAP = $ErrorActionPreference
$script:zq1 = 55, 59, 62, 63
$ErrorActionPreference = 'SilentlyContinue'
$script:StartTime = [DateTime]::Now

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    Microsoft.PowerShell.Utility\Write-Host 'AltDetectorX sadece Windows üzerinde çalışır.' -ForegroundColor Red
    return
}

$script:Report = Microsoft.PowerShell.Utility\New-Object System.Text.StringBuilder
$script:zq3 = 36, 63, 34, 46
$script:OrigEncoding = $null
try { $script:OrigEncoding = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }

# Konsolu koyu temaya sabitle: arka plan siyah, normal yazı açık gri (beyaza yakın).
# Vurgu renkleri (başlık mavi/camgöbeği, uyarılar kırmızı/sarı, güvenli yeşil) olduğu gibi kalır.
$script:OrigBg = $null; $script:OrigFg = $null
try { $script:OrigBg = [Console]::BackgroundColor; $script:OrigFg = [Console]::ForegroundColor } catch { }
function Set-DarkBase {
    try { [Console]::BackgroundColor = [ConsoleColor]::Black; [Console]::ForegroundColor = [ConsoleColor]::Gray } catch { }
}
Set-DarkBase
try { [Console]::Clear() } catch { }

$script:MarginX = 2
$script:MarginText = ' ' * $script:MarginX
$script:OutAtStart = $true
function Get-OutWidth {
    $w = 100
    try { $w = [Console]::WindowWidth - $script:MarginX - 3 } catch { }
    return [Math]::Max(40, [Math]::Min(160, $w))
}

function Split-Wrap([string]$Text, [int]$Width, [string]$Indent) {
    $lines = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
    if ($Indent.Length -gt $Width - 20) { $Indent = ' ' * 4 }
    $cur = $Text
    $minCut = $Indent.Length + 10
    while ($cur.Length -gt $Width) {
        $cut = $cur.LastIndexOf([char]32, $Width)
        if ($cut -lt $minCut) {
            $cut = $cur.LastIndexOf([char]92, $Width - 1)
            if ($cut -ge $minCut) { $cut++ } else { $cut = $Width }
        }
        $lines.Add($cur.Substring(0, $cut).TrimEnd())
        $cur = $Indent + $cur.Substring($cut).TrimStart()
    }
    $lines.Add($cur)
    return , $lines
}

function Out-Line {
    param([string]$Text = '', [string]$Color = 'Gray', [switch]$NoNewline, [string]$Indent)
    if (-not $NoNewline -and $script:OutAtStart -and $Text) {
        $w = Get-OutWidth
        if ($Text.Length -gt $w) {
            if (-not $PSBoundParameters.ContainsKey('Indent')) { $Indent = ' ' * (($Text.Length - $Text.TrimStart().Length) + 2) }
            foreach ($ln in (Split-Wrap $Text $w $Indent)) {
                $t = $script:MarginText + $ln
                Microsoft.PowerShell.Utility\Write-Host $t -ForegroundColor $Color
                [void]$script:Report.AppendLine($t)
            }
            $script:OutAtStart = $true
            return
        }
    }
    $t = $Text
    if ($script:OutAtStart -and $t) { $t = $script:MarginText + $t }
    if ($NoNewline) {
        Microsoft.PowerShell.Utility\Write-Host $t -ForegroundColor $Color -NoNewline
        [void]$script:Report.Append($t)
        if ($t) { $script:OutAtStart = $false }
    } else {
        Microsoft.PowerShell.Utility\Write-Host $t -ForegroundColor $Color
        [void]$script:Report.AppendLine($t)
        $script:OutAtStart = $true
    }
}

$script:SigCache = $null
function Get-Sig {
    if ($script:SigCache) { return $script:SigCache }
    $script:SigCache = Get-SigUncached
    return $script:SigCache
}

function Get-SigUncached {
    $k = 0x5A
    $cand = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
    try {
        $b = @($script:zq1 + $script:zq2 + $script:zq3 + $script:zq4)
        $c = foreach ($x in $b) { [char]([int]$x -bxor $k) }
        $cand.Add(-join $c)
    } catch { }
    try { $cand.Add([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($script:zqB))) } catch { }
    try { $cand.Add(-join ($script:zqD | Microsoft.PowerShell.Core\ForEach-Object { [char][int]$_ })) } catch { }
    try {
        $sha = [Security.Cryptography.SHA256]::Create()
        foreach ($s in $cand) {
            if (-not $s) { continue }
            $h = ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s)) | Microsoft.PowerShell.Core\ForEach-Object { $_.ToString('x2') }) -join ''
            if ($h -eq $script:zqH) { $sha.Dispose(); return $s }
        }
        $sha.Dispose()
    } catch { }
    return ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('bWFkZSBieSB+ZXh0ZXo2MTA=')))
}

function Get-SigPadded([int]$Width) {
    $s = Get-Sig
    if ($Width -lt ($s.Length + 3)) { return '  ' + $s }
    return $s.PadLeft($Width - 1)
}

$script:Tui = $false
try { $script:Tui = ($Host.Name -eq 'ConsoleHost') -and -not [Console]::IsOutputRedirected -and -not [Console]::IsInputRedirected } catch { }
$script:LastTick = 0
$script:zq2 = 122, 56, 35, 122
$script:Recent = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.Queue[string]
$script:UiPhase = ''; $script:UiPhaseNo = 0; $script:UiPhaseTotal = 7
$script:UiWidth = 0; $script:UiHeight = 0
$script:ScanStart = [DateTime]::Now
$script:ModeLabel = @{ Quick = 'Hızlı Tarama'; Normal = 'Normal Tarama'; Deep = 'Tam Tarama' }
$script:WalkTotal = 0; $script:WalkDone = 0
$script:UniqueNames = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$script:Settings = [pscustomobject]@{ Threads = 4; Reason = ''; CapRelevant = 512MB; CapOther = 64MB }

$CH_FULL = [string][char]0x2588; $CH_LIGHT = [string][char]0x2591; $CH_LINE = [string][char]0x2500; $CH_ARROW = [string][char]0x203A

function Format-Fit([string]$Text, [int]$Width) {
    if ($Width -lt 1) { return '' }
    if ($null -eq $Text) { $Text = '' }
    if ($Text.Length -gt $Width) {
        if ($Width -gt 6) { return $Text.Substring(0, 4) + '...' + $Text.Substring($Text.Length - ($Width - 7)) }
        return $Text.Substring(0, $Width)
    }
    return $Text.PadRight($Width)
}

function Add-Recent([string]$P) {
    if (-not $P) { return }
    $script:Recent.Enqueue($P)
    while ($script:Recent.Count -gt 40) { [void]$script:Recent.Dequeue() }
}

$script:UiActive = $false
$script:LastActivity = ''; $script:LastStatus = ''; $script:LastPercent = -1

function Start-Ui {
    $script:ScanStart = [DateTime]::Now
    $script:UiActive = $true
    if (-not $script:Tui) { return }
    try { [Console]::Clear(); [Console]::CursorVisible = $false } catch { }
    $script:UiWidth = 0
}

function Stop-Ui {
    $script:UiActive = $false
    Microsoft.PowerShell.Utility\Write-Progress -Id 1 -Activity 'Bitti' -Completed
    if (-not $script:Tui) { return }
    try { Set-DarkBase; [Console]::Clear(); [Console]::CursorVisible = $true } catch { }
}

function Set-Phase([int]$No, [string]$Title) {
    $script:UiPhaseNo = $No; $script:UiPhase = $Title
    Show-Progress -Activity $Title -Status '' -Force
}

function Write-At([int]$Row, [string]$Text, [ConsoleColor]$Color) {
    [Console]::SetCursorPosition($script:MarginX, $Row)
    [Console]::BackgroundColor = [ConsoleColor]::Black
    [Console]::ForegroundColor = $Color
    [Console]::Write((Format-Fit $Text $script:UiInner))
}

function Show-Frame([string]$Activity, [string]$Status, [int]$Percent) {
    try {
        $w = [Console]::WindowWidth - 1
        $h = [Console]::WindowHeight
        if ($w -ne $script:UiWidth -or $h -ne $script:UiHeight) {
            [Console]::Clear(); $script:UiWidth = $w; $script:UiHeight = $h
        }
        $w = $w - (2 * $script:MarginX)
        $script:UiInner = $w
        $top = [Console]::WindowTop
        $el = [DateTime]::Now - $script:ScanStart
        $row = $top + 1
        Write-At ($row++) ("  AltDetectorX  {0}  {1}  {0}  {2:hh\:mm\:ss}" -f [char]0x00B7, $script:ModeLabel[$Mode], $el) 'Cyan'
        Write-At ($row++) ('  ' + ($CH_LINE * [Math]::Max(1, $w - 4))) 'DarkCyan'
        Write-At ($row++) ("  Aşama {0}/{1}: {2}" -f $script:UiPhaseNo, $script:UiPhaseTotal, $Activity) 'White'

        $bw = [Math]::Max(10, [Math]::Min(60, $w - 14))
        if ($Percent -ge 0) {
            $p = [Math]::Min(100, $Percent)
            $fill = [int][Math]::Floor($bw * $p / 100)
            $bar = ($CH_FULL * $fill) + ($CH_LIGHT * ($bw - $fill))
            Write-At ($row++) ("  [{0}] {1,3}%" -f $bar, $p) 'Green'
        } else {
            $seg = 8
            $pos = [int](([Environment]::TickCount -band 0x7FFFFFFF) / 70) % ($bw + $seg)
            $sb = Microsoft.PowerShell.Utility\New-Object System.Text.StringBuilder
            for ($i = 0; $i -lt $bw; $i++) { if ($i -ge $pos - $seg -and $i -lt $pos) { [void]$sb.Append($CH_FULL) } else { [void]$sb.Append($CH_LIGHT) } }
            Write-At ($row++) ("  [{0}]  ..." -f $sb.ToString()) 'Green'
        }
        Write-At ($row++) ("  " + $Status) 'Gray'

        $secs = [Math]::Max(0.5, $el.TotalSeconds)
        $accColor = 'Gray'; if ($script:UniqueNames.Count -gt 0) { $accColor = 'Magenta' }
        Write-At ($row++) ("  Bulunan hesap : {0}" -f $script:UniqueNames.Count) $accColor
        Write-At ($row++) ("  Uyarı         : {0}" -f $script:Alerts.Count) 'Gray'
        Write-At ($row++) ("  Klasör / log  : {0:N0} / {1:N0}" -f $script:DirCount, $script:Found.Logs.Count) 'Gray'
        Write-At ($row++) ("  Hız           : {0:N0} klasör/sn, {1} iş parçacığı" -f ($script:DirCount / $secs), $script:Settings.Threads) 'Gray'
        Write-At ($row++) ('  ' + ($CH_LINE * [Math]::Max(1, $w - 4))) 'DarkCyan'
        Write-At ($row++) '  Son taranan yerler:' 'DarkGray'

        $sigRow = $top + $h - 2
        $n = [Math]::Max(1, [Math]::Min(18, $sigRow - $row - 1))
        $arr = $script:Recent.ToArray()
        for ($i = 0; $i -lt $n; $i++) {
            $t = ''
            if ($i -lt $arr.Count) { $t = "   $CH_ARROW " + $arr[$arr.Count - 1 - $i] }
            $c = 'DarkGray'; if ($i -eq 0) { $c = 'White' }
            Write-At ($row++) $t $c
        }
        if ($sigRow -gt $row) { Write-At $sigRow (Get-SigPadded $w) 'DarkGray' }
        Set-DarkBase
    } catch { $script:Tui = $false }
}

function Show-Progress {
    param([int]$Id = 1, [string]$Activity, [string]$Status, [int]$Percent = -1, [string]$Recent, [switch]$Force)
    # Son durum saklanır; uzun süren dış komutlar beklenirken Update-UiTick ekranı bununla yeniden çizer.
    $script:LastActivity = $Activity; $script:LastStatus = $Status; $script:LastPercent = $Percent
    $now = [Environment]::TickCount
    if (-not $Force -and [Math]::Abs($now - $script:LastTick) -lt 100) { return }
    $script:LastTick = $now
    if ($Recent) { Add-Recent $Recent }
    if (-not $Activity) { $Activity = $script:UiPhase }
    if ($script:Tui) { Show-Frame $Activity $Status $Percent; return }
    $st = $Status; if ($Recent) { $st = "$Status  |  $Recent" }; if (-not $st) { $st = '...' }
    if ($Percent -ge 0) {
        Microsoft.PowerShell.Utility\Write-Progress -Id $Id -Activity $Activity -Status $st -PercentComplete ([Math]::Min(100, $Percent))
    } else {
        Microsoft.PowerShell.Utility\Write-Progress -Id $Id -Activity $Activity -Status $st
    }
}

# Ekranı (süre, animasyonlu çubuk) son bilinen durumla yeniler. Uzun süren bekleme döngülerinden çağrılır;
# Show-Progress kendi içinde 100 ms'de bir çizecek şekilde sınırlandığı için sık çağrılması sorun değildir.
function Update-UiTick {
    if (-not $script:UiActive) { return }
    $a = $script:LastActivity; $s = $script:LastStatus; $p = $script:LastPercent
    Show-Progress -Activity $a -Status $s -Percent $p
}

$C_T = [string][char]0x251C + [char]0x2500 + ' '
$C_L = [string][char]0x2514 + [char]0x2500 + ' '
$C_V = [string][char]0x2502 + '  '
$C_S = '   '

function Get-MaxDate($Items) {
    $m = $null
    foreach ($i in $Items) { $d = $i.Date; if ($null -eq $d) { $d = $i.LastWriteTime }; if ($null -ne $d -and ($null -eq $m -or $d -gt $m)) { $m = $d } }
    return $m
}
function Get-MinDate($Items) {
    $m = $null
    foreach ($i in $Items) { $d = $i.Date; if ($null -eq $d) { $d = $i.LastWriteTime }; if ($null -ne $d -and ($null -eq $m -or $d -lt $m)) { $m = $d } }
    return $m
}

$script:Accounts = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
$script:Alerts = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]

function Add-Account {
    param([string]$Name, [string]$Launcher, [string]$Detail, [string]$Source, [string]$Path, [datetime]$Date)
    if ([string]::IsNullOrWhiteSpace($Name)) { return }
    $Name = $Name.Trim().Trim("'", '"', ',', ';')
    if ($Name.Length -lt 1 -or $Name.Length -gt 32) { return }
    [void]$script:UniqueNames.Add($Name)
    $script:Accounts.Add([pscustomobject]@{
            Name = $Name; Launcher = $Launcher; Detail = $Detail; Source = $Source; Path = $Path; Date = $Date
        })
}

function Add-Alert {
    param([ValidateSet('Yüksek', 'Orta', 'Bilgi')][string]$Level, [string]$Title, [string]$Detail)
    $script:Alerts.Add([pscustomobject]@{ Level = $Level; Title = $Title; Detail = $Detail })
}

$script:LauncherRules = @(
    @('\\\.lunarclient\\', 'Lunar Client'),
    @('\\blclient\\|\\Badlion Client\\', 'Badlion Client'),
    @('\\\.?feather\\|\\Feather Launcher\\', 'Feather Client'),
    @('\\labymod[^\\]*\\', 'LabyMod'),
    @('\\PrismLauncher\\', 'Prism Launcher'),
    @('\\PolyMC\\', 'PolyMC'),
    @('\\MultiMC[^\\]*\\', 'MultiMC'),
    @('\\ATLauncher\\', 'ATLauncher'),
    @('\\gdlauncher[^\\]*\\', 'GDLauncher'),
    @('\\curseforge\\minecraft\\', 'CurseForge'),
    @('\\ModrinthApp\\|\\com\.modrinth\.theseus\\', 'Modrinth App'),
    @('\\\.?ftba\\|\\FTB App\\', 'FTB App'),
    @('\\\.technic\\', 'Technic Launcher'),
    @('\\salwyrr[^\\]*\\', 'Salwyrr'),
    @('\\\.?tlauncher\\', 'TLauncher'),
    @('\\\.?sklauncher\\', 'SKLauncher'),
    @('\\Packages\\Microsoft\.4297127D64EC6_[^\\]+\\', 'Minecraft Launcher (MS Store)'),
    @('\\\.hmcl\\|\\\.?hmcl\.json$', 'HMCL'),
    @('\\PollyMC\\', 'PollyMC'),
    @('\\FjordLauncher\\', 'Fjord Launcher'),
    @('\\ElyPrismLauncher\\', 'ElyPrism Launcher'),
    @('\\FreesmLauncher\\', 'Freesm Launcher'),
    @('\\UltimMC[^\\]*\\', 'UltimMC'),
    @('\\xmcl\\', 'X Minecraft Launcher'),
    @('\\CCBlueX\\LiquidLauncher\\', 'LiquidLauncher'),
    @('\\\.minecraft\\', '.minecraft')
)
$script:RelevantPathRx = '(?i)(\\\.minecraft\\|lunarclient|feather|badlion|blclient|labymod|prismlauncher|polymc|multimc|atlauncher|gdlauncher|curseforge|modrinth|ftba|\\ftb app\\|technic|salwyrr|tlauncher|sklauncher|4297127d64ec6|minecraft|\\\.hmcl\\|\.?hmcl\.json$|pollymc|fjordlauncher|elyprismlauncher|freesmlauncher|ultimmc|\\xmcl\\|liquidlauncher|\\liquidbounce\\|\\meteor-client\\|\\wurst\\)'
$script:RecycleMap = @{}
$script:CurrentUser = $env:USERNAME

function Resolve-OriginalPath([string]$Path) {
    if ($Path -and $Path.StartsWith('\\?\GLOBALROOT\', [StringComparison]::OrdinalIgnoreCase)) {
        foreach ($k in $script:ShadowMap.Keys) {
            if ($Path.StartsWith($k + '\', [StringComparison]::OrdinalIgnoreCase)) { return $script:ShadowMap[$k][0] + $Path.Substring($k.Length) }
        }
    }
    foreach ($k in $script:RecycleMap.Keys) {
        if ($Path.StartsWith($k, [StringComparison]::OrdinalIgnoreCase)) {
            return $script:RecycleMap[$k] + $Path.Substring($k.Length)
        }
    }
    return $Path
}

function Get-LauncherInfo {
    param([string]$Path, [string[]]$Hints = @())
    $orig = Resolve-OriginalPath $Path
    $launcher = $null
    foreach ($r in $script:LauncherRules) {
        if ($orig -match "(?i)$($r[0])") { $launcher = $r[1]; break }
    }
    $detail = ''
    if ($launcher -eq '.minecraft' -or $null -eq $launcher) {
        $h = ($Hints -join ' ').ToLowerInvariant()
        if ($h -match 'tlauncher') { $launcher = 'TLauncher' }
        elseif ($h -match 'sklauncher') { $launcher = 'SKLauncher' }
        elseif ($h -match 'labymod') { $launcher = 'LabyMod' }
        elseif ($h -match 'lunar') { $launcher = 'Lunar Client' }
        elseif ($h -match 'badlion') { $launcher = 'Badlion Client' }
        elseif ($h -match 'feather') { $launcher = 'Feather Client' }
        elseif ($launcher -eq '.minecraft') { $launcher = 'Minecraft Launcher (.minecraft)' }
    }
    if ($null -eq $launcher) {
        $launcher = 'Bilinmeyen konum'
        $dir = [IO.Path]::GetDirectoryName($orig)
        if ($dir -match '(?i)^(.*)\\logs(\\.*)?$') { $dir = $Matches[1] }
        $detail = $dir
    } else {
        if ($orig -match '(?i)\\(?:instances|profiles)\\([^\\]+)\\') { $detail = $Matches[1] }
        elseif ($launcher -like '*(.minecraft)*' -and $orig -notmatch '(?i)\\AppData\\Roaming\\\.minecraft\\' -and $orig -match '(?i)^(.*?\\\.minecraft)\\') {
            $detail = $Matches[1]
        }
    }
    if ($orig -match '(?i)^[a-z]:\\Users\\([^\\]+)\\' -and $Matches[1] -ne $script:CurrentUser) {
        $detail = ("[Windows kullanıcısı: $($Matches[1])] $detail").Trim()
    }
    foreach ($wr in $script:WslRoots.Keys) {
        if ($orig.StartsWith($wr + '\', [StringComparison]::OrdinalIgnoreCase)) {
            $rest = $orig.Substring($wr.Length + 1)
            $lu = ''
            if ($rest -match '(?i)^home\\([^\\]+)\\') { $lu = " / $($Matches[1])" } elseif ($rest -match '(?i)^root\\') { $lu = ' / root' }
            $detail = ("[Linux (WSL): $($script:WslRoots[$wr])$lu] $detail").Trim()
            break
        }
    }
    $shadowLabel = $null
    if ($Path -and $Path.StartsWith('\\?\GLOBALROOT\', [StringComparison]::OrdinalIgnoreCase)) {
        foreach ($k in $script:ShadowMap.Keys) { if ($Path.StartsWith($k + '\', [StringComparison]::OrdinalIgnoreCase)) { $shadowLabel = $script:ShadowMap[$k][1] } }
    }
    if ($shadowLabel) { $detail = ("[$shadowLabel] $detail").Trim() }
    elseif ($orig -ne $Path) { $detail = ("[Çöp kutusundan] $detail").Trim() }
    return @($launcher, $detail)
}

function Get-FileDate([IO.FileInfo]$Fi) {
    if ($Fi.Name -match '^(\d{4}-\d{2}-\d{2})-\d+\.log') {
        try { return [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture) } catch { }
    }
    return $Fi.LastWriteTime
}

function Test-Environment {
    $isAdmin = $false
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $isAdmin = (Microsoft.PowerShell.Utility\New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { }
    $script:IsAdmin = $isAdmin
    if (-not $isAdmin) {
        Add-Alert 'Bilgi' 'Yönetici olarak çalıştırılmadı' 'Diğer Windows kullanıcılarının klasörleri ve çöp kutuları okunamayabilir. Tam tarama için PowerShell''i "Yönetici olarak çalıştır" ile açın.'
    }

    if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
        Add-Alert 'Yüksek' "PowerShell dil modu kısıtlı: $($ExecutionContext.SessionState.LanguageMode)" 'Tarama eksik çalışabilir. Kısıtlı mod bilinçli olarak açılmış olabilir.'
    }

    $watch = 'Write-Host', 'Write-Progress', 'Get-CimInstance', 'ConvertFrom-Json', 'Get-Item', 'Get-ChildItem', 'Get-Content',
    'Get-Acl', 'Test-Path', 'Out-Host', 'Out-Default', 'Out-String', 'Invoke-RestMethod', 'Invoke-Expression', 'Start-Sleep', 'Select-String',
    'Where-Object', 'ForEach-Object', 'Select-Object', 'Sort-Object', 'Group-Object', 'Measure-Object', 'New-Object', 'Add-Member',
    'Join-Path', 'Out-Null', 'Get-ItemProperty', 'Get-Service', 'Start-Process', 'Get-Command'
    foreach ($n in $watch) {
        $cmds = Microsoft.PowerShell.Core\Get-Command -Name $n -CommandType Alias, Function, Filter -ErrorAction SilentlyContinue
        foreach ($c in $cmds) {
            Add-Alert 'Yüksek' "PowerShell komutu ezilmiş: $n ($($c.CommandType))" 'Bu oturumda bir profil ya da önceden çalıştırılan kod çıktıyı değiştirmeye çalışıyor olabilir. Bu script modül adıyla çağrı yaptığı için etkilenmez; yine de -NoProfile ile tekrar çalıştırın.'
        }
    }

    $profiles = @()
    try { $profiles = @($PROFILE.AllUsersAllHosts, $PROFILE.AllUsersCurrentHost, $PROFILE.CurrentUserAllHosts, $PROFILE.CurrentUserCurrentHost) } catch { }
    foreach ($p in $profiles | Microsoft.PowerShell.Core\Where-Object { $_ } | Microsoft.PowerShell.Utility\Select-Object -Unique) {
        if ([IO.File]::Exists($p)) {
            $fi = Microsoft.PowerShell.Utility\New-Object IO.FileInfo($p)
            $lvl = 'Bilgi'
            $txt = ''
            try { $txt = [IO.File]::ReadAllText($p) } catch { }
            if ($txt -match '(?i)(function\s+(Write-Host|Write-Progress|Out-\w+|Get-ChildItem|Get-Content)|Set-Alias|New-Alias|Remove-Item|minecraft|Setting user)') { $lvl = 'Yüksek' }
            elseif ((([DateTime]::Now) - $fi.LastWriteTime).TotalDays -lt 7) { $lvl = 'Orta' }
            Add-Alert $lvl 'PowerShell profil dosyası mevcut' "$p (son değişiklik: $($fi.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))). Script'i -NoProfile ile çalıştırmanız önerilir."
        }
    }
}

$script:Found = @{
    Logs       = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    Accounts   = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    IasStores  = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    IasJson    = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    IasDirs    = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
    Mods       = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    Options    = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    Configs    = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    LogConfigs = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    Disks      = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    MeteorNbt  = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    AltStores  = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
}
$script:Visited = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$script:DirCount = 0
$script:Denied = 0
$script:SeenFiles = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

$script:SkipDirs = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($d in 'node_modules', '.git', '.svn', '.hg', '.gradle', '.m2', '.nuget', '.cargo', '.rustup', '.npm', '__pycache__', 'site-packages',
    'Cache', 'Code Cache', 'GPUCache', 'CacheStorage', 'Service Worker', 'ShaderCache', 'GrShaderCache', 'DawnCache', 'IndexedDB',
    'WinSxS', 'Installer', 'assembly', 'Microsoft.NET', 'servicing', 'SoftwareDistribution', 'DriverStore', 'System Volume Information',
    '$Recycle.Bin', '$WinREAgent', 'Recovery', 'WindowsApps', 'steamapps', 'Epic Games', 'texturepacks-mp-cache') { [void]$script:SkipDirs.Add($d) }

$script:InterestingExt = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($e in '.log', '.gz', '.json', '.jar', '.txt', '.xml', '.cfg', '.do_not_send_to_anyone', '.vhdx', '.vhd', '.vdi', '.vmdk', '.qcow2') { [void]$script:InterestingExt.Add($e) }

$script:SwitcherModRx = '(?i)(^ias[-_. ]|in-?game-?account-?switcher|account-?switcher|accountswitcher|reauth|alt-?manager|altmanager|account-?manager|^keychain[-_.])'
# Oyun klasörü içinde hesap/alt yöneticisi tutan istemci ve modların dosyaları (adı uzantıdan bağımsız aranır).
$script:AltFileNames = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($n in 'accounts.nbt', 'alts.encrypted_json') { [void]$script:AltFileNames.Add($n) }
# Aracın kendi rapor dosyası (-Export çıktısı) kendi çıktısını "silinmiş Minecraft dosyası" sanmasın.
# ÖNEMLİ: yalnızca .txt rapor hariç tutulur. .log / .json / hesap dosyaları ASLA ada göre
# atlanmaz; yoksa biri gerçek bir logu "AltDetectorX...log" diye yeniden adlandırıp taramadan
# kaçabilirdi. Araç zaten yalnızca .txt rapor ve (anında silinen) geçici .ps1 başlatıcı üretir;
# .txt dosyaları hiçbir yerde hesap/log olarak okunmadığı için bunu hariç tutmak açık yaratmaz.
$script:SelfFileRx = '(?i)(^|[\\/])AltDetectorX[^\\/]*\.txt$'

# Dosya gerçekten bu aracın ürettiği bir rapor mu? Sadece ad değil, İÇERİK doğrulanır:
# rapor başlığı ve imza aranır. Böylece biri bir hesap dosyasını "AltDetectorX_x.txt" diye
# adlandırıp taramadan gizleyemez (gizleme açığı kapalı).
function Test-IsSelfReport([string]$Path) {
    try {
        if (-not [IO.File]::Exists($Path)) { return $false }
        if ((Microsoft.PowerShell.Utility\New-Object IO.FileInfo($Path)).Length -gt 2MB) { return $false }
        $txt = [IO.File]::ReadAllText($Path)
    } catch { return $false }
    return ($txt -match '(?m)^\s*#\s*AltDetectorX\b' -and $txt.Contains((Get-Sig)) -and $txt -match '(?m)^\s*#\s*HESAPLAR\b')
}

function Register-File([IO.FileInfo]$Fi) {
    if (-not $script:SeenFiles.Add($Fi.FullName)) { return }
    if (([int]$Fi.Attributes -band 0x441000) -ne 0) { return }
    $lower = $Fi.Name.ToLowerInvariant()
    $full = $Fi.FullName
    $parent = ''
    try { $parent = $Fi.Directory.Name.ToLowerInvariant() } catch { }

    if ($lower.EndsWith('.log') -or $lower.EndsWith('.log.gz') -or ($lower.EndsWith('.gz') -and $full -match '(?i)\\logs\\')) {
        $limit = $script:Settings.CapOther
        if ($full -match $script:RelevantPathRx) { $limit = $script:Settings.CapRelevant }
        if ($Fi.Length -gt 0 -and $Fi.Length -le $limit) { $script:Found.Logs.Add($Fi) }
        return
    }
    if ($lower -match '\.(vhdx|vhd|vdi|vmdk|qcow2)$') {
        if ($Fi.Length -ge 512MB -or $lower -eq 'ext4.vhdx') { $script:Found.Disks.Add($Fi) }
        return
    }
    if ($lower -eq 'accounts_v1.do_not_send_to_anyone') { $script:Found.IasStores.Add($Fi); return }
    if ($lower -eq 'ias.json' -and $parent -eq 'config') { $script:Found.IasJson.Add($Fi); return }
    if ($lower.EndsWith('.jar') -and $parent -eq 'mods' -and $lower -match $script:SwitcherModRx) { $script:Found.Mods.Add($Fi); return }
    if ($lower -eq 'options.txt') { $script:Found.Options.Add($Fi); return }
    if ($lower.EndsWith('.xml') -and $parent -eq 'log_configs') { $script:Found.LogConfigs.Add($Fi); return }

    # Hile istemcilerinin / modların hesap (alt) yöneticisi dosyaları
    if ($lower -eq 'accounts.nbt' -and $parent -eq 'meteor-client') { $script:Found.MeteorNbt.Add($Fi); return }
    if ($lower -eq 'alts.encrypted_json' -and $parent -eq 'wurst') {
        $script:Found.AltStores.Add([pscustomobject]@{ File = $Fi; Kind = 'Wurst Client' }); return
    }
    if ($lower -eq 'account-switcher.json' -and $parent -eq 'config') {
        $script:Found.AltStores.Add([pscustomobject]@{ File = $Fi; Kind = 'Keychain (hesap değiştirici mod)' }); return
    }

    if ($lower -match '^(instance\.cfg|prismlauncher\.cfg|multimc\.cfg|polymc\.cfg|pollymc\.cfg|fjordlauncher\.cfg|elyprismlauncher\.cfg|freesmlauncher\.cfg|ultimmc\.cfg|launcher_profiles.*\.json|settings\.json)$' -and $full -match $script:RelevantPathRx) {
        $script:Found.Configs.Add($Fi)
    }
    if ($lower.EndsWith('.json') -and $Fi.Length -lt 8MB -and $full -match $script:RelevantPathRx -and
        ($lower -match 'account|launcher_profiles|tlauncherprofiles' -or
        ($lower -eq 'config.json' -and $full -match '(?i)gdlauncher') -or
        ($lower -in 'hmcl.json', '.hmcl.json') -or
        ($lower -eq 'user.json' -and $full -match '(?i)\\xmcl\\') -or
        ($lower -eq 'options.json' -and $full -match '(?i)\\CCBlueX\\LiquidLauncher\\'))) {
        $script:Found.Accounts.Add($Fi)
    }
}

function Invoke-Walk {
    param([string]$Root, [int]$MaxDepth = -1)
    if (-not [IO.Directory]::Exists($Root)) { return }
    $stack = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.Stack[object]
    $stack.Push(@($Root, 0))
    while ($stack.Count -gt 0) {
        $e = $stack.Pop()
        $dir = [string]$e[0]; $depth = [int]$e[1]
        # Bağlantı (junction/symlink) ise gerçek hedefe çevir: aynı klasör hem bağlantı yolundan hem
        # hedef yolundan taranıp loglar iki kez sayılmasın.
        try {
            $dAttr = [IO.File]::GetAttributes($dir)
            if (($dAttr -band [IO.FileAttributes]::ReparsePoint) -ne 0 -and
                [IO.Path]::GetFileName($dir.TrimEnd('\')) -match '(?i)^(logs|\.minecraft|mods|config|\.lunarclient|_IAS_ACCOUNTS_DO_NOT_SEND_TO_ANYONE|\.hidden)$') {
                $tg = $null
                try { $tg = @((Microsoft.PowerShell.Management\Get-Item -LiteralPath $dir -Force).Target) | Microsoft.PowerShell.Utility\Select-Object -First 1 } catch { }
                if (-not $tg) {
                    Add-Alert 'Orta' 'Minecraft ile ilgili klasör bir bağlantı (junction/symlink)' "$dir -> ?  (hedef okunamadı)"
                    continue
                }
                if ($tg) {
                    $tg = [string]$tg
                    if ($tg.StartsWith('\\?\')) { $tg = $tg.Substring(4) }
                    if (-not [IO.Path]::IsPathRooted($tg)) { $tg = [IO.Path]::GetFullPath((Microsoft.PowerShell.Management\Join-Path ([IO.Path]::GetDirectoryName($dir)) $tg)) }
                    $lname = [IO.Path]::GetFileName($dir.TrimEnd('\'))
                    if ($lname -ieq 'logs') {
                        Add-Alert 'Yüksek' 'logs klasörü bir bağlantı (junction/symlink)' "$dir -> $tg  (loglar başka yere yönlendirilmiş ya da gizlenmiş olabilir)"
                    } else {
                        Add-Alert 'Orta' 'Minecraft ile ilgili klasör bir bağlantı (junction/symlink)' "$dir -> $tg"
                    }
                    if (-not [IO.Directory]::Exists($tg)) { continue }
                    $dir = $tg.TrimEnd('\')
                }
            }
        } catch { }
        if (-not $script:Visited.Add($dir)) { continue }
        $script:DirCount++
        if ([Math]::Abs([Environment]::TickCount - $script:LastTick) -ge 100) {
            $pct = -1
            if ($script:WalkTotal -gt 0) { $pct = [int](100 * $script:WalkDone / $script:WalkTotal) }
            Show-Progress -Status ("Konum {0}/{1}:  {2}" -f [Math]::Min($script:WalkDone + 1, $script:WalkTotal), $script:WalkTotal, $script:WalkRoot) -Percent $pct -Recent $dir
        }

        $infos = $null
        try { $infos = ([IO.DirectoryInfo]$dir).GetFileSystemInfos() } catch { $script:Denied++; continue }
        foreach ($fi in $infos) {
            $attr = $fi.Attributes
            if (($attr -band [IO.FileAttributes]::Directory) -ne 0) {
                $name = $fi.Name
                if (($attr -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                    if ($name -match '(?i)^(logs|\.minecraft|mods|config|\.lunarclient|_IAS_ACCOUNTS_DO_NOT_SEND_TO_ANYONE|\.hidden)$') {
                            # Hedef, yığından çıkarılırken çözülür ve uyarı orada verilir (bkz. döngü başı).
                        $stack.Push(@($fi.FullName, $depth + 1))
                    }
                    continue
                }
                if ($script:SkipDirs.Contains($name)) { continue }
                if ($name -eq '_IAS_ACCOUNTS_DO_NOT_SEND_TO_ANYONE') { $script:Found.IasDirs.Add($fi.FullName) }
                if ($MaxDepth -lt 0 -or $depth -lt $MaxDepth) { $stack.Push(@($fi.FullName, $depth + 1)) }
            } elseif ($script:InterestingExt.Contains($fi.Extension) -or $script:AltFileNames.Contains($fi.Name)) {
                Register-File ([IO.FileInfo]$fi)
            }
        }
    }
}

function Get-ProfileRoots {
    $roots = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    try {
        $base = Microsoft.PowerShell.Management\Join-Path $env:SystemDrive 'Users'
        foreach ($d in [IO.Directory]::GetDirectories($base)) {
            $n = [IO.Path]::GetFileName($d)
            if ($n -notin 'All Users', 'Default', 'Default User', 'Public', 'defaultuser0') { [void]$roots.Add($d) }
        }
    } catch { }
    try {
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
        foreach ($k in Microsoft.PowerShell.Management\Get-ChildItem $key) {
            $p = (Microsoft.PowerShell.Management\Get-ItemProperty -LiteralPath $k.PSPath).ProfileImagePath
            if ($p -and $p -notmatch '(?i)\\(systemprofile|LocalService|NetworkService)$' -and [IO.Directory]::Exists($p)) { [void]$roots.Add($p) }
        }
    } catch { }
    if ($env:USERPROFILE) { [void]$roots.Add($env:USERPROFILE) }
    $arr = Microsoft.PowerShell.Utility\New-Object 'string[]' $roots.Count
    $roots.CopyTo($arr)
    return , $arr
}

function Get-KnownLauncherRoots([string]$ProfileDir) {
    $r = 'AppData\Roaming'
    $l = 'AppData\Local'
    $list = @(
        "$r\.minecraft", "$r\.tlauncher", "$r\.feather", "$r\Feather Launcher", "$r\Badlion Client", "$r\PrismLauncher", "$r\PolyMC",
        "$r\ATLauncher", "$r\gdlauncher_next", "$r\gdlauncher_carbon", "$r\GDLauncher", "$r\.technic", "$r\com.modrinth.theseus",
        "$r\ModrinthApp", "$r\.sklauncher", "$r\Salwyrr Launcher", "$r\labymodlauncher", "$r\.ftba", "$l\.ftba",
        "$l\Packages\Microsoft.4297127D64EC6_8wekyb3d8bbwe", "$l\Programs\PrismLauncher", "$l\Programs\MultiMC", "$l\MultiMC",
        '.lunarclient', '.minecraft', 'curseforge\minecraft', 'Documents\curseforge\minecraft', 'MultiMC', 'Desktop\MultiMC', 'Downloads\MultiMC',
        "$r\.hmcl", "$r\PollyMC", "$r\FjordLauncher", "$r\ElyPrismLauncher", "$r\FreesmLauncher", "$r\xmcl", "$r\CCBlueX\LiquidLauncher",
        "$l\Programs\PollyMC", "$l\Programs\FjordLauncher", "$l\Programs\ElyPrismLauncher", "$l\Programs\FreesmLauncher",
        'UltimMC', 'Desktop\UltimMC', 'Downloads\UltimMC'
    )
    foreach ($x in $list) { Microsoft.PowerShell.Management\Join-Path $ProfileDir $x }
}

function Get-ScanDrives {
    $types = @([IO.DriveType]::Fixed, [IO.DriveType]::Removable)
    @([IO.DriveInfo]::GetDrives() | Microsoft.PowerShell.Core\Where-Object { $_.IsReady -and $types -contains $_.DriveType })
}

function Get-WalkPlan {
    $plan = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    $profiles = Get-ProfileRoots

    foreach ($p in $profiles) { foreach ($root in Get-KnownLauncherRoots $p) { if ([IO.Directory]::Exists($root)) { $plan.Add(@($root, -1)) } } }
    $skipRoot = 'Windows', '$Recycle.Bin', 'System Volume Information', 'Recovery', 'PerfLogs', 'Config.Msi', '$WinREAgent', '$SysReset', '$Windows.~BT', '$Windows.~WS'
    switch ($Mode) {
        'Quick' {
            foreach ($p in $profiles) {
                foreach ($x in 'Desktop', 'Downloads', 'Documents', 'OneDrive', 'Games', 'AppData\Roaming', 'AppData\Local\Programs', 'AppData\Local\Temp') {
                    $q = Microsoft.PowerShell.Management\Join-Path $p $x; if ([IO.Directory]::Exists($q)) { $plan.Add(@($q, 4)) }
                }
            }
            foreach ($drv in Get-ScanDrives) {
                $subs = @(); try { $subs = [IO.Directory]::GetDirectories($drv.RootDirectory.FullName) } catch { $script:Denied++ }
                foreach ($sub in $subs) {
                    if ([IO.Path]::GetFileName($sub) -in ($skipRoot + 'Users', 'Program Files', 'Program Files (x86)', 'ProgramData')) { continue }
                    $plan.Add(@($sub, 3))
                }
            }
        }
        'Normal' {
            foreach ($p in $profiles) { $plan.Add(@($p, -1)) }
            foreach ($drv in Get-ScanDrives) {
                $subs = @(); try { $subs = [IO.Directory]::GetDirectories($drv.RootDirectory.FullName) } catch { $script:Denied++ }
                foreach ($sub in $subs) {
                    if ([IO.Path]::GetFileName($sub) -in ($skipRoot + 'Users')) { continue }
                    $plan.Add(@($sub, 6))
                }
            }
        }
        'Deep' {
            foreach ($drv in Get-ScanDrives) {
                $subs = @(); try { $subs = [IO.Directory]::GetDirectories($drv.RootDirectory.FullName) } catch { $script:Denied++ }
                foreach ($sub in $subs) {
                    if ([IO.Path]::GetFileName($sub) -in 'Windows', '$Recycle.Bin', 'System Volume Information') { continue }
                    $plan.Add(@($sub, -1))
                }
            }
        }
    }
    return , $plan
}

function Invoke-Scan {
    $plan = Get-WalkPlan
    $script:WalkTotal = $plan.Count; $script:WalkDone = 0
    foreach ($w in $plan) {
        $script:WalkRoot = [string]$w[0]
        Invoke-Walk ([string]$w[0]) ([int]$w[1])
        $script:WalkDone++
    }
    if ($Mode -eq 'Deep') {
        foreach ($drv in Get-ScanDrives) {
            $rf = @(); try { $rf = [IO.Directory]::GetFiles($drv.RootDirectory.FullName) } catch { }
            foreach ($f in $rf) { $fi = Microsoft.PowerShell.Utility\New-Object IO.FileInfo($f); if ($script:InterestingExt.Contains($fi.Extension)) { Register-File $fi } }
        }
    }
}

function Read-RecycleInfo([string]$IPath) {
    try {
        $b = [IO.File]::ReadAllBytes($IPath)
        if ($b.Length -lt 28) { return $null }
        $ver = [BitConverter]::ToInt64($b, 0)
        $deleted = [DateTime]::FromFileTime([BitConverter]::ToInt64($b, 16))
        if ($ver -eq 2) {
            $len = [BitConverter]::ToInt32($b, 24)
            $path = [Text.Encoding]::Unicode.GetString($b, 28, [Math]::Min($len * 2, $b.Length - 28)).TrimEnd([char]0)
        } else {
            $path = [Text.Encoding]::Unicode.GetString($b, 24, [Math]::Min(520, $b.Length - 24)).Split([char]0)[0]
        }
        return @($path, $deleted)
    } catch { return $null }
}

function Invoke-RecycleScan {
    $interesting = '(?i)(\.minecraft|lunarclient|feather|badlion|blclient|labymod|prismlauncher|polymc|multimc|atlauncher|gdlauncher|curseforge\\minecraft|modrinth|tlauncher|sklauncher|_IAS_ACCOUNTS|\\logs(\\|$)|\.log(\.gz)?$|launcher_accounts|launcher_profiles|accounts\.json|ias\.json|\\\.hmcl\\|\.?hmcl\.json$|pollymc|fjordlauncher|elyprismlauncher|freesmlauncher|ultimmc|\\xmcl\\|liquidlauncher|\\liquidbounce\\|\\meteor-client\\|\\wurst\\|accounts\.nbt$|alts\.encrypted_json$)'
    $count = 0
    foreach ($drv in Get-ScanDrives) {
        $bin = Microsoft.PowerShell.Management\Join-Path $drv.RootDirectory.FullName '$Recycle.Bin'
        $sids = @()
        try { $sids = [IO.Directory]::GetDirectories($bin) } catch { continue }
        foreach ($sid in $sids) {
            Show-Progress -Status "Silinmiş dosyalar aranıyor..." -Recent $sid
            $ifiles = @()
            try { $ifiles = [IO.Directory]::GetFiles($sid, '$I*') } catch { $script:Denied++; continue }
            foreach ($i in $ifiles) {
                $info = Read-RecycleInfo $i
                if (-not $info) { continue }
                $orig = [string]$info[0]; $when = [datetime]$info[1]
                if ($orig -notmatch $interesting) { continue }
                $rPath = Microsoft.PowerShell.Management\Join-Path $sid ('$R' + [IO.Path]::GetFileName($i).Substring(2))
                # Aracın kendi raporunu atla; ama yalnızca içeriği gerçekten rapor olan .txt'leri (açık kapalı).
                if ($orig -match $script:SelfFileRx -and (Test-IsSelfReport $rPath)) { continue }
                $count++
                $lvl = 'Orta'
                if ($orig -match '(?i)(\\logs(\\|$)|\.log(\.gz)?$|_IAS_ACCOUNTS|accounts|launcher_profiles|\.minecraft$|lunarclient$)') { $lvl = 'Yüksek' }
                if ($count -le 40) {
                    Add-Alert $lvl 'Çöp kutusunda silinmiş Minecraft dosyası' "$orig  (silinme: $($when.ToString('yyyy-MM-dd HH:mm')))"
                }
                $script:RecycleMap[$rPath] = $orig
                if ([IO.Directory]::Exists($rPath)) { Invoke-Walk $rPath -1 }
                elseif ([IO.File]::Exists($rPath)) {
                    $fi = Microsoft.PowerShell.Utility\New-Object IO.FileInfo($rPath)
                    if ($orig -match '(?i)\.(log|gz)$') { if ($fi.Length -gt 0 -and $fi.Length -le $script:Settings.CapRelevant -and $script:SeenFiles.Add($fi.FullName)) { $script:Found.Logs.Add($fi) } }
                    elseif ($orig -match '(?i)\.json$') { if ($script:SeenFiles.Add($fi.FullName)) { $script:Found.Accounts.Add($fi) } }
                    elseif ($orig -match '(?i)accounts_v1\.do_not_send_to_anyone$') { $script:Found.IasStores.Add($fi) }
                }
            }
        }
    }
    if ($count -gt 40) { Add-Alert 'Orta' "Çöp kutusunda toplam $count ilgili silinmiş öğe var" 'Sadece ilk 40 tanesi listelendi.' }
}

$script:ShadowMap = @{}
$script:OemEnc = $null
try { $script:OemEnc = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage) } catch { }

function Test-IsShadowPath([string]$P) {
    return ($P -and $P.StartsWith('\\?\GLOBALROOT\', [StringComparison]::OrdinalIgnoreCase))
}

function Split-CsvLine([string]$Line) {
    $vals = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($Line, '(?:^|,)(?:"((?:[^"]|"")*)"|([^,]*))')) {
        if ($m.Groups[1].Success) { $vals.Add($m.Groups[1].Value.Replace('""', '"')) } else { $vals.Add($m.Groups[2].Value.Trim()) }
    }
    return , $vals
}

function Invoke-ShadowScan {
    $shadows = @()
    Show-Progress -Status 'Gölge kopyalar (geri yükleme noktaları) aranıyor...' -Force
    try { $shadows = @(CimCmdlets\Get-CimInstance Win32_ShadowCopy -ErrorAction Stop -OperationTimeoutSec 60) } catch { return }
    if ($shadows.Count -eq 0) {
        Add-Alert 'Bilgi' 'Gölge kopya (geri yükleme noktası) yok' 'Eski dosya sürümlerine bakılamadı. Gölge kopyaların hepsinin silinmiş olması da bir temizlik işareti olabilir.'
        return
    }
    $vols = @{}
    try { foreach ($v in CimCmdlets\Get-CimInstance Win32_Volume) { if ($v.DriveLetter) { $vols[[string]$v.DeviceID] = [string]$v.DriveLetter } } } catch { }
    $profiles = Get-ProfileRoots
    $list = @($shadows | Microsoft.PowerShell.Utility\Sort-Object InstallDate -Descending | Microsoft.PowerShell.Utility\Select-Object -First 8)
    $plan = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    foreach ($sh in $list) {
        $letter = $vols[[string]$sh.VolumeName]
        if (-not $letter) { continue }
        $dev = ([string]$sh.DeviceObject).TrimEnd('\')
        $label = "Gölge kopya {0:yyyy-MM-dd HH:mm}" -f $sh.InstallDate
        $script:ShadowMap[$dev] = @($letter, $label)
        foreach ($p in $profiles) {
            if (-not $p.StartsWith($letter + '\', [StringComparison]::OrdinalIgnoreCase)) { continue }
            foreach ($root in Get-KnownLauncherRoots $p) { $plan.Add(@(($dev + $root.Substring(2)), -1)) }
            foreach ($x in 'Desktop', 'Downloads', 'Documents') { $plan.Add(@(($dev + (Microsoft.PowerShell.Management\Join-Path $p $x).Substring(2)), 4)) }
        }
    }
    Add-Alert 'Bilgi' "Gölge kopyalar tarandı: $($script:ShadowMap.Count) adet" (($script:ShadowMap.Values | Microsoft.PowerShell.Core\ForEach-Object { $_[1] }) -join ', ')
    $script:WalkTotal = $plan.Count; $script:WalkDone = 0
    foreach ($w in $plan) {
        $script:WalkRoot = [string]$w[0]
        if ([IO.Directory]::Exists([string]$w[0])) { Invoke-Walk ([string]$w[0]) ([int]$w[1]) }
        $script:WalkDone++
    }
}

function Test-ShadowDeleted {
    $seen = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $count = 0
    foreach ($a in $script:Accounts) {
        if (-not (Test-IsShadowPath $a.Path)) { continue }
        if (-not $seen.Add($a.Path)) { continue }
        $now = Resolve-OriginalPath $a.Path
        if ([IO.File]::Exists($now)) { continue }
        $count++
        if ($count -le 40) {
            $label = ''
            foreach ($k in $script:ShadowMap.Keys) { if ($a.Path.StartsWith($k, [StringComparison]::OrdinalIgnoreCase)) { $label = $script:ShadowMap[$k][1] } }
            Add-Alert 'Yüksek' 'Eski kopyada var, şu an silinmiş' "$now  ($label, içinde: $($a.Name))"
        }
    }
    if ($count -gt 40) { Add-Alert 'Yüksek' "Eski kopyalarda olup silinmiş toplam $count dosya" 'Sadece ilk 40 tanesi listelendi.' }
}

function Invoke-UsnScan {
    $fsutil = Microsoft.PowerShell.Management\Join-Path $env:SystemRoot 'System32\fsutil.exe'
    if (-not [IO.File]::Exists($fsutil)) { return }
    $install = $null
    try { $install = (CimCmdlets\Get-CimInstance Win32_OperatingSystem).InstallDate } catch { }
    $nameRx = '(?i)^(latest\.log|\d{4}-\d{2}-\d{2}-\d+\.log\.gz|launcher_accounts[^\\]*\.json|launcher_profiles[^\\]*\.json|tlauncherprofiles\.json|accounts\.json|accounts_v1\.do_not_send_to_anyone|ias\.json|user-accounts\.json|\.?hmcl\.json|accounts\.nbt|alts\.encrypted_json)$'
    $strongRx = '(?i)^(launcher_accounts[^\\]*\.json|tlauncherprofiles\.json|accounts_v1\.do_not_send_to_anyone|ias\.json|user-accounts\.json|accounts\.nbt|alts\.encrypted_json)$'
    $found = @{}
    $resolveCache = @{}
    $resolves = 0
    $drives = @([IO.DriveInfo]::GetDrives() | Microsoft.PowerShell.Core\Where-Object { $_.IsReady -and $_.DriveType -eq [IO.DriveType]::Fixed -and $_.DriveFormat -eq 'NTFS' })
    foreach ($drv in $drives) {
        $letter = $drv.Name.Substring(0, 2)
        Show-Progress -Status "Silinmiş dosyalar aranıyor..." -Recent $letter -Force

        $q = Invoke-Native $fsutil "usn queryjournal $letter" 20000 $script:OemEnc
        if ($q -and $q -match '0x([0-9a-fA-F]{16})') {
            try {
                $created = [DateTime]::FromFileTime([Convert]::ToInt64($Matches[1], 16))
                if ($created.Year -ge 2000 -and $created -le [DateTime]::Now.AddDays(1)) {
                    $age = ([DateTime]::Now - $created).TotalDays
                    $afterInstall = $true
                    if ($install) { $afterInstall = (($created - $install).TotalDays -gt 2) }
                    if ($age -lt 14 -and $afterInstall) {
                        Add-Alert 'Orta' "USN günlüğü yakın zamanda yeniden oluşturulmuş ($letter)" ("Oluşturulma: {0:yyyy-MM-dd HH:mm}. Daha önceki dosya silme kayıtları yok; günlük bilinçli olarak silinmiş olabilir." -f $created)
                    }
                }
            } catch { }
        } elseif ($null -ne $q) {
            Add-Alert 'Orta' "USN günlüğü okunamadı ya da kapalı ($letter)" 'Dosya değişiklik kaydı kapatılmış olabilir; silinen dosyalar bu yöntemle kontrol edilemedi.'
            continue
        }

        Show-Progress -Status "USN günlüğü okunuyor ($letter), birkaç dakika sürebilir..." -Recent "$letter\ (USN günlüğü)" -Force
        $args2 = "/c `"`"$fsutil`" usn readjournal $letter csv | findstr /i /c:`".log.gz`" /c:`"latest.log`" /c:`"account`" /c:`"launcher_profiles`" /c:`"do_not_send`" /c:`"ias.json`" /c:`"hmcl.json`" /c:`"alts.encrypted`"`""
        $out = Invoke-Native $env:ComSpec $args2 300000 $script:OemEnc
        if (-not $out) { continue }
        Show-Progress -Status "USN kayıtları inceleniyor ($letter)..." -Force
        foreach ($line in ($out -split "`r?`n")) {
            Update-UiTick
            if (-not $line) { continue }
            $f = Split-CsvLine $line
            if ($f.Count -lt 10) { continue }
            $name = $f[1]
            if ($name -notmatch $nameRx) { continue }
            $r = -1
            for ($i = 2; $i -lt [Math]::Min($f.Count, 6); $i++) { if ($f[$i] -match '^0x[0-9a-fA-F]{8}$') { $r = $i; break } }
            if ($r -lt 0) { continue }
            $reason = [Convert]::ToInt64($f[$r].Substring(2), 16)
            $isDel = ($reason -band 0x200) -ne 0
            $isRen = ($reason -band 0x1000) -ne 0
            if (-not ($isDel -or $isRen)) { continue }
            # Reason'dan sonraki sütunlar sabit sıraya göre değil içeriğe göre bulunur (fsutil csv düzeni
            # Windows sürümüne göre değişebilir): ilk tarih olarak okunan alan zaman damgası, 64/128 bit
            # hex alanlar sırasıyla File ID ve Parent File ID (öznitelikler 8 haneli olduğu için eşleşmez).
            $ts = $null; $ids = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
            for ($i = $r + 1; $i -lt $f.Count; $i++) {
                $v = $f[$i]
                if ($v -match '^0x[0-9a-fA-F]{16,32}$') { $ids.Add($v); if ($ids.Count -ge 2) { break }; continue }
                if ($null -eq $ts -and $v -match '\d' -and $v -notmatch '^(0x)?[0-9a-fA-F]+$') {
                    $tmpDate = [datetime]::MinValue
                    if ([datetime]::TryParse($v, [Globalization.CultureInfo]::CurrentCulture, [Globalization.DateTimeStyles]::None, [ref]$tmpDate)) { $ts = $v }
                }
            }
            if ($ids.Count -lt 2) { continue }
            if ($null -eq $ts) { $ts = '?' }
            $parent = $ids[1]
            $key = "$letter|$parent|$name"
            $what = 'silindi'; if (-not $isDel) { $what = 'adı değiştirildi' }
            $found[$key] = @($letter, $parent, $name, $ts, $what)
        }
    }

    $count = 0
    if ($found.Count -gt 0) { Show-Progress -Status "Silinen dosyaların konumları bulunuyor ($($found.Count) kayıt)..." -Force }
    foreach ($e in $found.Values) {
        Update-UiTick
        $letter = $e[0]; $parent = $e[1]; $name = $e[2]; $ts = $e[3]; $what = $e[4]
        $dir = $null
        if ($parent -match '^0x[0-9a-fA-F]+$') {
            $ck = "$letter|$parent"
            if ($resolveCache.ContainsKey($ck)) { $dir = $resolveCache[$ck] }
            elseif ($resolves -lt 120) {
                $resolves++
                $o = Invoke-Native $fsutil "file queryFileNameById $letter\ $parent" 10000 $script:OemEnc
                if ($o -and $o -match '([A-Za-z]:\\[^\r\n]*)') { $dir = $Matches[1].Trim() }
                $resolveCache[$ck] = $dir
            }
        }
        $strong = ($name -match $strongRx)
        if ($dir) {
            if ([IO.File]::Exists((Microsoft.PowerShell.Management\Join-Path $dir $name))) { continue }
            if (-not $strong -and $dir -notmatch $script:RelevantPathRx) { continue }
            $where = Microsoft.PowerShell.Management\Join-Path $dir $name
        } else {
            if (-not $strong -and $name -notmatch '\.log\.gz$') { continue }
            $where = "$name  (konumu bulunamadı, klasörü de silinmiş olabilir)"
        }
        $when = $ts
        try { $when = ([datetime]::Parse($ts, [Globalization.CultureInfo]::CurrentCulture)).ToString('yyyy-MM-dd HH:mm') } catch { }
        $count++
        if ($count -le 40) {
            $lvl = 'Orta'; if ($strong -or ($dir -and $dir -match $script:RelevantPathRx)) { $lvl = 'Yüksek' }
            Add-Alert $lvl "USN günlüğü: Minecraft dosyası $what" "$where  ($when)"
        }
    }
    if ($count -gt 40) { Add-Alert 'Yüksek' "USN günlüğünde toplam $count silinmiş/adı değişmiş Minecraft dosyası" 'Sadece ilk 40 tanesi listelendi.' }
}

function Test-WipeTools {
    $pf = Microsoft.PowerShell.Management\Join-Path $env:SystemRoot 'Prefetch'
    $pfMode = $null
    try { $pfMode = (Microsoft.PowerShell.Management\Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -ErrorAction Stop).EnablePrefetcher } catch { }
    if ($null -ne $pfMode -and [int]$pfMode -eq 0) {
        Add-Alert 'Orta' 'Prefetch kapatılmış' 'EnablePrefetcher = 0: hangi programların çalıştırıldığı kaydedilmiyor, temizleme araçları bu yöntemle kontrol edilemedi. Bilinçli olarak kapatılmış olabilir.'
    }
    $files = @()
    try { $files = ([IO.DirectoryInfo]$pf).GetFiles('*.pf') } catch {
        Add-Alert 'Orta' 'Prefetch klasörü okunamadı' "$pf  (klasör silinmiş ya da erişim engellenmiş olabilir)"
        return
    }
    if ($files.Count -eq 0) {
        Add-Alert 'Orta' 'Prefetch klasörü boş' "$pf  (yakın zamanda temizlenmiş ya da Prefetch kapatılmış olabilir)"
        return
    }
    # 3. alan: $true = temizleme / iz silme aracı, $false = sadece inceleme / sistem aracı (tek başına şüpheli değil)
    $tools = @(
        @('^CCLEANER', 'CCleaner', $true), @('^BLEACHBIT', 'BleachBit', $true), @('^PRIVAZER', 'PrivaZer', $true), @('^ERASER', 'Eraser', $true),
        @('^SDELETE', 'SDelete', $true), @('^WISEDISKCLEANER|^WISECLEANER', 'Wise Disk Cleaner', $true), @('^GLARY|^INTEGRATOR', 'Glary Utilities', $true),
        @('^HARDWIPE', 'Hardwipe', $true), @('^FILESHREDDER', 'File Shredder', $true), @('^CIPHER\.EXE', 'cipher (boş alan silme)', $true),
        @('^REVOUNIN', 'Revo Uninstaller', $true),
        @('^EVERYTHING', 'Everything (dosya arama)', $false), @('^LASTACTIVITYVIEW', 'LastActivityView', $false), @('^USBDEVIEW', 'USBDeview', $false),
        @('^PROCESSHACKER|^SYSTEMINFORMER', 'Process Hacker / System Informer', $false)
    )
    foreach ($t in $tools) {
        $hit = $files | Microsoft.PowerShell.Core\Where-Object { $_.Name -match "(?i)$($t[0])" } | Microsoft.PowerShell.Utility\Sort-Object LastWriteTime -Descending | Microsoft.PowerShell.Utility\Select-Object -First 1
        if (-not $hit) { continue }
        $days = ([DateTime]::Now - $hit.LastWriteTime).TotalDays
        $when = ("Son çalıştırma: {0:yyyy-MM-dd HH:mm}" -f $hit.LastWriteTime)
        if ($t[2]) {
            $lvl = 'Bilgi'; if ($days -lt 30) { $lvl = 'Orta' }
            Add-Alert $lvl "Temizleme / iz silme aracı çalıştırılmış: $($t[1])" $when
        } else {
            Add-Alert 'Bilgi' "İnceleme / sistem aracı çalıştırılmış: $($t[1])" $when
        }
    }
}

function Invoke-DeletedScan {
    Invoke-RecycleScan
    if (-not $script:IsAdmin) {
        Add-Alert 'Bilgi' 'Gelişmiş silinmiş dosya kontrolleri atlandı' 'USN günlüğü, gölge kopyalar ve Prefetch kontrolleri için yönetici yetkisi gerekiyor.'
        return
    }
    Show-Progress -Status 'Silinmiş dosyalar aranıyor...' -Force
    Test-WipeTools
    Show-Progress -Status 'Silinmiş dosyalar aranıyor...' -Force
    Invoke-ShadowScan
    Invoke-UsnScan
}

$script:Worker = {
    param([object[]]$Items)
    $rxUser = Microsoft.PowerShell.Utility\New-Object System.Text.RegularExpressions.Regex('Setting user:\s*([^\s\]\r\n]+)')
    $rxIas = Microsoft.PowerShell.Utility\New-Object System.Text.RegularExpressions.Regex("IAS: Received login request: LoginData\{name='([^'\r\n]*)'")
    $rxCmd = Microsoft.PowerShell.Utility\New-Object System.Text.RegularExpressions.Regex('--username[\s=]+"?([^\s"]+)')
    $rxHint = Microsoft.PowerShell.Utility\New-Object System.Text.RegularExpressions.Regex('(?i)(tlauncher|sklauncher|labymod|badlion|lunar ?client|feather)')
    $out = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    foreach ($path in $Items) {
        $users = @(); $ias = @(); $hints = @(); $err = $null
        try {
            $fs = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]'ReadWrite, Delete')
            try {
                $isGz = $false
                if ($fs.Length -ge 2) {
                    $b1 = $fs.ReadByte(); $b2 = $fs.ReadByte()
                    $isGz = ($b1 -eq 0x1F -and $b2 -eq 0x8B)
                    $fs.Position = 0
                }
                if ($isGz) {
                    $stream = Microsoft.PowerShell.Utility\New-Object IO.Compression.GZipStream($fs, [IO.Compression.CompressionMode]::Decompress)
                } else {
                    $stream = $fs
                }
                $sr = Microsoft.PowerShell.Utility\New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8, $true)
                $text = $sr.ReadToEnd()
                $sr.Dispose()
            } finally { $fs.Dispose() }

            if ($text.IndexOf('Setting user:', [StringComparison]::Ordinal) -ge 0) {
                foreach ($m in $rxUser.Matches($text)) { $users += $m.Groups[1].Value }
            }
            if ($text.IndexOf('IAS: Received login request', [StringComparison]::Ordinal) -ge 0) {
                foreach ($m in $rxIas.Matches($text)) { $ias += $m.Groups[1].Value }
            }
            if ($users.Count -eq 0 -and $text.IndexOf('--username', [StringComparison]::Ordinal) -ge 0) {
                foreach ($m in $rxCmd.Matches($text)) {
                    $v = $m.Groups[1].Value
                    if ($v -notmatch '^\$\{' -and $v -match '^[A-Za-z0-9_]{2,16}$') { $users += $v }
                }
            }
            if ($users.Count -gt 0 -or $ias.Count -gt 0) {
                $head = $text
                if ($head.Length -gt 300000) { $head = $head.Substring(0, 300000) }
                foreach ($m in $rxHint.Matches($head)) { $hints += $m.Groups[1].Value.ToLowerInvariant() }
            }
            $text = $null
        } catch { $err = $_.Exception.Message }
        if ($users.Count -gt 0 -or $ias.Count -gt 0) {
            $out.Add([pscustomobject]@{
                    Path  = $path
                    Users = @($users | Microsoft.PowerShell.Utility\Select-Object -Unique)
                    Ias   = @($ias | Microsoft.PowerShell.Utility\Select-Object -Unique)
                    Hints = @($hints | Microsoft.PowerShell.Utility\Select-Object -Unique)
                })
        }
    }
    , $out.ToArray()
}

function Invoke-LogParse {
    $files = $script:Found.Logs
    if ($files.Count -eq 0) { return }
    $byPath = @{}
    foreach ($f in $files) { $byPath[$f.FullName] = $f }

    $n = [int]$script:Settings.Threads
    if ($n -le 0) { $n = [Math]::Max(2, [Math]::Min(8, [Environment]::ProcessorCount)) }

    $sorted = @($files | Microsoft.PowerShell.Utility\Sort-Object Length -Descending)
    $batches = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    $batchSize = [int][Math]::Max(1, [Math]::Min(40, [Math]::Ceiling($sorted.Count / ($n * 4))))
    for ($i = 0; $i -lt $sorted.Count; $i += $batchSize) {
        $end = [Math]::Min($sorted.Count, $i + $batchSize) - 1
        $batches.Add([string[]]@($sorted[$i..$end] | Microsoft.PowerShell.Core\ForEach-Object { $_.FullName }))
    }

    $pool = [RunspaceFactory]::CreateRunspacePool(1, $n)
    $pool.Open()
    $jobs = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    foreach ($b in $batches) {
        $ps = [PowerShell]::Create()
        $ps.RunspacePool = $pool
        [void]$ps.AddScript($script:Worker).AddArgument($b)
        $jobs.Add(@{ PS = $ps; Handle = $ps.BeginInvoke(); Count = $b.Count; Done = $false; Paths = $b })
    }

    $total = $files.Count
    $done = 0
    $lastPath = $null
    try {
        while ($done -lt $total) {
            $progressed = $false
            foreach ($j in $jobs) {
                if (-not $j.Done -and $j.Handle.IsCompleted) {
                    try {
                        foreach ($r in $j.PS.EndInvoke($j.Handle)) { foreach ($x in $r) { if ($x) { Add-LogResult $x $byPath } } }
                    } catch { }
                    $j.PS.Dispose()
                    $j.Done = $true
                    $done += $j.Count
                    $progressed = $true
                    $lastPath = $j.Paths[$j.Paths.Count - 1]
                }
            }
            $pct = [int](100 * $done / [Math]::Max(1, $total))
            Show-Progress -Status ("{0:N0} / {1:N0} dosya" -f $done, $total) -Percent $pct -Recent $lastPath
            if (-not $progressed) { Microsoft.PowerShell.Utility\Start-Sleep -Milliseconds 50 }
        }
    } finally {
        foreach ($j in $jobs) { if (-not $j.Done) { try { $j.PS.Stop(); $j.PS.Dispose() } catch { } } }
        $pool.Close(); $pool.Dispose()
    }

}

function Add-LogResult($R, $ByPath) {
    $fi = $ByPath[$R.Path]
    if (-not $fi) { $fi = Microsoft.PowerShell.Utility\New-Object IO.FileInfo($R.Path) }
    $info = Get-LauncherInfo $R.Path $R.Hints
    $date = Get-FileDate $fi
    foreach ($u in $R.Users) { Add-Account $u $info[0] $info[1] 'log' $R.Path $date }
    foreach ($u in $R.Ias) { Add-Account $u $info[0] $info[1] 'IAS ile oyun içi geçiş' $R.Path $date }
}

$script:UuidRx = '^[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}$'
$script:McNameRx = '^[A-Za-z0-9_]{2,16}$'

function Get-JsonAccountNames {
    param($Obj, [string]$ParentKey, [System.Collections.Generic.List[string]]$Out, [int]$Depth = 0)
    if ($null -eq $Obj -or $Depth -gt 12) { return }
    if ($Obj -is [System.Collections.IEnumerable] -and $Obj -isnot [string] -and $Obj -isnot [System.Management.Automation.PSCustomObject]) {
        foreach ($x in $Obj) { Get-JsonAccountNames $x $ParentKey $Out ($Depth + 1) }
        return
    }
    if ($Obj -isnot [System.Management.Automation.PSCustomObject]) { return }

    $props = @{}
    foreach ($p in $Obj.PSObject.Properties) { $props[$p.Name.ToLowerInvariant()] = $p.Value }

    $idLike = ($ParentKey -match $script:UuidRx)
    foreach ($k in 'id', 'uuid', 'profileid', 'minecraftuuid', 'remoteid') {
        if ($props.ContainsKey($k) -and ([string]$props[$k]) -match $script:UuidRx) { $idLike = $true }
    }
    $isGameProfile = $false
    foreach ($k in 'lastversionid', 'gamedir', 'javaargs', 'icon', 'resolution', 'javadir') { if ($props.ContainsKey($k)) { $isGameProfile = $true } }

    if ($idLike -and -not $isGameProfile) {
        foreach ($k in 'minecraftusername', 'displayname', 'name', 'playername', 'profilename', 'username') {
            if ($props.ContainsKey($k)) {
                $v = [string]$props[$k]
                if ($v -match $script:McNameRx) { $Out.Add($v) }
            }
        }
    }
    foreach ($p in $Obj.PSObject.Properties) {
        $v = $p.Value
        if ($v -is [System.Management.Automation.PSCustomObject] -or ($v -is [System.Collections.IEnumerable] -and $v -isnot [string])) {
            Get-JsonAccountNames $v $p.Name $Out ($Depth + 1)
        }
    }
}

function Invoke-AccountFiles {
    $i = 0
    foreach ($fi in $script:Found.Accounts) {
        $i++
        Show-Progress -Status "$i / $($script:Found.Accounts.Count) dosya" -Percent ([int](100 * $i / $script:Found.Accounts.Count)) -Recent $fi.FullName
        $txt = $null
        try {
            $fs = [IO.File]::Open($fi.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]'ReadWrite, Delete')
            $sr = Microsoft.PowerShell.Utility\New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8, $true)
            $txt = $sr.ReadToEnd(); $sr.Dispose(); $fs.Dispose()
        } catch { continue }
        if ([string]::IsNullOrWhiteSpace($txt)) { continue }

        $names = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
        $parsed = $false
        try {
            $obj = Microsoft.PowerShell.Utility\ConvertFrom-Json -InputObject $txt -ErrorAction Stop
            Get-JsonAccountNames $obj '' $names
            $parsed = $true
        } catch { }
        # JSON okunamadıysa ya da yapısı tanınmadıysa (yalnızca hesap dosyalarında) ad alanlarını doğrudan ara.
        $isAccountFile = ($fi.Name -match '(?i)account|^\.?hmcl\.json$' -or ($fi.Name -ieq 'user.json' -and $fi.FullName -match '(?i)\\xmcl\\'))
        if (-not $parsed -or ($names.Count -eq 0 -and $isAccountFile)) {
            # Önce kullanıcı adına özgü alanlar; genel "name" alanı yalnızca bunlar yoksa kullanılır.
            $stop = 'accounts', 'account', 'value', 'values', 'name', 'type', 'offline', 'cracked', 'microsoft', 'mojang', 'legacy', 'default', 'profile', 'profiles', 'settings', 'config', 'true', 'false', 'null'
            foreach ($rx in '"(?:displayName|minecraftUsername|username|playerName)"\s*:\s*"([A-Za-z0-9_]{2,16})"', '"name"\s*:\s*"([A-Za-z0-9_]{2,16})"') {
                foreach ($m in [regex]::Matches($txt, $rx)) { $v = $m.Groups[1].Value; if ($stop -notcontains $v.ToLowerInvariant()) { $names.Add($v) } }
                if ($names.Count -gt 0) { break }
            }
        }
        $hint = @()
        if ($fi.Name -match '(?i)tlauncher') { $hint = @('tlauncher') }
        $info = Get-LauncherInfo $fi.FullName $hint
        $src = "hesap dosyası ($($fi.Name))"
        if ($fi.FullName -match '(?i)\\LiquidBounce\\[^\\]+$') { $src = 'LiquidBounce alt yöneticisi' }
        foreach ($n in ($names | Microsoft.PowerShell.Utility\Select-Object -Unique)) {
            Add-Account $n $info[0] $info[1] $src $fi.FullName $fi.LastWriteTime
        }
    }
}

function Read-JavaUtf([IO.BinaryReader]$R) {
    $hi = $R.ReadByte(); $lo = $R.ReadByte()
    $len = ([int]$hi -shl 8) -bor [int]$lo
    $bytes = $R.ReadBytes($len)
    if ($bytes.Length -ne $len) { throw 'EOF' }
    return [Text.Encoding]::UTF8.GetString($bytes)
}

function Read-IasStore([string]$Path) {

    $names = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    $raw = [IO.File]::ReadAllBytes($Path)
    if ($raw.Length -lt 3) { return , $names }
    $ms = Microsoft.PowerShell.Utility\New-Object IO.MemoryStream(, $raw)
    [void]$ms.ReadByte(); [void]$ms.ReadByte()
    $ds = Microsoft.PowerShell.Utility\New-Object IO.Compression.DeflateStream($ms, [IO.Compression.CompressionMode]::Decompress)
    $plain = Microsoft.PowerShell.Utility\New-Object IO.MemoryStream
    $ds.CopyTo($plain); $ds.Dispose()
    $plain.Position = 0
    $r = Microsoft.PowerShell.Utility\New-Object IO.BinaryReader($plain)
    try {
        $count = ([int]$r.ReadByte() -shl 8) -bor [int]$r.ReadByte()
        for ($i = 0; $i -lt $count; $i++) {
            $type = Read-JavaUtf $r
            switch ($type) {
                'ias:offline_v1' { $names.Add(@((Read-JavaUtf $r), 'çevrimdışı')) }
                'ias:offline_v2' {
                    $n = Read-JavaUtf $r
                    if ($r.ReadByte() -ne 0) { [void]$r.ReadBytes(16) }
                    $names.Add(@($n, 'çevrimdışı'))
                }
                'ias:microsoft_v1' {
                    [void]$r.ReadByte(); [void]$r.ReadBytes(16)
                    $n = Read-JavaUtf $r
                    $len = ([int]$r.ReadByte() -shl 8) -bor [int]$r.ReadByte()
                    [void]$r.ReadBytes($len)
                    $names.Add(@($n, 'Microsoft'))
                }
                default { $script:IasUnknownType = $type; $i = $count }
            }
        }
    } catch { }
    $r.Dispose()
    return , $names
}

function Invoke-Ias {
    foreach ($fi in $script:Found.IasStores) {
        $info = Get-LauncherInfo $fi.FullName
        $list = $null
        $script:IasUnknownType = $null
        try { $list = Read-IasStore $fi.FullName } catch { }
        if ($null -eq $list) {
            Add-Alert 'Orta' 'IAS hesap dosyası okunamadı' "$($fi.FullName) (bozuk ya da değiştirilmiş olabilir)"
            continue
        }
        foreach ($x in $list) { Add-Account $x[0] $info[0] $info[1] "IAS kayıtlı hesap ($($x[1]))" $fi.FullName $fi.LastWriteTime }
        if ($script:IasUnknownType) {
            Add-Alert 'Orta' 'IAS hesap dosyası tam okunamadı' "$($fi.FullName)  (tanınmayan hesap türü: '$($script:IasUnknownType)'; $($list.Count) hesap okundu, sonrakiler atlandı. Yeni bir IAS sürümü olabilir.)"
        } elseif ($list.Count -eq 0) { Add-Alert 'Bilgi' 'IAS hesap dosyası boş' $fi.FullName }
    }
    foreach ($fi in $script:Found.IasJson) {

        $info = Get-LauncherInfo $fi.FullName
        try {
            $txt = [IO.File]::ReadAllText($fi.FullName)
            foreach ($m in [regex]::Matches($txt, '"(?:name|username|alias)"\s*:\s*"([A-Za-z0-9_]{2,16})"')) {
                Add-Account $m.Groups[1].Value $info[0] $info[1] 'IAS kayıtlı hesap (eski sürüm)' $fi.FullName $fi.LastWriteTime
            }
        } catch { }
    }
    foreach ($d in $script:Found.IasDirs) {
        $store = Microsoft.PowerShell.Management\Join-Path $d '.hidden\accounts_v1.do_not_send_to_anyone'
        if (-not [IO.File]::Exists($store)) {
            Add-Alert 'Orta' 'IAS klasörü var ama hesap dosyası yok' "$d  (IAS kullanılmış, hesap dosyası silinmiş olabilir)"
        }
    }
    foreach ($fi in $script:Found.Mods) {
        $info = Get-LauncherInfo $fi.FullName
        $where = $info[0]; if ($info[1]) { $where += " › $($info[1])" }
        Add-Alert 'Orta' 'Hesap değiştirici mod yüklü' "$($fi.Name)  [$where]  (oyun içinden hesap değiştirmeye izin verir)"
    }
}

# NBT dosyasındaki TAG_String değerlerini (yalnızca istenen anahtar adları için) okur.
# Biçim: 0x08, ad uzunluğu (2 bayt, big-endian), ad, değer uzunluğu (2 bayt), değer (UTF-8).
function Read-NbtStrings([string]$Path, [string[]]$Keys) {
    $out = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
    $b = [IO.File]::ReadAllBytes($Path)
    if ($b.Length -ge 2 -and $b[0] -eq 0x1F -and $b[1] -eq 0x8B) {
        $ms = Microsoft.PowerShell.Utility\New-Object IO.MemoryStream(, $b)
        $gz = Microsoft.PowerShell.Utility\New-Object IO.Compression.GZipStream($ms, [IO.Compression.CompressionMode]::Decompress)
        $plain = Microsoft.PowerShell.Utility\New-Object IO.MemoryStream
        $gz.CopyTo($plain); $gz.Dispose(); $b = $plain.ToArray()
    }
    $keyBytes = @{}
    foreach ($k in $Keys) { $keyBytes[$k] = [Text.Encoding]::UTF8.GetBytes($k) }
    for ($i = 0; $i -lt $b.Length - 5; $i++) {
        if ($b[$i] -ne 8) { continue }
        $nl = ([int]$b[$i + 1] -shl 8) -bor [int]$b[$i + 2]
        foreach ($k in $Keys) {
            $kb = $keyBytes[$k]
            if ($nl -ne $kb.Length -or $i + 3 + $nl + 2 -gt $b.Length) { continue }
            $same = $true
            for ($j = 0; $j -lt $nl; $j++) { if ($b[$i + 3 + $j] -ne $kb[$j]) { $same = $false; break } }
            if (-not $same) { continue }
            $p = $i + 3 + $nl
            $vl = ([int]$b[$p] -shl 8) -bor [int]$b[$p + 1]
            if ($p + 2 + $vl -le $b.Length) { $out.Add([Text.Encoding]::UTF8.GetString($b, $p + 2, $vl)) }
        }
    }
    return , $out
}

function Invoke-AltManagers {
    foreach ($fi in $script:Found.MeteorNbt) {
        $info = Get-LauncherInfo $fi.FullName
        $where = $info[0]; if ($info[1]) { $where += " › $($info[1])" }
        $names = @()
        try {
            $raw = Read-NbtStrings $fi.FullName @('username', 'name')
            $names = @($raw | Microsoft.PowerShell.Core\Where-Object { $_ -match $script:McNameRx } | Microsoft.PowerShell.Utility\Select-Object -Unique)
        } catch { }
        foreach ($n in $names) { Add-Account $n $info[0] $info[1] 'Meteor Client alt yöneticisi' $fi.FullName $fi.LastWriteTime }
        Add-Alert 'Yüksek' 'Hile istemcisi alt yöneticisi: Meteor Client' ("{0}  [{1}]  ({2} hesap adı okundu)" -f $fi.FullName, $where, $names.Count)
    }
    foreach ($s in $script:Found.AltStores) {
        $info = Get-LauncherInfo $s.File.FullName
        $where = $info[0]; if ($info[1]) { $where += " › $($info[1])" }
        $lvl = 'Orta'; $title = "Hesap değiştirici kayıtları: $($s.Kind)"
        if ($s.Kind -like 'Wurst*') { $lvl = 'Yüksek'; $title = "Hile istemcisi alt yöneticisi: $($s.Kind)" }
        Add-Alert $lvl $title ("{0}  [{1}]  (dosya şifreli, hesap adları okunamıyor; son değişiklik: {2:yyyy-MM-dd HH:mm})" -f $s.File.FullName, $where, $s.File.LastWriteTime)
    }
}

function Test-LogIntegrity {
    foreach ($opt in $script:Found.Options) {
        if (Test-IsShadowPath $opt.FullName) { continue }
        $game = $opt.DirectoryName
        $isGameDir = [IO.File]::Exists((Microsoft.PowerShell.Management\Join-Path $game 'servers.dat')) -or [IO.Directory]::Exists((Microsoft.PowerShell.Management\Join-Path $game 'saves')) -or
        [IO.Directory]::Exists((Microsoft.PowerShell.Management\Join-Path $game 'resourcepacks')) -or [IO.Directory]::Exists((Microsoft.PowerShell.Management\Join-Path $game 'logs'))
        if (-not $isGameDir) { continue }
        $display = Resolve-OriginalPath $game
        $logs = Microsoft.PowerShell.Management\Join-Path $game 'logs'

        if (-not [IO.Directory]::Exists($logs)) {
            Add-Alert 'Orta' 'Oyun klasöründe logs klasörü yok' "$display  (oyun oynanmış ama loglar yok: silinmiş olabilir)"
            continue
        }
        $ldi = Microsoft.PowerShell.Utility\New-Object IO.DirectoryInfo($logs)
        $isWsl = $game.StartsWith('\\wsl', [StringComparison]::OrdinalIgnoreCase)
        if (-not $isWsl -and ($ldi.Attributes -band [IO.FileAttributes]::ReadOnly) -ne 0) {
            Add-Alert 'Orta' 'logs klasörü salt okunur' "$logs"
        }
        if (-not $isWsl) { try {
            $acl = Microsoft.PowerShell.Security\Get-Acl -LiteralPath $logs
            foreach ($rule in $acl.Access) {
                if ($rule.AccessControlType -eq 'Deny' -and ([int]$rule.FileSystemRights -band 0x2) -ne 0) {
                    Add-Alert 'Yüksek' 'logs klasörüne yazma engellenmiş (ACL Deny)' "$logs  ($($rule.IdentityReference)): oyunun log yazması bilinçli olarak engellenmiş"
                    break
                }
            }
        } catch { } }

        $files = @()
        try { $files = $ldi.GetFiles() } catch { }
        if ($files.Count -eq 0) {
            Add-Alert 'Orta' 'logs klasörü boş' "$logs"
            continue
        }
        $latest = $files | Microsoft.PowerShell.Core\Where-Object { $_.Name -ieq 'latest.log' } | Microsoft.PowerShell.Utility\Select-Object -First 1
        if ($latest -and $latest.Length -eq 0) {
            Add-Alert 'Orta' 'latest.log boş (0 bayt)' "$($latest.FullName)  (oyun şu an açılıyor olabilir ya da log temizlenmiş olabilir)"
        }
        foreach ($f in $files) {
            if (-not $isWsl -and ([int]$f.Attributes -band 0x6) -ne 0) {
                Add-Alert 'Orta' 'Gizli/sistem öznitelikli log dosyası' $f.FullName
            }
        }
        $newest = Get-MaxDate $files
        $lastPlay = $opt.LastWriteTime
        foreach ($marker in 'servers.dat', 'usercache.json') {
            $mp = Microsoft.PowerShell.Management\Join-Path $game $marker
            if ([IO.File]::Exists($mp)) { $t = [IO.File]::GetLastWriteTime($mp); if ($t -gt $lastPlay) { $lastPlay = $t } }
        }
        if ($newest -and ($lastPlay - $newest).TotalHours -gt 24) {
            Add-Alert 'Orta' 'Loglar, oyunun son kullanımından eski' ("{0}  (son log: {1:yyyy-MM-dd HH:mm}, son oyun etkinliği: {2:yyyy-MM-dd HH:mm}); loglar silinmiş ya da log yazımı kapatılmış olabilir" -f $display, $newest, $lastPlay)
        }
    }

    foreach ($fi in $script:Found.LogConfigs) {
        if (Test-IsShadowPath $fi.FullName) { continue }
        try {
            $x = [IO.File]::ReadAllText($fi.FullName)
            if ($x -match '(?i)level\s*=\s*"off"' -or $x -notmatch '(?i)logs/latest\.log') {
                Add-Alert 'Yüksek' 'Minecraft log yapılandırması değiştirilmiş' "$($fi.FullName)  (latest.log yazımı kapatılmış ya da yönlendirilmiş olabilir)"
            }
        } catch { }
    }

    foreach ($fi in $script:Found.Configs) {
        if (Test-IsShadowPath $fi.FullName) { continue }
        try {
            $x = [IO.File]::ReadAllText($fi.FullName)
            if ($x -match '(?i)-Dlog4j2?\.(configurationFile|level|rootLogger\w*)|log4j2?\.configurationFile') {
                Add-Alert 'Yüksek' 'Launcher ayarlarında özel log4j parametresi' "$($fi.FullName)  (JVM argümanlarıyla oyun logu kapatılmış olabilir)"
            }
        } catch { }
    }
}

function Invoke-ProcessScan {
    $procs = @()
    try { $procs = @(CimCmdlets\Get-CimInstance -ClassName Win32_Process -Filter "Name='javaw.exe' OR Name='java.exe'") } catch { }
    foreach ($p in $procs) {
        $cmd = [string]$p.CommandLine
        if (-not $cmd) { continue }
        if ($cmd -notmatch '(?i)(minecraft|--username|lunar|net\.fabricmc|cpw\.mods|forge)') { continue }
        $user = $null
        if ($cmd -match '--username[\s=]+"?([^\s"]+)') { $user = $Matches[1] }
        $gameDir = ''
        if ($cmd -match '--gameDir\s+"([^"]+)"') { $gameDir = $Matches[1] }
        elseif ($cmd -match '--gameDir\s+(\S+)') { $gameDir = $Matches[1] }
        $exe = [string]$p.ExecutablePath
        $info = Get-LauncherInfo ((($gameDir, $exe) | Microsoft.PowerShell.Core\Where-Object { $_ } | Microsoft.PowerShell.Utility\Select-Object -First 1) + '\x')
        if ($user) {
            Add-Account $user $info[0] $info[1] "şu an açık oyun (PID $($p.ProcessId))" $gameDir ([DateTime]::Now)
        }
        if ($cmd -match '(?i)-Dlog4j2?\.configurationFile=("?)([^\s"]+)') {
            $cfg = $Matches[2]
            if ($cfg -notmatch '(?i)[\\/]log_configs[\\/]client-1\.\d+\.xml$') {
                Add-Alert 'Orta' 'Çalışan oyunda standart dışı log4j yapılandırması' "PID $($p.ProcessId): $cfg"
            }
        }
        if ($cmd -match '(?i)-Dlog4j2?\.level=off|-Dlog4j2?\.rootLogger\w*=off') {
            Add-Alert 'Yüksek' 'Çalışan oyunda loglama kapatılmış' "PID $($p.ProcessId)"
        }
    }
}

$script:WslRoots = @{}
$script:WslSummary = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
$script:WslBasePaths = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

function Invoke-Native {

    param([string]$Exe, [string]$Arguments, [int]$TimeoutMs = 15000, [Text.Encoding]$Enc = $null)
    try {
        $psi = Microsoft.PowerShell.Utility\New-Object Diagnostics.ProcessStartInfo
        $psi.FileName = $Exe
        $psi.Arguments = $Arguments
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.StandardOutputEncoding = [Text.Encoding]::UTF8
        if ($null -ne $Enc) { $psi.StandardOutputEncoding = $Enc }
        $psi.EnvironmentVariables['WSL_UTF8'] = '1'
        $proc = [Diagnostics.Process]::Start($psi)
        $task = $proc.StandardOutput.ReadToEndAsync()
        [void]$proc.StandardError.ReadToEndAsync()
        # Tek seferde beklemek yerine 100 ms'lik adımlarla bekle ve arada ekranı yenile; yoksa uzun komutlarda
        # (ör. USN günlüğü okuma, dakikalar sürebilir) arayüz donar ve süre sayacı durur.
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $exited = $false
        while ($true) {
            if ($proc.WaitForExit(100)) { $exited = $true; break }
            if ($sw.ElapsedMilliseconds -ge $TimeoutMs) { break }
            Update-UiTick
        }
        if (-not $exited) {
            # Süreç ağacının tamamını kapat: $Exe cmd.exe ise alt süreçler (fsutil, findstr) yoksa çalışmaya devam eder.
            try {
                $tk = Microsoft.PowerShell.Management\Join-Path $env:SystemRoot 'System32\taskkill.exe'
                $kpsi = Microsoft.PowerShell.Utility\New-Object Diagnostics.ProcessStartInfo
                $kpsi.FileName = $tk; $kpsi.Arguments = "/T /F /PID $($proc.Id)"
                $kpsi.UseShellExecute = $false; $kpsi.CreateNoWindow = $true
                $kp = [Diagnostics.Process]::Start($kpsi); [void]$kp.WaitForExit(10000)
            } catch { }
            try { if (-not $proc.HasExited) { $proc.Kill() } } catch { }
            return $null
        }
        return ($task.Result -replace "`0", '')
    } catch { return $null }
}

function Get-WslDistros {
    $hives = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
    $hives.Add('Registry::HKEY_CURRENT_USER')
    try {
        foreach ($k in Microsoft.PowerShell.Management\Get-ChildItem 'Registry::HKEY_USERS') {
            if ($k.PSChildName -match '^S-1-5-21-[\d-]+$') { $hives.Add("Registry::HKEY_USERS\$($k.PSChildName)") }
        }
    } catch { }
    $seen = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $list = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    foreach ($h in $hives) {
        $lxss = "$h\Software\Microsoft\Windows\CurrentVersion\Lxss"
        $subs = @()
        try { $subs = @(Microsoft.PowerShell.Management\Get-ChildItem -LiteralPath $lxss -ErrorAction Stop) } catch { continue }
        foreach ($s in $subs) {
            $p = Microsoft.PowerShell.Management\Get-ItemProperty -LiteralPath $s.PSPath
            if (-not $p.DistributionName) { continue }
            $base = [string]$p.BasePath
            if ($base.StartsWith('\\?\')) { $base = $base.Substring(4) }
            $key = "$($p.DistributionName)|$base"
            if (-not $seen.Add($key)) { continue }
            $ver = 1; if ($p.Version) { $ver = [int]$p.Version }
            $list.Add([pscustomobject]@{ Name = [string]$p.DistributionName; BasePath = $base; Version = $ver; State = 'Bilinmiyor' })
            if ($base) { [void]$script:WslBasePaths.Add($base.TrimEnd('\')) }
        }
    }
    return , $list
}

function Get-WslLinuxRoots([string]$Root) {

    $homes = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string]
    try { foreach ($h in [IO.Directory]::GetDirectories((Microsoft.PowerShell.Management\Join-Path $Root 'home'))) { $homes.Add($h) } } catch { }
    $homes.Add((Microsoft.PowerShell.Management\Join-Path $Root 'root'))
    $known = '.minecraft', '.lunarclient', '.tlauncher', '.feather', '.technic', '.local\share\PrismLauncher', '.local\share\PolyMC',
    '.local\share\multimc', '.local\share\ATLauncher', '.local\share\ModrinthApp', '.local\share\com.modrinth.theseus',
    '.config\gdlauncher_next', '.var\app\com.mojang.Minecraft', '.var\app\org.prismlauncher.PrismLauncher', '.var\app\org.polymc.PolyMC',
    '.var\app\com.atlauncher.ATLauncher', '.var\app\com.modrinth.ModrinthApp', 'MultiMC', 'PrismLauncher',
    '.hmcl', '.local\share\hmcl', '.local\share\PollyMC', '.local\share\FjordLauncher', '.local\share\ElyPrismLauncher',
    '.local\share\FreesmLauncher', '.config\xmcl', 'UltimMC'
    $out = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    foreach ($h in $homes) { foreach ($k in $known) { $out.Add(@((Microsoft.PowerShell.Management\Join-Path $h $k), -1)) } }
    switch ($Mode) {
        'Quick' { }
        'Normal' {
            foreach ($h in $homes) { $out.Add(@($h, 8)) }
            foreach ($d in 'opt', 'srv', 'tmp', 'var\tmp', 'usr\local', 'usr\games') { $out.Add(@((Microsoft.PowerShell.Management\Join-Path $Root $d), 6)) }
        }
        'Deep' {
            $subs = @(); try { $subs = [IO.Directory]::GetDirectories($Root) } catch { }
            foreach ($s in $subs) {
                if ([IO.Path]::GetFileName($s) -in 'mnt', 'proc', 'sys', 'dev', 'run', 'lost+found') { continue }
                $out.Add(@($s, -1))
            }
        }
    }
    return , $out
}

function Get-WslCache {
    if ($null -ne $script:WslCache) { return , $script:WslCache }
    $distros = Get-WslDistros
    $wslExe = Microsoft.PowerShell.Management\Join-Path $env:SystemRoot 'System32\wsl.exe'
    if ($distros.Count -gt 0 -and [IO.File]::Exists($wslExe)) {
        $txt = Invoke-Native $wslExe '--list --verbose' 15000
        if ($txt) {
            foreach ($line in ($txt -split "`r?`n")) {
                $l = $line.Trim().TrimStart('*').Trim()
                $parts = @($l -split '\s{2,}' | Microsoft.PowerShell.Core\Where-Object { $_ })
                if ($parts.Count -ge 3) {
                    foreach ($d in $distros) { if ($d.Name -eq $parts[0]) { $d.State = $parts[1] } }
                }
            }
        }
    }
    $script:WslCache = $distros
    return , $distros
}

function Invoke-WslScan {
    if ($NoWsl) { $script:WslSummary.Add('WSL taraması kapatıldı (-NoWsl)'); return }
    $distros = Get-WslCache
    $wslExe = Microsoft.PowerShell.Management\Join-Path $env:SystemRoot 'System32\wsl.exe'
    $di = 0
    foreach ($d in $distros) {
        $di++
        Show-Progress -Status "$di / $($distros.Count)" -Percent ([int](100 * ($di - 1) / [Math]::Max(1, $distros.Count))) -Force
        $running = ($d.State -match '(?i)running|çalış')
        $stateTxt = if ($running) { 'çalışıyor' } elseif ($d.State -eq 'Bilinmiyor') { 'durum bilinmiyor' } else { 'durmuş' }
        $script:WslSummary.Add("$($d.Name) (WSL$($d.Version), $stateTxt)")
        if ($d.Name -match '(?i)^docker-desktop') { continue }

        $root = $null
        if ($d.Version -eq 1 -and $d.BasePath -and [IO.Directory]::Exists((Microsoft.PowerShell.Management\Join-Path $d.BasePath 'rootfs'))) {
            $root = Microsoft.PowerShell.Management\Join-Path $d.BasePath 'rootfs'
        } else {
            Show-Progress -Id 1 -Activity 'WSL' -Status "$($d.Name) bağlanıyor..." -Force
            foreach ($cand in "\\wsl.localhost\$($d.Name)", "\\wsl$\$($d.Name)") {
                if ([IO.Directory]::Exists($cand)) { $root = $cand; break }
            }
            if ($root -and -not $running) {
                Add-Alert 'Bilgi' "WSL dağıtımı taranmak için başlatıldı: $($d.Name)" 'Tarama bitince "wsl --terminate <ad>" ile kapatabilirsiniz.'
            }
        }
        if (-not $root) {
            Add-Alert 'Orta' "WSL dağıtımına erişilemedi: $($d.Name)" "İçindeki Minecraft dosyaları taranamadı. Konum: $($d.BasePath)"
            continue
        }
        $script:WslRoots[$root] = $d.Name

        $wr = Get-WslLinuxRoots $root
        $script:WalkTotal = $wr.Count; $script:WalkDone = 0
        foreach ($w in $wr) { $script:WalkRoot = [string]$w[0]; Invoke-Walk ([string]$w[0]) ([int]$w[1]); $script:WalkDone++ }

        if ($running -and [IO.File]::Exists($wslExe)) {
            $ps = Invoke-Native $wslExe "-d `"$($d.Name)`" --exec ps -eo args" 10000
            if ($ps) {
                foreach ($line in ($ps -split "`r?`n")) {
                    if ($line -notmatch '(?i)(minecraft|--username)') { continue }
                    if ($line -match '--username[\s=]+"?([^\s"]+)') {
                        $u = $Matches[1]
                        $gd = ''
                        if ($line -match '--gameDir\s+(\S+)') { $gd = $root + ($Matches[1] -replace '/', '\') }
                        $info = Get-LauncherInfo ($(if ($gd) { $gd } else { $root }) + '\x')
                        Add-Account $u $info[0] $info[1] 'şu an açık oyun (WSL)' $gd ([DateTime]::Now)
                    }
                    if ($line -match '(?i)-Dlog4j2?\.level=off') { Add-Alert 'Yüksek' "WSL'deki oyunda loglama kapatılmış" $d.Name }
                }
            }
        }
    }
}

function Test-LinuxInstall {

    foreach ($fi in $script:Found.Disks) {
        $sizeGb = [Math]::Round($fi.Length / 1GB, 1)
        if ($fi.Name -ieq 'ext4.vhdx') {
            if (-not $script:WslBasePaths.Contains($fi.DirectoryName.TrimEnd('\'))) {
                Add-Alert 'Orta' 'Kayıtlı olmayan WSL diski (ext4.vhdx)' "$($fi.FullName)  ($sizeGb GB): WSL'den kaldırılmış ya da dışa aktarılmış bir Linux olabilir, içi taranamadı"
            }
        } else {
            Add-Alert 'Bilgi' 'Sanal makine diski bulundu' "$($fi.FullName)  ($sizeGb GB): içinde Linux/Minecraft olabilir, taranamaz"
        }
    }

    $lp = Get-LinuxPartitions
    if ($lp.Ok -and $lp.Items.Count -gt 0) {
        Add-Alert 'Orta' 'Bilgisayarda Linux bölümü var (dual boot)' (($lp.Items -join ', ') + '. Linux tarafındaki dosyalar Windows''tan okunamaz; orada başka hesaplar olabilir.')
        $script:WslSummary.Add('Linux bölümü (dual boot) bulundu')
    } elseif (-not $lp.Ok) { $script:WslSummary.Add('Disk bölümleri kontrol edilemedi (yönetici gerekli)') }
    $lb = Get-LinuxBootEntries
    if ($lb.Ok -and $lb.Items.Count -gt 0) { Add-Alert 'Orta' 'UEFI önyükleme menüsünde Linux girdisi var' ($lb.Items -join ', ') }
    $vm = Get-VmSoftware
    if ($vm.Count -gt 0) { Add-Alert 'Bilgi' 'Sanal makine yazılımı kurulu' ($vm -join ', ') }
}

$script:zq4 = 63, 32, 108, 107, 106
$script:zqB = 'bWFkZSBieSB+ZXh0ZXo2MTA='
$script:zqD = 109, 97, 100, 101, 32, 98, 121, 32, 126, 101, 120, 116, 101, 122, 54, 49, 48
$script:zqH = '6d3e9e83339678bd4ea883c06f55ecd9516b68c5f4bac996e008503dd78ef159'
$script:BusMap = @{ 1 = 'SCSI'; 2 = 'ATAPI'; 3 = 'ATA'; 6 = 'Fibre Channel'; 7 = 'USB'; 8 = 'RAID'; 9 = 'iSCSI'; 10 = 'SAS'; 11 = 'SATA'; 12 = 'SD'; 13 = 'MMC'; 15 = 'Sanal'; 16 = 'Storage Spaces'; 17 = 'NVMe' }
$script:MediaMap = @{ 0 = ''; 3 = 'HDD'; 4 = 'SSD'; 5 = 'SCM' }
$script:zqR = 48, 49, 54, 122, 101, 116, 120, 101, 126, 32, 121, 98, 32, 101, 100, 97, 109
$script:MemTypeMap = @{ 20 = 'DDR'; 21 = 'DDR2'; 24 = 'DDR3'; 26 = 'DDR4'; 29 = 'LPDDR3'; 30 = 'LPDDR4'; 34 = 'DDR5'; 35 = 'LPDDR5' }

function Get-SystemInfo {
    $s = [ordered]@{
        OS = 'Bilinmiyor'; Device = ''; Cpu = 'Bilinmiyor'; Cores = 0; Threads = [Environment]::ProcessorCount; CpuMHz = 0; CpuLoad = 0
        RamTotalGB = 0; RamFreeGB = 0; RamText = ''; Gpu = @(); Disks = @(); SystemDiskKind = 'Bilinmiyor'; Boot = $null
    }
    try {
        $os = CimCmdlets\Get-CimInstance Win32_OperatingSystem
        $cv = Microsoft.PowerShell.Management\Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        $caption = ([string]$os.Caption) -replace '^Microsoft\s+', ''
        $build = [int]$os.BuildNumber
        if ($build -ge 22000) { $caption = $caption -replace 'Windows 10', 'Windows 11' }
        $disp = [string]$cv.DisplayVersion; if (-not $disp) { $disp = [string]$cv.ReleaseId }
        $s.OS = ("{0} {1}  (Build {2}.{3}, {4})" -f $caption.Trim(), $disp, $build, $cv.UBR, $os.OSArchitecture) -replace '\s{2,}\(', '  ('
        $s.Boot = $os.LastBootUpTime
        $s.RamTotalGB = [double]$os.TotalVisibleMemorySize / 1MB
        $s.RamFreeGB = [double]$os.FreePhysicalMemory / 1MB
    } catch { }
    try {
        $cs = CimCmdlets\Get-CimInstance Win32_ComputerSystem
        $s.Device = ("{0} {1}" -f $cs.Manufacturer, $cs.Model).Trim()
    } catch { }
    try {
        $cpus = @(CimCmdlets\Get-CimInstance Win32_Processor)
        if ($cpus.Count -gt 0) {
            $s.Cpu = ([string]$cpus[0].Name).Trim() -replace '\s{2,}', ' '
            $s.Cores = ($cpus | Microsoft.PowerShell.Utility\Measure-Object -Property NumberOfCores -Sum).Sum
            $s.Threads = ($cpus | Microsoft.PowerShell.Utility\Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
            $s.CpuMHz = [int]$cpus[0].MaxClockSpeed
            $s.CpuLoad = [int]($cpus | Microsoft.PowerShell.Utility\Measure-Object -Property LoadPercentage -Average).Average
        }
    } catch { }
    try {
        $mods = @(CimCmdlets\Get-CimInstance Win32_PhysicalMemory)
        if ($mods.Count -gt 0) {
            $speed = ($mods | Microsoft.PowerShell.Core\ForEach-Object { if ($_.ConfiguredClockSpeed) { $_.ConfiguredClockSpeed } else { $_.Speed } } | Microsoft.PowerShell.Utility\Measure-Object -Maximum).Maximum
            $type = $script:MemTypeMap[[int]$mods[0].SMBIOSMemoryType]
            $parts = @()
            if ($type) { $parts += $type }
            if ($speed) { $parts += "$speed MHz" }
            $parts += "$($mods.Count) modül"
            $s.RamText = $parts -join ', '
        }
    } catch { }
    try { $s.Gpu = @(CimCmdlets\Get-CimInstance Win32_VideoController | Microsoft.PowerShell.Core\Where-Object { $_.Name } | Microsoft.PowerShell.Core\ForEach-Object { ([string]$_.Name).Trim() } | Microsoft.PowerShell.Utility\Select-Object -Unique) } catch { }

    $winsatSeq = $null; $winsatDate = $null
    try {
        $ds = Microsoft.PowerShell.Management\Join-Path $env:SystemRoot 'Performance\WinSAT\DataStore'
        $xmlFile = ([IO.DirectoryInfo]$ds).GetFiles('*.WinSAT.xml') | Microsoft.PowerShell.Core\Where-Object { $_.Name -match '(?i)formal|disk' } | Microsoft.PowerShell.Utility\Sort-Object LastWriteTime -Descending | Microsoft.PowerShell.Utility\Select-Object -First 1
        if ($xmlFile) {
            $x = [IO.File]::ReadAllText($xmlFile.FullName)
            if ($x -match '(?is)<AvgThroughput[^>]*Sequential Read[^>]*>\s*([\d.]+)') {
                $winsatSeq = [double]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture); $winsatDate = $xmlFile.LastWriteTime
            }
        }
    } catch { }

    $sysLetter = ([string]$env:SystemDrive).TrimEnd(':').ToUpperInvariant()
    $letters = @{}
    try {
        foreach ($p in Storage\Get-Partition -ErrorAction Stop) {
            if ($p.DriveLetter -and [char]$p.DriveLetter -ne [char]0) {
                $k = [string]$p.DiskNumber
                if (-not $letters.ContainsKey($k)) { $letters[$k] = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[string] }
                $letters[$k].Add([string]$p.DriveLetter)
            }
        }
    } catch { }
    $free = @{}
    try { foreach ($ld in CimCmdlets\Get-CimInstance Win32_LogicalDisk) { $free[([string]$ld.DeviceID).TrimEnd(':')] = $ld } } catch { }

    $disks = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    $phys = @()
    try { $phys = @(Storage\Get-PhysicalDisk -ErrorAction Stop) } catch { }
    if ($phys.Count -gt 0) {
        foreach ($pd in $phys | Microsoft.PowerShell.Utility\Sort-Object { [int]$_.DeviceId }) {
            $bus = [string]$pd.BusType; if ($bus -match '^\d+$') { $bus = $script:BusMap[[int]$bus] }
            $media = [string]$pd.MediaType; if ($media -match '^\d+$') { $media = $script:MediaMap[[int]$media] }
            $name = ([string]$pd.FriendlyName).Trim()
            $kind = 'Bilinmiyor'
            if ($bus -eq 'NVMe' -or $name -match '(?i)nvme') { $kind = 'NVMe' }
            elseif ($bus -eq 'USB') { $kind = 'USB' }
            elseif ($media -eq 'SSD' -or $name -match '(?i)\bssd\b') { $kind = 'SSD' }
            elseif ($media -eq 'HDD') { $kind = 'HDD' }
            $lt = @(); if ($letters.ContainsKey([string]$pd.DeviceId)) { $lt = @($letters[[string]$pd.DeviceId]) }
            $disks.Add([pscustomobject]@{ Name = $name; Bus = $bus; Media = $media; Kind = $kind; SizeGB = [double]$pd.Size / 1GB; Letters = $lt; IsSystem = ($lt -contains $sysLetter) })
        }
    } else {
        try {
            foreach ($dd in CimCmdlets\Get-CimInstance Win32_DiskDrive) {
                $kind = 'Bilinmiyor'
                if ($dd.Model -match '(?i)nvme') { $kind = 'NVMe' } elseif ($dd.InterfaceType -eq 'USB') { $kind = 'USB' } elseif ($dd.Model -match '(?i)ssd') { $kind = 'SSD' }
                $lt = @(); if ($letters.ContainsKey([string]$dd.Index)) { $lt = @($letters[[string]$dd.Index]) }
                $disks.Add([pscustomobject]@{ Name = ([string]$dd.Model).Trim(); Bus = [string]$dd.InterfaceType; Media = ''; Kind = $kind; SizeGB = [double]$dd.Size / 1GB; Letters = $lt; IsSystem = ($lt -contains $sysLetter) })
            }
        } catch { }
    }
    foreach ($d in $disks) {
        $sp = switch ($d.Kind) {
            'NVMe' { 'tahmini ~1.500-7.000 MB/sn' }
            'SSD' { 'tahmini ~450-550 MB/sn' }
            'HDD' { 'tahmini ~80-200 MB/sn' }
            'USB' { 'USB: bağlantıya göre değişir' }
            default { 'hız bilinmiyor' }
        }
        if ($d.IsSystem -and $winsatSeq) { $sp = ("ölçülen ~{0:N0} MB/sn sıralı okuma (WinSAT, {1:yyyy-MM-dd})" -f $winsatSeq, $winsatDate) }
        $vol = @()
        foreach ($l in $d.Letters) {
            $ld = $free[$l]
            if ($ld -and $ld.Size) { $vol += ("{0}: {1:N0}/{2:N0} GB boş" -f $l, ($ld.FreeSpace / 1GB), ($ld.Size / 1GB)) } else { $vol += "${l}:" }
        }
        $d | Microsoft.PowerShell.Utility\Add-Member -NotePropertyName Speed -NotePropertyValue $sp
        $d | Microsoft.PowerShell.Utility\Add-Member -NotePropertyName Volumes -NotePropertyValue ($vol -join ', ')
        if ($d.IsSystem) { $s.SystemDiskKind = $d.Kind }
    }
    $s.Disks = $disks.ToArray()
    return [pscustomobject]$s
}

function Get-LinuxPartitions {
    if ($null -ne $script:LinuxParts) { return $script:LinuxParts }
    $linuxGpt = '0fc63daf-8483-4772-8e79-3d69d8477de4', '4f68bce3-e8cd-4db1-96e7-fbcaf984b709', '933ac7e1-2eb4-4f13-b844-0e14e2aef915',
    '0657fd6d-a4ab-43c4-84e5-0933c84b4f4f', 'e6d6d379-f507-44c2-a23c-238f2a3df928', 'b921b045-1df0-41c3-af44-4c6f280d3fae'
    $res = [pscustomobject]@{ Ok = $false; Items = @() }
    try {
        $found = @()
        foreach ($p in Storage\Get-Partition -ErrorAction Stop) {
            $g = ([string]$p.GptType).Trim('{}').ToLowerInvariant()
            if (($g -and $linuxGpt -contains $g) -or ([int]$p.MbrType -in 130, 131, 142)) {
                $found += ("Disk {0} / Bölüm {1} ({2:N1} GB)" -f $p.DiskNumber, $p.PartitionNumber, ($p.Size / 1GB))
            }
        }
        $res = [pscustomobject]@{ Ok = $true; Items = $found }
    } catch { }
    $script:LinuxParts = $res
    return $res
}

function Get-LinuxBootEntries {
    if ($null -ne $script:LinuxBoot) { return $script:LinuxBoot }
    $res = [pscustomobject]@{ Ok = $false; Items = @() }
    if ($script:IsAdmin) {
        $bcd = Invoke-Native (Microsoft.PowerShell.Management\Join-Path $env:SystemRoot 'System32\bcdedit.exe') '/enum firmware' 10000
        if ($bcd) {
            $names = @([regex]::Matches($bcd, '(?im)^\s*description\s+(.*(ubuntu|debian|fedora|arch|mint|manjaro|opensuse|suse|pop!?_?os|grub|linux|kali|zorin|elementary|endeavour|gentoo|nixos|centos|rocky|alma).*)$') |
                    Microsoft.PowerShell.Core\ForEach-Object { $_.Groups[1].Value.Trim() } | Microsoft.PowerShell.Utility\Select-Object -Unique)
            $res = [pscustomobject]@{ Ok = $true; Items = $names }
        }
    }
    $script:LinuxBoot = $res
    return $res
}

function Get-VmSoftware {
    $list = @()
    $pf = $env:ProgramFiles; $pf86 = ${env:ProgramFiles(x86)}
    if ([IO.Directory]::Exists("$pf\Oracle\VirtualBox")) { $list += 'VirtualBox' }
    foreach ($b in $pf, $pf86) {
        if ($b -and ([IO.Directory]::Exists("$b\VMware\VMware Workstation") -or [IO.Directory]::Exists("$b\VMware\VMware Player"))) { $list += 'VMware'; break }
    }
    if ([IO.Directory]::Exists("$pf\qemu")) { $list += 'QEMU' }
    if ([IO.Directory]::Exists("$pf\Docker\Docker")) { $list += 'Docker Desktop' }
    try { if (Microsoft.PowerShell.Management\Get-Service -Name vmms -ErrorAction Stop) { $list += 'Hyper-V' } } catch { }
    return , @($list | Microsoft.PowerShell.Utility\Select-Object -Unique)
}

function Get-OptimalSettings($Sys) {
    $lp = [int]$Sys.Threads; if ($lp -lt 1) { $lp = [Environment]::ProcessorCount }
    switch ($Sys.SystemDiskKind) {
        'NVMe' { $t = [Math]::Min($lp, 16); $why = 'NVMe SSD: yüksek paralellik' }
        'SSD' { $t = [Math]::Min($lp, 8); $why = 'SATA SSD: orta-yüksek paralellik' }
        'HDD' { $t = 2; $why = 'HDD: düşük paralellik (disk kafası sürekli gidip gelmesin)' }
        default { $t = [Math]::Min($lp, 6); $why = 'disk türü bilinmiyor: dengeli ayar' }
    }
    if ($lp -gt 2) { $t = [Math]::Min($t, $lp - 1) }
    $free = [double]$Sys.RamFreeGB
    if ($free -gt 0 -and $free -lt 2) { $t = [Math]::Min($t, 2); $why += ', boş RAM az' }
    elseif ($free -gt 0 -and $free -lt 4) { $t = [Math]::Min($t, 4); $why += ', boş RAM sınırlı' }
    if ($Sys.CpuLoad -ge 80) { $t = [Math]::Max(1, [int]($t / 2)); $why += ', işlemci şu an yoğun' }
    if ($Threads -gt 0) { $t = $Threads; $why = 'elle ayarlandı (-Threads)' }
    $t = [Math]::Max(1, [int]$t)
    if ($free -le 0) { $free = 4 }
    $capRel = [long][Math]::Max(32MB, [Math]::Min(512MB, ($free * 1GB * 0.5) / ($t * 3)))
    $capOther = [long][Math]::Min(64MB, $capRel)
    return [pscustomobject]@{ Threads = $t; Reason = $why; CapRelevant = $capRel; CapOther = $capOther }
}

function Add-PanelItem($L, [string]$Label, $Values, [string]$Color = 'Gray') {
    $vals = @($Values | Microsoft.PowerShell.Core\Where-Object { $_ -ne $null -and "$_" -ne '' })
    if ($vals.Count -eq 0) { return }
    $pad = '   ' + $Label.PadRight(12) + ': '
    $L.Add(@(($pad + $vals[0]), $Color))
    for ($i = 1; $i -lt $vals.Count; $i++) { $L.Add(@(((' ' * $pad.Length) + $vals[$i]), $Color)) }
}

function Get-PanelLines {
    $L = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    $S = $script:Sys
    $L.Add(@('  AltDetectorX', 'Cyan'))
    $L.Add(@('', 'Gray'))
    $L.Add(@('  # SİSTEM', 'White'))
    $osParts = @(([string]$S.OS) -split '\s{2,}\(' | Microsoft.PowerShell.Core\ForEach-Object { $_.Trim().TrimEnd(')') })
    Add-PanelItem $L 'Windows' $osParts
    Add-PanelItem $L 'Cihaz' @($S.Device)
    $cpuVals = @($S.Cpu)
    if ($S.Cores) {
        $cpuVals += ("{0} çekirdek / {1} iş parçacığı" -f $S.Cores, $S.Threads)
        $cpuVals += ("{0:N1} GHz, yük %{1}" -f ($S.CpuMHz / 1000), $S.CpuLoad)
    }
    Add-PanelItem $L 'İşlemci' $cpuVals
    $ram = "{0:N0} GB" -f $S.RamTotalGB
    if ($S.RamText) { $ram += ", $($S.RamText)" }
    Add-PanelItem $L 'RAM' @($ram, ("boş {0:N1} GB" -f $S.RamFreeGB))
    Add-PanelItem $L 'Ekran kartı' @($S.Gpu)
    if ($S.Boot) {
        $up = [DateTime]::Now - $S.Boot
        Add-PanelItem $L 'Son açılış' @(("{0:yyyy-MM-dd HH:mm}" -f $S.Boot), ("{0} gün {1} saat önce" -f $up.Days, $up.Hours))
    }
    if ($S.Disks.Count -eq 0) { Add-PanelItem $L 'Disk' @('okunamadı') 'DarkGray' }
    foreach ($d in $S.Disks) {
        $kindTxt = switch ($d.Kind) { 'NVMe' { 'NVMe SSD' } 'SSD' { 'SATA SSD' } 'HDD' { 'HDD' } 'USB' { 'USB disk' } default { "$($d.Bus) $($d.Media)".Trim() } }
        $nm = $d.Name; if ($d.IsSystem) { $nm += ' [sistem]' }
        $vals = @($nm, ("{0}, {1:N0} GB" -f $kindTxt, $d.SizeGB), $d.Speed)
        if ($d.Volumes) { $vals += @($d.Volumes -split ',\s*') }
        Add-PanelItem $L 'Disk' $vals
    }

    $L.Add(@('', 'Gray'))
    $L.Add(@('  # LINUX / WSL', 'White'))
    $ds = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
    if ($null -ne $script:WslCache) { foreach ($x in $script:WslCache) { $ds.Add($x) } }
    if ($ds.Count -eq 0) { Add-PanelItem $L 'WSL' @('kurulu dağıtım yok') }
    else {
        $wv = foreach ($x in $ds) {
            $st = 'durmuş'
            if ($x.State -match '(?i)running|çalış') { $st = 'çalışıyor' } elseif ($x.State -eq 'Bilinmiyor') { $st = 'durum bilinmiyor' }
            "$($x.Name) (WSL$($x.Version), $st)"
        }
        Add-PanelItem $L 'WSL' @($wv) 'Yellow'
    }
    $lp = Get-LinuxPartitions
    if (-not $lp.Ok) { Add-PanelItem $L 'Dual boot' @('kontrol edilemedi') 'DarkGray' }
    elseif ($lp.Items.Count -gt 0) { Add-PanelItem $L 'Dual boot' (@('Linux bölümü var') + @($lp.Items)) 'Yellow' }
    else { Add-PanelItem $L 'Dual boot' @('Linux bölümü yok') }
    $lb = Get-LinuxBootEntries
    if ($lb.Ok -and $lb.Items.Count -gt 0) { Add-PanelItem $L 'Önyükleme' @($lb.Items) 'Yellow' }
    $vm = Get-VmSoftware
    if ($vm.Count -gt 0) { Add-PanelItem $L 'Sanal makine' @($vm) 'Yellow' } else { Add-PanelItem $L 'Sanal makine' @('yok') }

    $L.Add(@('', 'Gray'))
    $L.Add(@('  # TARAMA AYARI', 'White'))
    Add-PanelItem $L 'Paralellik' @(("{0} iş parçacığı" -f $script:Settings.Threads))
    Add-PanelItem $L 'Öncelik' @('düşük')
    Add-PanelItem $L 'Dosya sınırı' @(("{0:N0} MB" -f ($script:Settings.CapRelevant / 1MB)))
    Add-PanelItem $L 'Neden' @($script:Settings.Reason -split ',\s*')
    if (-not $script:IsAdmin) { Add-PanelItem $L 'Yönetici' @('hayır', 'bazı kontroller atlanacak') 'DarkYellow' }
    return , $L
}

function Show-Menu {
    $items = @(
        @{ Type = 'scan'; Mode = 'Quick'; Label = 'Hızlı Tarama' },
        @{ Type = 'scan'; Mode = 'Normal'; Label = 'Normal Tarama' },
        @{ Type = 'scan'; Mode = 'Deep'; Label = 'Tam Tarama' },
        @{ Type = 'sep' },
        @{ Type = 'opt'; Key = 'Paths'; Label = 'Dosya yollarını göster' },
        @{ Type = 'opt'; Key = 'Wsl'; Label = 'WSL dağıtımlarını tara' },
        @{ Type = 'opt'; Key = 'Export'; Label = 'Raporu masaüstüne kaydet' },
        @{ Type = 'sep' },
        @{ Type = 'exit'; Label = 'Çıkış' }
    )
    # Menüde tüm seçenekler varsayılan olarak açık gelir; kullanıcı Boşluk ile kapatabilir.
    $opts = @{ Paths = $true; Wsl = $true; Export = $true }
    $sel = 1
    $panel = Get-PanelLines
    $arrow = [string][char]0x25BA
    $script:MenuInit = $false
    $prevRows = 0
    while ($true) {
        try { [Console]::CursorVisible = $false } catch { }
        $m = $script:MarginText
        $pw = Get-OutWidth

        # Çizilecek satırları renkli parçalar halinde hazırla (her satır = parça listesi).
        $rows = Microsoft.PowerShell.Utility\New-Object System.Collections.Generic.List[object]
        $rows.Add(@())
        foreach ($l in $panel) {
            if (-not $l[0]) { $rows.Add(@()); continue }
            foreach ($ln in (Split-Wrap ([string]$l[0]) $pw (' ' * 17))) { $rows.Add(@(@{ T = $m + $ln; F = $l[1] })) }
        }
        $rows.Add(@())
        $rows.Add(@(@{ T = $m + '  ' + ([string][char]0x2500 * [Math]::Min(66, $pw - 4)); F = 'DarkCyan' }))
        for ($i = 0; $i -lt $items.Count; $i++) {
            $it = $items[$i]
            if ($it.Type -eq 'sep') { $rows.Add(@()); continue }
            $on = ($i -eq $sel)
            $prefix = '    '; if ($on) { $prefix = "  $arrow " }
            $text = $it.Label
            if ($it.Type -eq 'opt') { $box = '[ ]'; if ($opts[$it.Key]) { $box = '[x]' }; $text = "$box $($it.Label)" }
            $lbl = (" {0,-28}" -f $text)
            if ($on) { $rows.Add(@(@{ T = $m + $prefix; F = 'Cyan' }, @{ T = $lbl; F = 'Black'; B = 'Cyan' })) }
            else { $rows.Add(@(@{ T = $m + $prefix; F = 'Cyan' }, @{ T = $lbl; F = 'White' })) }
        }
        $rows.Add(@())
        $hint = ("  {0}/{1} - SEÇ     ENTER - ONAYLA     BO{2}LUK - AÇ/KAPAT     1-2-3 - HIZLI SEÇİM     ESC - ÇIKI{2}" -f [char]0x2191, [char]0x2193, [char]0x015E)
        foreach ($ln in (Split-Wrap $hint $pw '  ')) { $rows.Add(@(@{ T = $m + $ln; F = 'DarkGray' })) }
        $rows.Add(@())
        $rows.Add(@(@{ T = $m + (Get-SigPadded $pw); F = 'DarkGray' }))

        $useCur = $false
        try { $useCur = -not [Console]::IsOutputRedirected } catch { $useCur = $false }

        if ($useCur) {
            # İmleci başa alıp yerinde çiz: [Console]::Clear() bazı terminallerde içeriği aşağı kaydırıp
            # başlığı geride bıraktığı için her döngüde temizlemek yerine satırları üzerine yazıyoruz.
            if (-not $script:MenuInit) { try { [Console]::Clear() } catch { }; $script:MenuInit = $true }
            $fullW = 80; try { $fullW = [Console]::WindowWidth } catch { }
            $top = 0; try { $top = [Console]::WindowTop } catch { }
            $r = $top
            foreach ($run in $rows) {
                try { [Console]::SetCursorPosition(0, $r) } catch { }
                $col = 0
                foreach ($seg in $run) {
                    try {
                        [Console]::BackgroundColor = [ConsoleColor]::Black
                        [Console]::ForegroundColor = $seg.F
                        if ($seg.B) { [Console]::BackgroundColor = $seg.B }
                    } catch { }
                    Microsoft.PowerShell.Utility\Write-Host $seg.T -NoNewline
                    try { [Console]::BackgroundColor = [ConsoleColor]::Black; [Console]::ForegroundColor = [ConsoleColor]::Gray } catch { }
                    $col += ([string]$seg.T).Length
                }
                if ($col -lt $fullW - 1) { Microsoft.PowerShell.Utility\Write-Host (' ' * ($fullW - 1 - $col)) -NoNewline }
                $r++
            }
            for ($j = $rows.Count; $j -lt $prevRows; $j++) {
                try { [Console]::SetCursorPosition(0, $top + $j); [Console]::BackgroundColor = [ConsoleColor]::Black; [Console]::ForegroundColor = [ConsoleColor]::Gray } catch { }
                Microsoft.PowerShell.Utility\Write-Host (' ' * ($fullW - 1)) -NoNewline
            }
            $prevRows = $rows.Count
            try { [Console]::SetCursorPosition(0, $top) } catch { }
        } else {
            try { [Console]::Clear() } catch { }
            foreach ($run in $rows) {
                if ($run.Count -eq 0) { Microsoft.PowerShell.Utility\Write-Host ''; continue }
                for ($s = 0; $s -lt $run.Count; $s++) {
                    $seg = $run[$s]; $last = ($s -eq $run.Count - 1)
                    if ($seg.B) { Microsoft.PowerShell.Utility\Write-Host $seg.T -ForegroundColor $seg.F -BackgroundColor $seg.B -NoNewline:(-not $last) }
                    else { Microsoft.PowerShell.Utility\Write-Host $seg.T -ForegroundColor $seg.F -NoNewline:(-not $last) }
                }
            }
        }

        $k = [Console]::ReadKey($true)
        $key = [string]$k.Key
        if ($key -in 'UpArrow', 'W') { do { $sel = ($sel - 1 + $items.Count) % $items.Count } while ($items[$sel].Type -eq 'sep'); continue }
        if ($key -in 'DownArrow', 'S', 'Tab') { do { $sel = ($sel + 1) % $items.Count } while ($items[$sel].Type -eq 'sep'); continue }
        if ($key -eq 'Escape') { return $null }
        $pick = $null
        if ($key -in 'D1', 'NumPad1') { $pick = 'Quick' } elseif ($key -in 'D2', 'NumPad2') { $pick = 'Normal' } elseif ($key -in 'D3', 'NumPad3') { $pick = 'Deep' }
        if ($key -in 'Enter', 'Spacebar') {
            $it = $items[$sel]
            if ($it.Type -eq 'opt') { $opts[$it.Key] = -not $opts[$it.Key]; continue }
            if ($it.Type -eq 'exit') { return $null }
            if ($it.Type -eq 'scan') { $pick = $it.Mode }
        }
        if ($pick) { return [pscustomobject]@{ Mode = $pick; Paths = $opts.Paths; Wsl = $opts.Wsl; Export = $opts.Export } }
    }
}

function Get-ShortSource([string]$S) {
    if ($S -like 'hesap dosyas*') { return 'hesap dosyası' }
    if ($S -like 'IAS kay*') { return 'IAS kaydı' }
    if ($S -like 'IAS ile*') { return 'IAS ile geçiş' }
    if ($S -like '*açık oyun*') { return 'açık oyun' }
    return $S
}

function Write-Report {
    if (-not $script:EndTime) { $script:EndTime = [DateTime]::Now }
    $yes = 'Hayır'; if ($script:IsAdmin) { $yes = 'Evet' }
    Out-Line ''
    Out-Line '# AltDetectorX' 'Cyan'
    Out-Line ("  Başlangıç : {0:yyyy-MM-dd HH:mm:ss}" -f $script:StartTime) 'DarkGray'
    Out-Line ("  Bitiş     : {0:yyyy-MM-dd HH:mm:ss}" -f $script:EndTime) 'DarkGray'
    Out-Line ("  Tarama    : {0}" -f $script:ModeLabel[$Mode]) 'DarkGray'
    Out-Line ("  Yönetici  : {0}" -f $yes) 'DarkGray'
    if ($script:WslSummary.Count -gt 0) {
        Out-Line '  WSL/Linux :' 'DarkGray'
        foreach ($w in $script:WslSummary) { Out-Line ("    - " + $w) 'DarkGray' -Indent '      ' }
    } else { Out-Line '  WSL/Linux : bulunamadı' 'DarkGray' }
    Out-Line ''

    Out-Line '# HESAPLAR' 'Cyan'
    $groups = @($script:Accounts | Microsoft.PowerShell.Utility\Group-Object { $_.Name.ToLowerInvariant() })
    if ($groups.Count -eq 0) {
        Out-Line '  Hiç hesap bulunamadı.' 'Yellow'
        Out-Line ''
    } else {
        $ordered = $groups | Microsoft.PowerShell.Core\ForEach-Object {
            $last = Get-MaxDate $_.Group
            $display = ($_.Group | Microsoft.PowerShell.Utility\Sort-Object Date -Descending | Microsoft.PowerShell.Utility\Select-Object -First 1).Name
            [pscustomobject]@{ Name = $display; Last = $last; Items = $_.Group }
        } | Microsoft.PowerShell.Utility\Sort-Object Last -Descending

        Out-Line ("  {0} farklı hesap bulundu" -f $groups.Count) 'White'
        Out-Line ''
        foreach ($g in $ordered) {
            $launchers = @($g.Items | Microsoft.PowerShell.Utility\Group-Object { "$($_.Launcher)`t$($_.Detail)" })
            Out-Line ('  ' + $g.Name) 'Magenta' -NoNewline
            Out-Line ("   son: {0:yyyy-MM-dd}" -f $g.Last) 'DarkGray'

            $sortedL = @($launchers | Microsoft.PowerShell.Utility\Sort-Object { Get-MaxDate $_.Group } -Descending)
            for ($i = 0; $i -lt $sortedL.Count; $i++) {
                $lg = $sortedL[$i]
                $isLast = ($i -eq $sortedL.Count - 1)
                $first = $lg.Group[0]
                $branch = $C_T; $cont = $C_V
                if ($isLast) { $branch = $C_L; $cont = $C_S }
                $pre = '    ' + $cont + '  '

                $srcParts = @($lg.Group | Microsoft.PowerShell.Utility\Group-Object { Get-ShortSource $_.Source } | Microsoft.PowerShell.Core\ForEach-Object {
                        $files = @($_.Group | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty Path -Unique).Count
                        if ($_.Name -eq 'log') { "$files log" } elseif ($files -gt 1) { "$($_.Name) x$files" } else { $_.Name }
                    })
                $min = Get-MinDate $lg.Group
                $max = Get-MaxDate $lg.Group
                $range = $max.ToString('yyyy-MM-dd')
                if ($min.Date -ne $max.Date) { $range = "$($min.ToString('yyyy-MM-dd')) - $($max.ToString('yyyy-MM-dd'))" }

                $color = 'Green'
                if ($srcParts -match 'IAS|alt yöneticisi') { $color = 'Red' }
                elseif ($first.Launcher -match 'Bilinmeyen' -or $first.Detail -match 'Çöp kutusundan|Gölge kopya') { $color = 'Yellow' }

                Out-Line ('    ' + $branch) 'DarkGray' -NoNewline
                Out-Line $first.Launcher $color
                if ($first.Detail) { Out-Line ($pre + $first.Detail) 'Gray' -Indent $pre }
                Out-Line ($pre + ($srcParts -join ', ')) 'DarkGray' -Indent $pre
                Out-Line ($pre + $range) 'DarkGray'

                if ($Paths) {
                    $plist = @($lg.Group | Microsoft.PowerShell.Utility\Sort-Object Date -Descending | Microsoft.PowerShell.Utility\Select-Object -ExpandProperty Path -Unique | Microsoft.PowerShell.Core\Where-Object { $_ })
                    foreach ($pp in ($plist | Microsoft.PowerShell.Utility\Select-Object -First 5)) { Out-Line ($pre + (Resolve-OriginalPath $pp)) 'DarkGray' -Indent ($pre + '  ') }
                    if ($plist.Count -gt 5) { Out-Line ($pre + "... ve $($plist.Count - 5) dosya daha") 'DarkGray' }
                }
            }
            Out-Line ''
        }
    }

    Out-Line '# UYARILAR' 'Cyan'
    $rank = @{ 'Yüksek' = 0; 'Orta' = 1; 'Bilgi' = 2 }
    $seenAlert = Microsoft.PowerShell.Utility\New-Object 'System.Collections.Generic.HashSet[string]'
    $alerts = @($script:Alerts | Microsoft.PowerShell.Core\Where-Object { $seenAlert.Add("$($_.Level)|$($_.Title)|$($_.Detail)") } | Microsoft.PowerShell.Utility\Sort-Object @{ Expression = { $rank[$_.Level] } }, Title)
    if ($alerts.Count -eq 0) {
        Out-Line '  Herhangi bir uyarı yok.' 'Green'
    } else {
        foreach ($a in $alerts) {
            $col = switch ($a.Level) { 'Yüksek' { 'Red' } 'Orta' { 'Yellow' } default { 'DarkGray' } }
            Out-Line ("  [{0}]" -f $a.Level.ToUpper()) $col
            Out-Line ("    " + $a.Title) 'White' -Indent '    '
            if ($a.Detail) {
                $dp = @($a.Detail -split '\s{2,}\(')
                for ($k = 0; $k -lt $dp.Count; $k++) {
                    $t = $dp[$k].Trim()
                    if ($k -gt 0) { $t = '(' + $t }
                    if ($t) { Out-Line ("    " + $t) 'DarkGray' -Indent '      ' }
                }
            }
            Out-Line ''
        }
    }

    $elapsed = $script:EndTime - $script:StartTime
    Out-Line ''
    Out-Line '# ÖZET' 'Cyan'
    Out-Line ("  Taranan klasör : {0:N0}" -f $script:DirCount) 'DarkGray'
    Out-Line ("  Okunan log     : {0:N0}" -f $script:Found.Logs.Count) 'DarkGray'
    Out-Line ("  Hesap dosyası  : {0:N0}" -f $script:Found.Accounts.Count) 'DarkGray'
    Out-Line ("  Erişilemeyen   : {0:N0}" -f $script:Denied) 'DarkGray'
    Out-Line ("  Süre           : {0:N1} sn" -f $elapsed.TotalSeconds) 'DarkGray'
    Out-Line ''
    Out-Line (Get-SigPadded (Get-OutWidth)) 'DarkGray'
    Out-Line ''
}

function Invoke-RuntimeExit {
    $m = -join ((115, 101, 110, 105, 32, 103, 105, 100, 105, 32, 115, 101, 110, 105) | Microsoft.PowerShell.Core\ForEach-Object { [char]$_ })
    try {
        [Console]::BackgroundColor = [ConsoleColor]::Black
        Microsoft.PowerShell.Utility\Write-Host ''
        Microsoft.PowerShell.Utility\Write-Host ('  ' + $m) -ForegroundColor Red
        Microsoft.PowerShell.Utility\Write-Host ''
    } catch { }
    $self = $PSCommandPath
    if (-not $self) { $self = $env:ALTDETECTORX_SELF }
    if ($self -and $self -match '(?i)\.ps1$' -and [IO.File]::Exists($self)) {
        try { [IO.File]::SetAttributes($self, [IO.FileAttributes]::Normal); [IO.File]::Delete($self) } catch { }
    }
    exit 1
}

function Initialize-Runtime {
    $ok = $true
    try {
        $r = @($script:zqR); [array]::Reverse($r)
        $exp = -join ($r | Microsoft.PowerShell.Core\ForEach-Object { [char][int]$_ })
        $c1 = -join (@($script:zq1 + $script:zq2 + $script:zq3 + $script:zq4) | Microsoft.PowerShell.Core\ForEach-Object { [char]([int]$_ -bxor 0x5A) })
        $c2 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($script:zqB))
        $c3 = -join ($script:zqD | Microsoft.PowerShell.Core\ForEach-Object { [char][int]$_ })
        $c4 = ([string](Get-SigPadded 60)).Trim()
        foreach ($c in @($c1, $c2, $c3, (Get-Sig), (Get-SigUncached), $c4)) { if ($c -cne $exp) { $ok = $false } }
        $sha = [Security.Cryptography.SHA256]::Create()
        $h = -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($exp)) | Microsoft.PowerShell.Core\ForEach-Object { $_.ToString('x2') })
        $sha.Dispose()
        if ($h -ne $script:zqH -or $exp.Length -ne 17) { $ok = $false }
    } catch { $ok = $false }
    if (-not $ok) { Invoke-RuntimeExit }
}

function Test-IsAdmin {
    try {
        return (Microsoft.PowerShell.Utility\New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Invoke-Elevation {
    $text = $null
    try {
        $a = ${function:Get-Sig}.Ast
        while ($null -ne $a.Parent) { $a = $a.Parent }
        $text = $a.Extent.Text
    } catch { }
    if (-not $text -or $text.IndexOf('function Invoke-Elevation') -lt 0) { return $false }

    $bytes = (Microsoft.PowerShell.Utility\New-Object Text.UTF8Encoding($false)).GetBytes($text)
    $sha = [Security.Cryptography.SHA256]::Create()
    $hash = -join ($sha.ComputeHash($bytes) | Microsoft.PowerShell.Core\ForEach-Object { $_.ToString('x2') })
    $tmp = Microsoft.PowerShell.Management\Join-Path ([IO.Path]::GetTempPath()) ("AltDetectorX_{0}.ps1" -f [guid]::NewGuid().ToString('N'))
    try { [IO.File]::WriteAllBytes($tmp, $bytes) } catch { return $false }

    $q = [string][char]39
    $loader = @(
        ('$p = ' + $q + ($tmp -replace $q, ($q + $q)) + $q)
        ('$h = ' + $q + $hash + $q)
        '$b = $null'
        'try { $b = [IO.File]::ReadAllBytes($p) } catch { }'
        'try { [IO.File]::Delete($p) } catch { }'
        ('if ($null -eq $b) { Write-Host ' + $q + 'AltDetectorX: başlatma dosyası okunamadı.' + $q + ' -ForegroundColor Red; return }')
        ('$c = -join ([Security.Cryptography.SHA256]::Create().ComputeHash($b) | ForEach-Object { $_.ToString(' + $q + 'x2' + $q + ') })')
        ('if ($c -ne $h) { Write-Host ' + $q + 'AltDetectorX: dosya doğrulaması başarısız, çalıştırılmadı.' + $q + ' -ForegroundColor Red; return }')
        ('$Host.UI.RawUI.WindowTitle = ' + $q + 'AltDetectorX (Yönetici)' + $q)
        ('& ([scriptblock]::Create([Text.Encoding]::UTF8.GetString($b))) ' + ($script:ForwardArgs -join ' '))
    ) -join "`n"
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($loader))

    $exe = $null
    try { $exe = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName } catch { }
    if (-not $exe -or [IO.Path]::GetFileName($exe) -notmatch '(?i)^(powershell|pwsh)\.exe$') {
        $exe = Microsoft.PowerShell.Management\Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    }
    try {
        Microsoft.PowerShell.Management\Start-Process -FilePath $exe -Verb RunAs -ArgumentList "-NoProfile -NoExit -ExecutionPolicy Bypass -EncodedCommand $enc" -ErrorAction Stop | Microsoft.PowerShell.Core\Out-Null
        return $true
    } catch {
        try { [IO.File]::Delete($tmp) } catch { }
        return $false
    }
}

$script:OrigPriority = $null
$script:MenuShown = $false
try {
    Initialize-Runtime
    try { $Host.UI.RawUI.WindowTitle = 'AltDetectorX' } catch { }
    $script:IsAdmin = Test-IsAdmin
    if (-not $script:IsAdmin -and -not $NoElevate) {
        Microsoft.PowerShell.Utility\Write-Host ''
        Microsoft.PowerShell.Utility\Write-Host '  AltDetectorX yönetici izni istiyor (tam tarama için gerekli)...' -ForegroundColor Cyan
        if (Invoke-Elevation) {
            Microsoft.PowerShell.Utility\Write-Host '  Yönetici penceresinde açıldı. Bu pencereyi kapatabilirsiniz.' -ForegroundColor Green
            return
        }
        Microsoft.PowerShell.Utility\Write-Host '  Yönetici izni verilmedi. Sınırlı modda devam ediliyor...' -ForegroundColor Yellow
        Microsoft.PowerShell.Utility\Start-Sleep -Seconds 2
    }
    if ($script:Tui) {
        try { [Console]::Clear() } catch { }
        Microsoft.PowerShell.Utility\Write-Host ''
        Microsoft.PowerShell.Utility\Write-Host '  AltDetectorX: sistem bilgileri okunuyor...' -ForegroundColor Cyan
    }
    $script:Sys = Get-SystemInfo
    $script:Settings = Get-OptimalSettings $script:Sys
    [void](Get-WslCache)

    if ($script:Tui -and -not $NoMenu -and -not $script:ParamGiven) {
        $script:MenuShown = $true
        $choice = Show-Menu
        if ($null -eq $choice) {
            try { [Console]::Clear(); [Console]::CursorVisible = $true } catch { }
            Microsoft.PowerShell.Utility\Write-Host 'AltDetectorX kapatıldı.' -ForegroundColor DarkGray
            return
        }
        $Mode = $choice.Mode
        $Paths = [switch]$choice.Paths
        $NoWsl = [switch](-not $choice.Wsl)
        if ($choice.Export -and -not $Export) {
            $Export = Microsoft.PowerShell.Management\Join-Path ([Environment]::GetFolderPath('Desktop')) ("AltDetectorX_{0:yyyyMMdd_HHmm}.txt" -f [DateTime]::Now)
        }
    } elseif (-not $script:Tui) {
        Microsoft.PowerShell.Utility\Write-Host ''
        Microsoft.PowerShell.Utility\Write-Host ("  AltDetectorX: {0} başlıyor." -f $script:ModeLabel[$Mode]) -ForegroundColor Cyan
    }

    try {
        $me = [Diagnostics.Process]::GetCurrentProcess()
        $script:OrigPriority = $me.PriorityClass
        $me.PriorityClass = [Diagnostics.ProcessPriorityClass]::BelowNormal
    } catch { }

    $script:StartTime = [DateTime]::Now
    Start-Ui

    Set-Phase 1 'Ortam kontrolü'
    Test-Environment

    Set-Phase 2 'Silinmiş dosyalar'
    Invoke-DeletedScan

    Set-Phase 3 'Klasörler taranıyor'
    Invoke-Scan

    Set-Phase 4 'WSL / Linux'
    Invoke-WslScan

    Set-Phase 5 'Log dosyaları okunuyor'
    Invoke-LogParse

    Set-Phase 6 'Hesap dosyaları'
    Invoke-AccountFiles

    Set-Phase 7 'Son kontroller'
    Invoke-Ias
    Invoke-AltManagers
    Test-LogIntegrity
    Invoke-ProcessScan
    Test-LinuxInstall
    Test-ShadowDeleted
    Show-Progress -Status 'Tamamlandı' -Percent 100 -Force

    $script:EndTime = [DateTime]::Now
    Stop-Ui
    Write-Report
    if (-not $script:Report.ToString().Contains((Get-Sig))) { Invoke-RuntimeExit }

    if ($Export) {
        try {
            $Export = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Export)
            [IO.File]::WriteAllText($Export, $script:Report.ToString(), (Microsoft.PowerShell.Utility\New-Object Text.UTF8Encoding($true)))
            Out-Line "Rapor kaydedildi: $Export" 'Green'
        } catch { Out-Line "Rapor kaydedilemedi: $($_.Exception.Message)" 'Red' }
    }
    if ($script:MenuShown) {
        Microsoft.PowerShell.Utility\Write-Host ($script:MarginText + '  Kapatmak için bir tuşa basın...') -ForegroundColor DarkGray
        Microsoft.PowerShell.Utility\Write-Host ''
        try { [void][Console]::ReadKey($true) } catch { }
    }
} finally {
    Microsoft.PowerShell.Utility\Write-Progress -Id 1 -Activity 'Bitti' -Completed
    # Konsolun özgün renklerini geri ver (kullanıcının teması bozulmasın).
    try {
        if ($null -ne $script:OrigBg) { [Console]::BackgroundColor = $script:OrigBg }
        if ($null -ne $script:OrigFg) { [Console]::ForegroundColor = $script:OrigFg }
        if ($null -eq $script:OrigBg -and $null -eq $script:OrigFg) { [Console]::ResetColor() }
        [Console]::CursorVisible = $true
    } catch { }
    if ($script:OrigPriority) { try { [Diagnostics.Process]::GetCurrentProcess().PriorityClass = $script:OrigPriority } catch { } }
    if ($script:OrigEncoding) { try { [Console]::OutputEncoding = $script:OrigEncoding } catch { } }
    $ErrorActionPreference = $script:OrigEAP
}
