# =====================================================================
#  DIAGNOSTIC PC COMPLET - v2.1
#  Remplace plusieurs petits logiciels (infos système, SMART, benchmark,
#  test RAM, test de charge...) et dit ce que le PC est capable de faire :
#  bureautique, jeu 1080p / 1440p / 4K, streaming, montage vidéo, 3D,
#  IA locale. Pour chaque usage : une note /100, un verdict, et ce quʼil
#  faut changer pour lʼaméliorer (avec la note estimée après amélioration).
#  v2.1 : vrai test de la carte graphique (puissance, erreurs de calcul,
#  chauffe), vraies températures (LibreHardwareMonitor facultatif,
#  nvidia-smi), test de vraie capacité des clés USB / disques externes.
#
#  Lancer via LANCER-DIAGNOSTIC.bat (droits administrateur).
#  Ne modifie rien sur le PC. Seul un fichier temporaire de 2 Go est écrit
#  puis supprimé pour mesurer la vitesse du disque.
# =====================================================================
$ErrorActionPreference = 'Continue'
$VERSION = '2.2'
try { $Host.UI.RawUI.WindowTitle = 'Diagnostic PC' } catch {}
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$reportDir = Join-Path $root 'Rapports'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm'
$reportPath = Join-Path $reportDir ("Diagnostic_{0}_{1}.html" -f $env:COMPUTERNAME, $stamp)
$TOTAL = 15

# =====================================================================
#  BASE DE DONNÉES (à mettre à jour quand de nouveaux modèles sortent)
# =====================================================================

# --- Cartes graphiques : @(motif, indice de performance, mémoire vidéo en Go)
#     Indice 100 = RTX 5090. Valeurs moyennes en jeu 1440p (ordre de grandeur).
#     Les motifs les plus précis doivent être AVANT les plus généraux.
$GPU_DB = @(
    # NVIDIA RTX 50
    @('RTX 5090', 100, 32), @('RTX 5080', 58, 16), @('RTX 5070 TI', 51, 16), @('RTX 5070', 41, 12),
    @('RTX 5060 TI', 30, 16), @('RTX 5060', 25, 8), @('RTX 5050', 19, 8),
    # NVIDIA RTX 40
    @('RTX 4090', 75, 24), @('RTX 4080 SUPER', 56, 16), @('RTX 4080', 55, 16),
    @('RTX 4070 TI SUPER', 47, 16), @('RTX 4070 TI', 44, 12), @('RTX 4070 SUPER', 41, 12), @('RTX 4070', 35, 12),
    @('RTX 4060 TI', 26, 8), @('RTX 4060', 21, 8), @('RTX 4050', 15, 6),
    # NVIDIA RTX 30
    @('RTX 3090 TI', 42, 24), @('RTX 3090', 38, 24), @('RTX 3080 TI', 37, 12), @('RTX 3080', 34, 10),
    @('RTX 3070 TI', 27, 8), @('RTX 3070', 26, 8), @('RTX 3060 TI', 23, 8), @('RTX 3060', 17, 12), @('RTX 3050', 11, 8),
    # NVIDIA RTX 20 / GTX 16 / GTX 10
    @('RTX 2080 TI', 25, 11), @('RTX 2080 SUPER', 21, 8), @('RTX 2080', 20, 8), @('RTX 2070 SUPER', 19, 8),
    @('RTX 2070', 17, 8), @('RTX 2060 SUPER', 16, 8), @('RTX 2060', 14, 6),
    @('GTX 1660 SUPER', 11, 6), @('GTX 1660 TI', 11, 6), @('GTX 1660', 10, 6), @('GTX 1650', 7, 4), @('GTX 1630', 4, 4),
    @('GTX 1080 TI', 17, 11), @('GTX 1080', 13, 8), @('GTX 1070 TI', 12, 8), @('GTX 1070', 11, 8),
    @('GTX 1060', 8, 6), @('GTX 1050 TI', 5, 4), @('GTX 1050', 4, 2), @('GTX 9[78]0', 7, 4), @('GTX 9[56]0', 4, 2),
    @('MX\s?\d{3}', 3, 2),
    # NVIDIA pro
    @('RTX 6000 ADA', 65, 48), @('RTX A6000', 45, 48), @('RTX A5000', 35, 24), @('RTX A4000', 23, 16), @('QUADRO', 10, 4),
    # AMD RX 9000 / 7000
    @('RX 9070 XT', 50, 16), @('RX 9070', 45, 16), @('RX 9060 XT', 30, 16), @('RX 9060', 24, 8),
    @('RX 7900 XTX', 55, 24), @('RX 7900 XT', 48, 20), @('RX 7900 GRE', 40, 16), @('RX 7800 XT', 37, 16),
    @('RX 7700 XT', 31, 12), @('RX 7600 XT', 21, 16), @('RX 7600', 20, 8),
    # AMD RX 6000 / 5000 / anciennes
    @('RX 6950 XT', 37, 16), @('RX 6900 XT', 35, 16), @('RX 6800 XT', 33, 16), @('RX 6800', 29, 16),
    @('RX 6750 XT', 25, 12), @('RX 6700 XT', 24, 12), @('RX 6700', 22, 10), @('RX 6650 XT', 19, 8),
    @('RX 6600 XT', 18, 8), @('RX 6600', 16, 8), @('RX 6500 XT', 7, 4), @('RX 6400', 5, 4),
    @('RX 5700 XT', 16, 8), @('RX 5700', 14, 8), @('RX 5600 XT', 12, 6), @('RX 5500 XT', 8, 8),
    @('RX VEGA 64', 12, 8), @('RX VEGA 56', 11, 8), @('RX 590', 9, 8), @('RX 580', 8, 8), @('RX 570', 7, 4), @('RX 5[56]0', 4, 4),
    # Intel Arc (cartes dédiées)
    @('ARC B580', 22, 12), @('ARC B570', 19, 10), @('ARC A770', 19, 16), @('ARC A750', 18, 8), @('ARC A580', 15, 8), @('ARC A380', 6, 6)
)
# --- Puces graphiques intégrées au processeur (mémoire vidéo partagée avec la RAM)
$IGPU_DB = @(
    @('RADEON 8060S', 20), @('RADEON 8050S', 16), @('RADEON 890M', 8), @('RADEON 880M', 7), @('RADEON 780M', 6),
    @('RADEON 760M', 5), @('RADEON 680M', 5), @('RADEON 740M', 3.5), @('RADEON 660M', 3.5),
    @('ARC 140V', 7), @('ARC 130V', 6), @('ARC 140T', 6), @('ARC 130T', 5), @('ARC GRAPHICS', 5),
    @('IRIS XE', 3), @('IRIS', 2), @('RADEON VEGA', 2.5), @('VEGA \d+', 2.5), @('RADEON GRAPHICS', 2),
    @('UHD GRAPHICS', 1.5), @('HD GRAPHICS', 1)
)

# --- Cartes graphiques conseillées, de la moins chère à la plus chère
#     G = indice, V = mémoire vidéo, Nv = NVIDIA (indispensable pour la plupart des outils dʼIA), W = alimentation conseillée
$GPU_SHOP = @(
    [pscustomobject]@{ N = 'Intel Arc B580 12 Go';                       G = 22;  V = 12; Nv = $false; W = 550 }
    [pscustomobject]@{ N = 'NVIDIA GeForce RTX 5060 8 Go';               G = 25;  V = 8;  Nv = $true;  W = 550 }
    [pscustomobject]@{ N = 'AMD Radeon RX 9060 XT 16 Go';                G = 30;  V = 16; Nv = $false; W = 550 }
    [pscustomobject]@{ N = 'NVIDIA GeForce RTX 5060 Ti 16 Go';           G = 30;  V = 16; Nv = $true;  W = 600 }
    [pscustomobject]@{ N = 'NVIDIA GeForce RTX 5070 12 Go';              G = 41;  V = 12; Nv = $true;  W = 650 }
    [pscustomobject]@{ N = 'AMD Radeon RX 9070 16 Go';                   G = 45;  V = 16; Nv = $false; W = 650 }
    [pscustomobject]@{ N = 'AMD Radeon RX 9070 XT 16 Go';                G = 50;  V = 16; Nv = $false; W = 750 }
    [pscustomobject]@{ N = 'NVIDIA GeForce RTX 5070 Ti 16 Go';           G = 51;  V = 16; Nv = $true;  W = 750 }
    [pscustomobject]@{ N = 'NVIDIA GeForce RTX 3090 24 Go (occasion)';   G = 38;  V = 24; Nv = $true;  W = 750 }
    [pscustomobject]@{ N = 'NVIDIA GeForce RTX 5080 16 Go';              G = 58;  V = 16; Nv = $true;  W = 850 }
    [pscustomobject]@{ N = 'NVIDIA GeForce RTX 4090 24 Go (occasion)';   G = 75;  V = 24; Nv = $true;  W = 850 }
    [pscustomobject]@{ N = 'NVIDIA GeForce RTX 5090 32 Go';              G = 100; V = 32; Nv = $true;  W = 1000 }
)

# --- Processeurs compatibles par support (socket), du moins cher au plus cher
#     S = indice 1 cœur, M = indice multi-cœurs (100 = Ryzen 9 9950X / Core Ultra 9 285K)
$CPU_SHOP = @{
    'AM4'     = @( [pscustomobject]@{ N = 'AMD Ryzen 5 5600';      S = 70; M = 29 },
                   [pscustomobject]@{ N = 'AMD Ryzen 7 5700X3D';   S = 66; M = 36 },
                   [pscustomobject]@{ N = 'AMD Ryzen 7 5800X';     S = 74; M = 41 },
                   [pscustomobject]@{ N = 'AMD Ryzen 9 5900X';     S = 76; M = 63 },
                   [pscustomobject]@{ N = 'AMD Ryzen 9 5950X';     S = 76; M = 80 } )
    'AM5'     = @( [pscustomobject]@{ N = 'AMD Ryzen 5 9600X';     S = 95; M = 41 },
                   [pscustomobject]@{ N = 'AMD Ryzen 7 9800X3D';   S = 93; M = 52 },
                   [pscustomobject]@{ N = 'AMD Ryzen 9 9900X';     S = 98; M = 81 },
                   [pscustomobject]@{ N = 'AMD Ryzen 9 9950X';     S = 100; M = 100 } )
    'LGA1700' = @( [pscustomobject]@{ N = 'Intel Core i5-14400F';  S = 82; M = 43 },
                   [pscustomobject]@{ N = 'Intel Core i5-14600K';  S = 94; M = 60 },
                   [pscustomobject]@{ N = 'Intel Core i7-14700K';  S = 96; M = 83 },
                   [pscustomobject]@{ N = 'Intel Core i9-14900K';  S = 99; M = 97 } )
    'LGA1851' = @( [pscustomobject]@{ N = 'Intel Core Ultra 5 245K'; S = 94; M = 58 },
                   [pscustomobject]@{ N = 'Intel Core Ultra 7 265K'; S = 97; M = 82 },
                   [pscustomobject]@{ N = 'Intel Core Ultra 9 285K'; S = 100; M = 98 } )
    'LGA1200' = @( [pscustomobject]@{ N = 'Intel Core i7-11700K';  S = 70; M = 37 },
                   [pscustomobject]@{ N = 'Intel Core i9-11900K';  S = 72; M = 39 } )
}
$CPU_SOCKET_NOTE = @{
    'AM4'     = 'Mettre à jour le BIOS de la carte mère AVANT de changer de processeur.'
    'AM5'     = 'Mettre à jour le BIOS de la carte mère avant le changement.'
    'LGA1700' = 'Mettre à jour le BIOS AVANT (correctif de stabilité Intel pour les 13e/14e génération).'
    'LGA1851' = 'Mettre à jour le BIOS avant le changement.'
    'LGA1200' = 'Plateforme ancienne : vérifier la compatibilité de la carte mère (les cartes H410/B460 nʼacceptent pas la 11e génération).'
}
# Plateforme neuve conseillée si le support actuel est trop ancien
$PLATFORM_NEW = @(
    [pscustomobject]@{ N = 'AMD Ryzen 7 9800X3D + carte mère AM5 (B650/B850) + 32 Go DDR5';  S = 93;  M = 52;  R = 32 }
    [pscustomobject]@{ N = 'AMD Ryzen 9 9900X + carte mère AM5 (B650/B850) + 32 Go DDR5';    S = 98;  M = 81;  R = 32 }
    [pscustomobject]@{ N = 'AMD Ryzen 9 9950X + carte mère AM5 (X870) + 64 Go DDR5';         S = 100; M = 100; R = 64 }
)

# --- Usages évalués
#     T = valeur cible (au-delà, le composant est "parfait" pour cet usage), W = poids, C = composant critique
#     Clés : S = processeur 1 cœur, M = processeur multi-cœurs, G = carte graphique (indices /100),
#            V = mémoire vidéo (Go), R = RAM (Go), D = stockage (indice /100)
$USAGES = @(
    [pscustomobject]@{ Id = 1; Nom = 'Bureautique, internet, vidéos';           C = $null; T = @{ S = 40; R = 8;  D = 45; G = 1.5 };            W = @{ S = 3; R = 2;   D = 3;   G = 1 } }
    [pscustomobject]@{ Id = 2; Nom = 'Jeu en 1080p (Full HD)';                  C = 'G';   T = @{ G = 24; S = 70; R = 16; V = 8;  D = 50 };     W = @{ G = 6; S = 2;   R = 1;   V = 1;   D = 0.5 } }
    [pscustomobject]@{ Id = 3; Nom = 'Jeu en 1440p (QHD)';                      C = 'G';   T = @{ G = 42; S = 80; R = 16; V = 12; D = 60 };     W = @{ G = 6; S = 2;   R = 1;   V = 1;   D = 0.5 } }
    [pscustomobject]@{ Id = 4; Nom = 'Jeu en 4K / réalité virtuelle';           C = 'G';   T = @{ G = 70; S = 85; R = 32; V = 16; D = 60 };     W = @{ G = 7; S = 2;   R = 1;   V = 1.5; D = 0.5 } }
    [pscustomobject]@{ Id = 5; Nom = 'Streaming / création de contenu';         C = 'G';   T = @{ G = 30; M = 40; S = 75; R = 32; D = 60 };     W = @{ G = 3; M = 3;   S = 1;   R = 1.5; D = 1 } }
    [pscustomobject]@{ Id = 6; Nom = 'Montage vidéo 1080p';                     C = 'M';   T = @{ M = 28; S = 60; R = 16; G = 12; D = 60 };     W = @{ M = 3; S = 1;   R = 2;   G = 1.5; D = 1.5 } }
    [pscustomobject]@{ Id = 7; Nom = 'Montage vidéo 4K / 360';                  C = 'M';   T = @{ M = 55; S = 75; R = 32; G = 30; V = 8; D = 80 }; W = @{ M = 3; S = 1; R = 2.5; G = 2; V = 1; D = 1.5 } }
    [pscustomobject]@{ Id = 8; Nom = '3D : Unreal Engine 5, Blender';           C = 'G';   T = @{ G = 45; V = 12; M = 50; R = 32; D = 70 };     W = @{ G = 4; V = 2;   M = 2;   R = 2;   D = 1 } }
    [pscustomobject]@{ Id = 9; Nom = 'IA en local (chatbot, génération dʼimages)'; C = 'V'; T = @{ V = 16; G = 28; R = 32; D = 60 };           W = @{ V = 5; G = 2;   R = 2;   D = 1 } }
)

# =====================================================================
#  OUTILS
# =====================================================================
$sections = New-Object System.Collections.Generic.List[string]
$alerts   = New-Object System.Collections.Generic.List[object]
$health   = 100      # score de santé, on retire des points à chaque problème

function Add-Alert([string]$level, [string]$text, [int]$malus = 0) {
    # level : ROUGE / ORANGE / OK / INFO ; malus : points retirés au score de santé
    $alerts.Add([pscustomobject]@{ Level = $level; Text = $text })
    $script:health -= $malus
    $color = @{ ROUGE = 'Red'; ORANGE = 'Yellow'; OK = 'Green'; INFO = 'Gray' }[$level]
    Write-Host ("   -> [{0}] {1}" -f $level, $text) -ForegroundColor $color
}
function Enc($s) { [System.Net.WebUtility]::HtmlEncode([string]$s) }
function Add-Table([string]$title, $rows) {
    $h = "<h3>$(Enc $title)</h3><table>"
    foreach ($k in $rows.Keys) { $h += "<tr><th>$(Enc $k)</th><td>$(Enc $rows[$k])</td></tr>" }
    $sections.Add($h + '</table>')
}
function Add-Grid([string]$title, $objects) {
    $list = @($objects)
    if ($list.Count -eq 0) { $sections.Add("<h3>$(Enc $title)</h3><p class='small'>Aucune donnée.</p>"); return }
    $props = $list[0].PSObject.Properties.Name
    $h = "<h3>$(Enc $title)</h3><div class='scroll'><table class='grid'><tr>"
    foreach ($p in $props) { $h += "<th>$(Enc $p)</th>" }
    $h += '</tr>'
    foreach ($o in $list) {
        $h += '<tr>'
        foreach ($p in $props) { $h += "<td>$(Enc $o.$p)</td>" }
        $h += '</tr>'
    }
    $sections.Add($h + '</table></div>')
}
function Step([int]$n, [string]$t) { Write-Host ''; Write-Host ("[{0}/{1}] {2}" -f $n, $TOTAL, $t) -ForegroundColor Cyan }
function GB($bytes) { [math]::Round([double]$bytes / 1GB, 1) }
function Clamp([double]$v, [double]$lo = 0, [double]$hi = 100) { [math]::Max($lo, [math]::Min($hi, $v)) }
function Interp([double]$x, $pts) {
    if ($x -le $pts[0][0]) { return [double]$pts[0][1] }
    for ($i = 1; $i -lt $pts.Count; $i++) {
        if ($x -le $pts[$i][0]) {
            $a = $pts[$i - 1]; $b = $pts[$i]
            return [double]$a[1] + ($x - $a[0]) * ($b[1] - $a[1]) / ($b[0] - $a[0])
        }
    }
    return [double]$pts[$pts.Count - 1][1]
}
function Bar($v) {
    if ($null -eq $v) { return '<span class="small">non mesuré</span>' }
    $pct = [int](Clamp $v)
    $col = '#2e7d32'; if ($pct -lt 70) { $col = '#ef8c00' }; if ($pct -lt 50) { $col = '#c62828' }
    "<div class='bar'><div style='width:$pct%;background:$col'></div></div><b>$pct</b>/100"
}
function Get-Level([double]$s) {
    if ($s -ge 85) { return [pscustomobject]@{ Txt = 'Excellent';   Cls = 'g'; Ic = '&#9989;' } }
    if ($s -ge 70) { return [pscustomobject]@{ Txt = 'Très bien';   Cls = 'g'; Ic = '&#9989;' } }
    if ($s -ge 50) { return [pscustomobject]@{ Txt = 'Correct';     Cls = 'o'; Ic = '&#9888;&#65039;' } }
    if ($s -ge 30) { return [pscustomobject]@{ Txt = 'Faible';      Cls = 'r'; Ic = '&#10060;' } }
    return [pscustomobject]@{ Txt = 'Insuffisant'; Cls = 'r'; Ic = '&#10060;' }
}

# ---------------------------------------------------------------------
#  Capteurs : LibreHardwareMonitor (facultatif, vraies températures)
#  et nvidia-smi (installé avec le pilote NVIDIA)
# ---------------------------------------------------------------------
$lhm = $null; $lhmCpuOk = $false
function Init-Lhm {
    $dir = Join-Path $root 'LibreHardwareMonitor'
    $dll = Get-ChildItem $dir -Recurse -Filter 'LibreHardwareMonitorLib.dll' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $dll) { Write-Host '   (LibreHardwareMonitor absent : températures approximatives)' -ForegroundColor DarkGray; return }
    try {
        Get-ChildItem $dll.DirectoryName -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
        Add-Type -Path $dll.FullName -ErrorAction Stop
        $cp = New-Object LibreHardwareMonitor.Hardware.Computer
        foreach ($p in 'IsCpuEnabled', 'IsGpuEnabled', 'IsMotherboardEnabled') { try { $cp.$p = $true } catch {} }
        $cp.Open()
        $script:lhm = $cp
        $t0 = Read-Lhm
        $script:lhmCpuOk = ($null -ne $t0.Cpu)
        Write-Host "   LibreHardwareMonitor chargé (temp. processeur : $(if ($t0.Cpu) { "$([int]$t0.Cpu) C" } else { 'non lisible' }), carte graphique : $(if ($t0.Gpu) { "$([int]$t0.Gpu) C" } else { 'non lisible' }))." -ForegroundColor DarkGray
    } catch { Write-Host "   LibreHardwareMonitor nʼa pas pu démarrer : $($_.Exception.Message)" -ForegroundColor DarkGray }
}
function Read-Lhm {
    $o = [pscustomobject]@{ Cpu = $null; CpuPower = $null; Gpu = $null; GpuHot = $null }
    if (-not $script:lhm) { return $o }
    try {
        foreach ($hw in $script:lhm.Hardware) {
            $hw.Update()
            foreach ($sub in $hw.SubHardware) { $sub.Update() }
            $ht = "$($hw.HardwareType)"
            foreach ($h in @($hw) + @($hw.SubHardware)) {
                foreach ($s in $h.Sensors) {
                    if ($null -eq $s.Value) { continue }
                    $st = "$($s.SensorType)"; $nm = "$($s.Name)"; $v = [double]$s.Value
                    if ($st -eq 'Temperature' -and ($v -le 0 -or $v -gt 125)) { continue }
                    if ($ht -eq 'Cpu' -and $st -eq 'Temperature' -and $nm -match 'Package|Tctl|Tdie|Core Max|CPU') { if ($null -eq $o.Cpu -or $v -gt $o.Cpu) { $o.Cpu = $v } }
                    elseif ($ht -eq 'Cpu' -and $st -eq 'Power' -and $nm -match 'Package') { $o.CpuPower = $v }
                    elseif ($ht -match '^Gpu' -and $st -eq 'Temperature') {
                        if ($nm -match 'Hot ?Spot') { $o.GpuHot = $v }
                        elseif ($nm -match 'Core|GPU') { if ($null -eq $o.Gpu -or $v -gt $o.Gpu) { $o.Gpu = $v } }
                    }
                }
            }
        }
    } catch {}
    $o
}
$smi = @("$env:windir\System32\nvidia-smi.exe", "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
function ToD($s) { $d = 0.0; if ([double]::TryParse(("" + $s).Trim(), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { return $d }; return $null }
function Get-NvSample {
    if (-not $smi) { return $null }
    try {
        $l = & $smi --query-gpu=temperature.gpu,utilization.gpu,clocks.gr,power.draw --format=csv,noheader,nounits 2>$null | Select-Object -First 1
        $p = ("" + $l) -split ','
        if ($p.Count -lt 3) { return $null }
        return [pscustomobject]@{ Temp = (ToD $p[0]); Util = (ToD $p[1]); Clock = (ToD $p[2]); Power = $(if ($p.Count -gt 3) { ToD $p[3] } else { $null }) }
    } catch { return $null }
}

# ---------------------------------------------------------------------
#  Identification du processeur : indice 1 cœur (100 = le plus rapide du marché)
# ---------------------------------------------------------------------
function Get-CpuInfo([string]$name, [bool]$laptop) {
    $n = ($name.ToUpper() -replace '\(TM\)|\(R\)|™|®', ' ' -replace '@.*$', '' -replace '\bCPU\b|PROCESSOR|\d+-CORE', ' ' -replace '\s+', ' ').Trim()
    $r = @{ ST = 35.0; Socket = ''; Known = $true; Mobile = $laptop }
    if ($n -match 'ULTRA ([3579]) (\d)(\d\d)([A-Z]*)') {
        # Intel Core Ultra (série 1 = portable Meteor Lake, série 2 = Arrow/Lunar Lake)
        $tier = [int]$Matches[1]; $series = [int]$Matches[2]; $suf = $Matches[4]
        if ($series -eq 1) { $st = 76; $r.Mobile = $true }
        elseif ($suf -eq 'HX') { $st = 92; $r.Mobile = $true }
        elseif ($suf -match '^(K|KF|F|T)?$' -and -not $laptop) { $st = 98; $r.Socket = 'LGA1851' }
        else { $st = 86; $r.Mobile = $true }
        $r.ST = $st * @{ 3 = 0.9; 5 = 0.95; 7 = 1.0; 9 = 1.02 }[$tier]
    }
    elseif ($n -match '\bI([3579])-(\d{4,5})([A-Z]*\d?)') {
        # Intel Core i3/i5/i7/i9
        $tier = [int]$Matches[1]; $num = $Matches[2]; $suf = $Matches[3]
        if ($num.Length -eq 5) { $gen = [int]$num.Substring(0, 2) }
        elseif ($num.StartsWith('1')) { $gen = [int]$num.Substring(0, 2); $r.Mobile = $true }   # ex. i7-1165G7, i5-1235U
        else { $gen = [int]$num.Substring(0, 1) }
        $genST = @{ 2 = 32; 3 = 35; 4 = 41; 5 = 42; 6 = 47; 7 = 51; 8 = 53; 9 = 56; 10 = 59; 11 = 69; 12 = 86; 13 = 94; 14 = 96 }
        $st = 30; if ($genST.ContainsKey($gen)) { $st = $genST[$gen] } else { $r.Known = $false }
        if ($suf -match '^(U|Y|G\d)') { $st *= 0.78; $r.Mobile = $true }
        elseif ($suf -eq 'HX') { $st *= 0.97; $r.Mobile = $true }
        elseif ($suf -match '^(H|HK|HQ|HS|P|M)') { $st *= 0.9; $r.Mobile = $true }
        elseif ($suf -match '^T') { $st *= 0.88 }
        elseif ($suf -match '^K') { $st *= 1.03 }
        $r.ST = $st * @{ 3 = 0.9; 5 = 0.95; 7 = 1.0; 9 = 1.03 }[$tier]
        if (-not $r.Mobile) {
            if ($gen -le 3) { $r.Socket = 'LGA1155' } elseif ($gen -le 5) { $r.Socket = 'LGA1150' } elseif ($gen -le 9) { $r.Socket = 'LGA1151' }
            elseif ($gen -le 11) { $r.Socket = 'LGA1200' } elseif ($gen -le 14) { $r.Socket = 'LGA1700' }
        }
    }
    elseif ($n -match '\bCORE ([3579]) (\d)(\d\d)([A-Z]*)') {
        # Intel Core 5 / Core 7 (série 1 et 2 sans "Ultra")
        $r.ST = 82 * @{ 3 = 0.9; 5 = 0.95; 7 = 1.0; 9 = 1.02 }[[int]$Matches[1]]; $r.Mobile = $true
    }
    elseif ($n -match 'RYZEN AI MAX') { $r.ST = 90; $r.Mobile = $true }
    elseif ($n -match 'RYZEN AI ([3579])') { $r.ST = 89 * @{ 3 = 0.9; 5 = 0.96; 7 = 1.0; 9 = 1.02 }[[int]$Matches[1]]; $r.Mobile = $true }
    elseif ($n -match 'THREADRIPPER( PRO)? (\d)') {
        $r.ST = @{ 1 = 47; 2 = 51; 3 = 58; 5 = 72; 7 = 88; 9 = 97 }[[int]$Matches[2]]; if (-not $r.ST) { $r.ST = 60 }
    }
    elseif ($n -match 'RYZEN ([3579]) (PRO )?(\d)(\d)(\d)(\d)([A-Z0-9]*)') {
        $tier = [int]$Matches[1]; $s = [int]$Matches[3]; $d3 = [int]$Matches[5]; $suf = $Matches[7]
        $mob = $laptop -or ($suf -match '^(U|H|HS|HX|HN)')
        if (-not $mob) {
            $st = @{ 1 = 47; 2 = 51; 3 = 58; 4 = 57; 5 = 70; 7 = 88; 8 = 85; 9 = 98 }[$s]; if (-not $st) { $st = 50; $r.Known = $false }
            if ($s -le 5) { $r.Socket = 'AM4' } else { $r.Socket = 'AM5' }
        } else {
            $r.Mobile = $true
            switch ($s) {
                2 { $st = 45 } 3 { $st = 45 } 4 { $st = 55 } 5 { $st = 64 } 6 { $st = 70 }
                7 { $st = @{ 2 = 52; 3 = 66; 4 = 82; 5 = 86 }[$d3]; if (-not $st) { $st = 66 } }
                8 { $st = 82 } 9 { $st = 95 }
                default { $st = 50; $r.Known = $false }
            }
            if ($suf -match '^U') { $st *= 0.9 }
        }
        if ($suf -match 'X3D') { $st *= 0.93 }
        $r.ST = $st * @{ 3 = 0.9; 5 = 0.96; 7 = 1.0; 9 = 1.02 }[$tier]
    }
    elseif ($n -match '\bN\d{2,3}\b') { $r.ST = 40 }                       # Intel N100 / N200...
    elseif ($n -match 'PENTIUM|CELERON|ATOM|ATHLON|\bA\d{1,2}-|FX-') { $r.ST = 25 }
    elseif ($n -match 'XEON|EPYC') { $r.ST = 55; $r.Known = $false }
    else { $r.Known = $false }
    $r.ST = [math]::Round($r.ST, 1)
    $r
}

# ---------------------------------------------------------------------
#  Identification de la carte graphique
# ---------------------------------------------------------------------
function Get-GpuInfo([string]$name) {
    $n = ($name.ToUpper() -replace '\(TM\)|\(R\)|™|®', ' ' -replace '\s+', ' ').Trim()
    $o = [ordered]@{ Name = $name; G = $null; V = 0.0; Igpu = $false; Known = $false; Vendor = 'Autre'; Laptop = $false; Driver = ''; DriverDate = $null; Av1 = $false }
    if ($n -match 'NVIDIA|GEFORCE|RTX|GTX|QUADRO') { $o.Vendor = 'NVIDIA' } elseif ($n -match 'RADEON|AMD') { $o.Vendor = 'AMD' } elseif ($n -match 'INTEL|ARC|IRIS|UHD') { $o.Vendor = 'Intel' }
    foreach ($e in $GPU_DB) {
        if ($n -match ('\b(?:' + $e[0] + ')\b')) { $o.G = [double]$e[1]; $o.V = [double]$e[2]; $o.Known = $true; break }
    }
    if (-not $o.Known) {
        foreach ($e in $IGPU_DB) {
            if ($n -match ('\b(?:' + $e[0] + ')\b')) { $o.G = [double]$e[1]; $o.V = 0.0; $o.Known = $true; $o.Igpu = $true; break }
        }
    }
    if ($o.Known -and -not $o.Igpu -and $n -match 'LAPTOP|MOBILE|MAX-Q') { $o.G = [math]::Round($o.G * 0.72, 1); $o.Laptop = $true }
    if (-not $o.Known) {
        if ($n -match 'BASIC|MICROSOFT|STANDARD|VGA') { $o.G = 0.0 } else { $o.G = 10.0 }
    }
    $o.Av1 = ($n -match 'RTX [45]0\d\d|RX [79]\d{3}|ARC')
    $o
}

# =====================================================================
#  DÉMARRAGE
# =====================================================================
Clear-Host
Write-Host '=====================================================' -ForegroundColor Cyan
Write-Host "        DIAGNOSTIC COMPLET DU PC  (v$VERSION)" -ForegroundColor Cyan
Write-Host '=====================================================' -ForegroundColor Cyan
Write-Host 'Fermez les autres programmes pendant le test.'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Host 'ATTENTION : pas en administrateur, certaines infos manqueront.' -ForegroundColor Yellow }
Write-Host ''
Write-Host 'Pour quels usages veux-tu vérifier ce PC ?' -ForegroundColor Cyan
foreach ($u in $USAGES) { Write-Host ("   {0}. {1}" -f $u.Id, $u.Nom) }
$sel = Read-Host 'Tape les numéros séparés par des espaces (ex : 3 7 9), ou Entrée pour tout évaluer'
$selected = @()
foreach ($tok in ($sel -split '[\s,;]+')) {
    if ($tok -match '^\d+$' -and @($USAGES | Where-Object { $_.Id -eq [int]$tok }).Count) { $selected += [int]$tok }
}
$selected = @($selected | Sort-Object -Unique)
$ans = Read-Host 'Durée du test de charge processeur en minutes (Entrée = 5)'
$stressMin = 5
if ($ans -match '^\d+$' -and [int]$ans -ge 1) { $stressMin = [int]$ans }
Write-Host ''
Init-Lhm

# ---------------------------------------------------------------- 1
Step 1 'Windows (version, activation)'
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
$lic = $null
try {
    $lic = Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL" -ErrorAction Stop |
           Where-Object { $_.Name -like 'Windows*' } | Select-Object -First 1
} catch {}
$licNames = @{ 0 = 'Non activé'; 1 = 'ACTIVÉ'; 2 = 'Période de grâce'; 3 = 'Période de grâce'; 4 = 'Non authentique'; 5 = 'Notification (non activé)'; 6 = 'Période de grâce étendue' }
$licText = 'Inconnu'
if ($lic) { $licText = $licNames[[int]$lic.LicenseStatus] + ' (' + $lic.Description + ')' }
$winActive = ($lic -and [int]$lic.LicenseStatus -eq 1)
$uptime = (Get-Date) - $os.LastBootUpTime
Add-Table 'Windows' ([ordered]@{
    'Système'                         = "$($os.Caption) $($cv.DisplayVersion) (build $($cv.CurrentBuild))"
    'Activation'                      = $licText
    'Date dʼinstallation (ou de la dernière grosse mise à jour)' = $os.InstallDate.ToString('dd/MM/yyyy')
    'Allumé depuis'                   = "$([int]$uptime.TotalDays) j $($uptime.Hours) h"
    'Fabricant / modèle'              = "$($cs.Manufacturer) / $($cs.Model)"
})
if ($winActive) { Add-Alert OK 'Windows est activé.' } else { Add-Alert ORANGE "Windows nʼest pas activé ($licText)." }

# ---------------------------------------------------------------- 2
Step 2 'Processeur, carte mère, BIOS, type de PC'
$cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
$bb   = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS
$enc  = Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue | Select-Object -First 1
$batt = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)
$isLaptop = $false
$chassis = @(); if ($enc) { $chassis = @($enc.ChassisTypes | ForEach-Object { [int]$_ }) }
foreach ($t in $chassis) { if (@(8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32) -contains $t) { $isLaptop = $true } }
if (-not $isLaptop -and $batt.Count -gt 0 -and ($chassis.Count -eq 0 -or ($chassis | Where-Object { $_ -le 2 }))) { $isLaptop = $true }
$pcType = $(if ($isLaptop) { 'PC portable' } else { 'PC de bureau (tour)' })
$cpuName = ("" + $cpu.Name).Trim()
$cpuInfo = Get-CpuInfo $cpuName $isLaptop
$threads = [int]$cpu.NumberOfLogicalProcessors
$cores = [int]$cpu.NumberOfCores
$slots = (Get-CimInstance Win32_PhysicalMemoryArray | Measure-Object -Property MemoryDevices -Sum).Sum
$biosDate = ''; try { $biosDate = $bios.ReleaseDate.ToString('dd/MM/yyyy') } catch {}
Add-Table 'Processeur, carte mère, BIOS' ([ordered]@{
    'Type de PC'           = $pcType
    'Processeur'           = $cpuName
    'Cœurs / threads'      = "$cores / $threads"
    'Fréquence de base'    = "$($cpu.MaxClockSpeed) MHz"
    'Support (socket)'     = $(if ($cpuInfo.Socket) { $cpuInfo.Socket } elseif ($cpuInfo.Mobile) { 'soudé (portable)' } else { 'non identifié' })
    'Carte mère'           = "$($bb.Manufacturer) $($bb.Product)"
    'BIOS'                 = "$($bios.SMBIOSBIOSVersion) du $biosDate"
})
Write-Host "   $pcType - $cpuName - carte mère $($bb.Manufacturer) $($bb.Product)"
if (-not $cpuInfo.Known) { Add-Alert INFO "Processeur absent de la base : sa note 1 cœur est estimée." }

# Batterie (portables)
$battHealth = $null
if ($isLaptop) {
    try {
        $des  = (Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction Stop | Select-Object -First 1).DesignedCapacity
        $full = (Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction Stop | Select-Object -First 1).FullChargedCapacity
        if ($des -gt 0 -and $full -gt 0) { $battHealth = [int][math]::Min(100, 100 * $full / $des) }
    } catch {}
    if ($batt.Count -and [int]$batt[0].BatteryStatus -eq 1) { Add-Alert ORANGE 'Le portable est sur batterie : branche le chargeur, sinon les performances mesurées seront plus basses.' }
    if ($null -ne $battHealth) {
        $sections.Add("<p>Santé de la batterie : <b>$battHealth %</b> de sa capacité dʼorigine.</p>")
        if ($battHealth -lt 60) { Add-Alert ROUGE "Batterie usée : $battHealth % de sa capacité dʼorigine (à remplacer)." 10 }
        elseif ($battHealth -lt 80) { Add-Alert ORANGE "Batterie fatiguée : $battHealth % de sa capacité dʼorigine." 3 }
        else { Add-Alert OK "Batterie en bon état ($battHealth %)." }
    }
}

# ---------------------------------------------------------------- 3
Step 3 'Mémoire vive (RAM)'
$mods = @(Get-CimInstance Win32_PhysicalMemory)
$memTypes = @{ 20 = 'DDR'; 21 = 'DDR2'; 24 = 'DDR3'; 26 = 'DDR4'; 27 = 'LPDDR'; 28 = 'LPDDR2'; 29 = 'LPDDR3'; 30 = 'LPDDR4'; 34 = 'DDR5'; 35 = 'LPDDR5' }
$ramType = ''
if ($mods.Count) {
    $code = [int]$mods[0].SMBIOSMemoryType
    if ($memTypes.ContainsKey($code)) { $ramType = $memTypes[$code] }
    elseif ([int]$mods[0].Speed -ge 4400) { $ramType = 'DDR5' }
    elseif ([int]$mods[0].Speed -ge 2133) { $ramType = 'DDR4' }
    elseif ([int]$mods[0].Speed -gt 0) { $ramType = 'DDR3' }
}
$ramSoldered = ($ramType -like 'LP*')
$ramRows = foreach ($m in $mods) {
    [pscustomobject]@{
        'Emplacement'    = $m.DeviceLocator
        'Taille'         = "$(GB $m.Capacity) Go"
        'Type'           = $ramType
        'Vitesse annoncée' = "$($m.Speed) MT/s"
        'Vitesse réelle' = "$($m.ConfiguredClockSpeed) MT/s"
        'Fabricant'      = $m.Manufacturer
        'Référence'      = ("" + $m.PartNumber).Trim()
    }
}
$ramTotal = GB (($mods | Measure-Object -Property Capacity -Sum).Sum)
$channels = [math]::Min([math]::Max($mods.Count, 1), 2)
if ($ramSoldered) { $channels = 2 }   # mémoire soudée : toujours en multi-canal
Add-Grid "Barrettes de RAM ($ramTotal Go $ramType, $($mods.Count) barrette(s), $slots emplacement(s) annoncés)" $ramRows
if ($mods.Count -eq 1 -and $slots -ge 2 -and -not $ramSoldered) { Add-Alert ORANGE "Une seule barrette : la RAM tourne en simple canal (deux fois moins de bande passante)." }
$xmpOff = $false
if ($mods.Count -and $mods[0].Speed -and $mods[0].ConfiguredClockSpeed -and ($mods[0].ConfiguredClockSpeed -lt $mods[0].Speed - 200) -and -not $isLaptop) {
    $xmpOff = $true; Add-Alert ORANGE "La RAM tourne à $($mods[0].ConfiguredClockSpeed) MT/s au lieu de $($mods[0].Speed) MT/s : profil XMP/EXPO non activé dans le BIOS."
}

# ---------------------------------------------------------------- 4
Step 4 'Carte graphique et écran'
$vram = @{}
$classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
Get-ChildItem $classKey -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
    $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
    $v = $p.'HardwareInformation.qwMemorySize'
    if (-not $v) { $v = $p.'HardwareInformation.MemorySize' }
    if ($v -and $p.DriverDesc) {
        if ($v -is [byte[]]) { if ($v.Length -ge 8) { $v = [BitConverter]::ToUInt64($v, 0) } else { $v = [BitConverter]::ToUInt32($v, 0) } }
        $vram[$p.DriverDesc] = GB $v
    }
}
$gpus = @()
foreach ($g in @(Get-CimInstance Win32_VideoController)) {
    if ("$($g.Name)" -match 'Virtual|Remote|Parsec|DisplayLink|Mirror|Indirect') { continue }
    $info = Get-GpuInfo ("" + $g.Name)
    if (-not $info.Igpu -and $vram[$g.Name] -and $vram[$g.Name] -ge 1) { $info.V = [double]$vram[$g.Name] }
    $info.Driver = $g.DriverVersion
    $info.DriverDate = $g.DriverDate
    $info.Res = "$($g.CurrentHorizontalResolution) x $($g.CurrentVerticalResolution) @ $($g.CurrentRefreshRate) Hz"
    $gpus += [pscustomobject]$info
}
$mainGpu = $gpus | Sort-Object { [double]$_.G } -Descending | Select-Object -First 1
if ($smi -and $mainGpu -and $mainGpu.Vendor -eq 'NVIDIA') {
    # mémoire vidéo exacte donnée par le pilote NVIDIA
    try { $mt = ToD (& $smi --query-gpu=memory.total --format=csv,noheader,nounits 2>$null | Select-Object -First 1); if ($mt -gt 0) { $mainGpu.V = [math]::Round($mt / 1024, 1) } } catch {}
}
$gpuRows = foreach ($g in $gpus) {
    [pscustomobject]@{
        'Carte'          = $g.Name
        'Type'           = $(if ($g.Igpu) { 'intégrée au processeur' } elseif ($g.Laptop) { 'dédiée (version portable)' } else { 'dédiée' })
        'Mémoire vidéo'  = $(if ($g.Igpu) { 'partagée avec la RAM' } else { "$($g.V) Go" })
        'Indice /100'    = $(if ($g.Known) { $g.G } else { "$($g.G) (estimé)" })
        'Pilote'         = "$($g.Driver) ($(try { $g.DriverDate.ToString('dd/MM/yyyy') } catch { '?' }))"
        'Affichage'      = $g.Res
    }
}
Add-Grid 'Carte(s) graphique(s)' $gpuRows
if (-not $mainGpu -or $mainGpu.G -eq 0) { Add-Alert ROUGE 'Aucun pilote graphique correct installé (carte en mode "affichage de base").' 10 }
elseif (-not $mainGpu.Known) { Add-Alert INFO "Carte graphique « $($mainGpu.Name) » absente de la base : performance estimée." }
else { Add-Alert OK "Carte graphique principale : $($mainGpu.Name) (indice $($mainGpu.G)/100)." }
$monRows = @()
try {
    $monRows = foreach ($mo in Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction Stop) {
        $dec = { param($a) if ($a) { -join ([char[]]($a | Where-Object { $_ -ne 0 })) } else { '' } }
        [pscustomobject]@{
            'Écran'       = & $dec $mo.UserFriendlyName
            'Fabricant'   = & $dec $mo.ManufacturerName
            'Fabriqué en' = "semaine $($mo.WeekOfManufacture) de $($mo.YearOfManufacture)"
        }
    }
} catch {}
Add-Grid 'Écran(s)' $monRows

# ---------------------------------------------------------------- 5
Step 5 'Santé des disques'
$sysDiskNum = $null; try { $sysDiskNum = [int](Get-Partition -DriveLetter C -ErrorAction Stop | Select-Object -First 1).DiskNumber } catch {}
$keyDiskNum = $null; try { $keyDiskNum = [int](Get-Partition -DriveLetter $root.Substring(0, 1) -ErrorAction Stop | Select-Object -First 1).DiskNumber } catch {}
$pdisks = @(Get-PhysicalDisk | Where-Object { "$($_.BusType)" -ne 'USB' -and ($null -eq $keyDiskNum -or [int]$_.DeviceId -ne $keyDiskNum) })
function Disk-Kind($d) {
    if ("$($d.BusType)" -eq 'NVMe') { return 'NVMe' }
    if ("$($d.MediaType)" -eq 'SSD') { return 'SSD SATA' }
    if ("$($d.MediaType)" -eq 'HDD') { return 'Disque dur (HDD)' }
    if ($d.SpindleSpeed -gt 0 -and $d.SpindleSpeed -lt 20000) { return 'Disque dur (HDD)' }
    return 'SSD (type inconnu)'
}
$diskRows = @(); $sysDisk = $null; $sysKind = 'SSD (type inconnu)'; $sysWear = $null
foreach ($d in $pdisks) {
    $rc = $null; try { $rc = $d | Get-StorageReliabilityCounter -ErrorAction Stop } catch {}
    $kind = Disk-Kind $d
    $isSys = ($null -ne $sysDiskNum -and [int]$d.DeviceId -eq $sysDiskNum)
    if ($isSys) { $sysDisk = $d; $sysKind = $kind; $sysWear = $rc.Wear }
    $diskRows += [pscustomobject]@{
        'Disque'          = "$($d.FriendlyName)$(if ($isSys) { ' (Windows)' })"
        'Type'            = $kind
        'Taille'          = "$(GB $d.Size) Go"
        'État Windows'    = $d.HealthStatus
        'Heures allumé'   = $rc.PowerOnHours
        'Usure %'         = $rc.Wear
        'Temp. / max'     = "$($rc.Temperature) / $($rc.TemperatureMax) C"
        'Erreurs lecture' = $rc.ReadErrorsUncorrected
    }
    if ("$($d.HealthStatus)" -ne 'Healthy') { Add-Alert ROUGE "Disque $($d.FriendlyName) : état $($d.HealthStatus)." 30 }
    if ($null -ne $rc.Wear -and "$($d.BusType)" -ne 'NVMe') {   # NVMe : usure lue plus bas via SMART
        if ($rc.Wear -ge 50) { Add-Alert ROUGE "SSD $($d.FriendlyName) usé à $($rc.Wear) %." 20 }
        elseif ($rc.Wear -ge 20) { Add-Alert ORANGE "SSD $($d.FriendlyName) usé à $($rc.Wear) %." 5 }
    }
    if ($rc.ReadErrorsUncorrected -gt 0) { Add-Alert ROUGE "Disque $($d.FriendlyName) : $($rc.ReadErrorsUncorrected) erreurs de lecture non corrigées." 20 }
    if ($kind -like 'Disque dur*' -and $isSys) { Add-Alert ORANGE 'Windows est installé sur un disque dur mécanique : le PC sera lent (un SSD change tout).' }
}
Add-Grid 'Disques internes' $diskRows

# Compteurs SMART des SSD NVMe (lecture directe, sans logiciel externe)
$nvmeCode = @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class NvmeSmart {
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern SafeFileHandle CreateFile(string name, uint access, uint share, IntPtr sec, uint disp, uint flags, IntPtr tmpl);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool DeviceIoControl(SafeFileHandle h, uint code, byte[] inBuf, int inSize, byte[] outBuf, int outSize, out int ret, IntPtr ov);
    public static byte[] ReadHealthLog(int drive) {
        using (SafeFileHandle h = CreateFile(@"\\.\PhysicalDrive" + drive, 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero)) {
            if (h.IsInvalid) return null;
            int total = 8 + 40 + 512;
            byte[] buf = new byte[total];
            BitConverter.GetBytes(50).CopyTo(buf, 0);   // StorageDeviceProtocolSpecificProperty
            BitConverter.GetBytes(0).CopyTo(buf, 4);    // PropertyStandardQuery
            BitConverter.GetBytes(3).CopyTo(buf, 8);    // ProtocolTypeNvme
            BitConverter.GetBytes(2).CopyTo(buf, 12);   // NVMeDataTypeLogPage
            BitConverter.GetBytes(2).CopyTo(buf, 16);   // page 0x02 : SMART / Health
            BitConverter.GetBytes(0).CopyTo(buf, 20);
            BitConverter.GetBytes(40).CopyTo(buf, 24);  // ProtocolDataOffset
            BitConverter.GetBytes(512).CopyTo(buf, 28); // ProtocolDataLength
            byte[] outBuf = new byte[total];
            int ret;
            if (!DeviceIoControl(h, 0x002D1400, buf, total, outBuf, total, out ret, IntPtr.Zero)) return null;
            int off = 8 + BitConverter.ToInt32(outBuf, 8 + 16);
            if (off < 0 || off + 512 > outBuf.Length) return null;
            byte[] log = new byte[512];
            Array.Copy(outBuf, off, log, 0, 512);
            return log;
        }
    }
}
'@
$nvmeRows = @()
try {
    if (-not ('NvmeSmart' -as [type])) { Add-Type -TypeDefinition $nvmeCode -ErrorAction Stop }
    foreach ($d in $pdisks | Where-Object { "$($_.BusType)" -eq 'NVMe' }) {
        $log = [NvmeSmart]::ReadHealthLog([int]$d.DeviceId)
        if ($log) {
            $u64 = { param($o) [BitConverter]::ToUInt64($log, $o) }
            $tb = { param($o) [math]::Round((& $u64 $o) * 512000 / 1e12, 2) }
            $row = [pscustomobject]@{
                'Disque'               = $d.FriendlyName
                'Allumages'            = & $u64 112
                'Heures dʼutilisation' = & $u64 128
                'Arrêts brutaux'       = & $u64 144
                'Usure %'              = $log[5]
                'Réserve %'            = $log[3]
                'Données écrites'      = "$(& $tb 48) To"
                'Erreurs média'        = & $u64 160
                'Température'          = "$([BitConverter]::ToUInt16($log, 1) - 273) C"
                'Alerte critique'      = $log[0]
            }
            $nvmeRows += $row
            if ([int]$d.DeviceId -eq $sysDiskNum -and $null -eq $sysWear) { $sysWear = [int]$log[5] }
            Write-Host "   $($d.FriendlyName) : $($row.'Allumages') allumages, $($row.'Heures dʼutilisation') h, $($row.'Données écrites') écrits, usure $($log[5]) %"
            if ($log[0] -ne 0) { Add-Alert ROUGE "SSD $($d.FriendlyName) : alerte critique SMART (code $($log[0]))." 40 }
            if ((& $u64 160) -gt 0) { Add-Alert ROUGE "SSD $($d.FriendlyName) : $(& $u64 160) erreurs média." 20 }
            if ($log[3] -lt $log[4]) { Add-Alert ROUGE "SSD $($d.FriendlyName) : réserve de secours épuisée ($($log[3]) %)." 30 }
            if ($log[5] -ge 50) { Add-Alert ROUGE "SSD $($d.FriendlyName) usé à $($log[5]) % (prévoir son remplacement)." 15 }
            elseif ($log[5] -ge 20) { Add-Alert ORANGE "SSD $($d.FriendlyName) usé à $($log[5]) %." 5 }
            else { Add-Alert OK "SSD $($d.FriendlyName) : usure $($log[5]) %, $($row.'Données écrites') écrits." }
        }
    }
} catch { Write-Host "   Lecture SMART directe impossible : $_" -ForegroundColor DarkGray }
if ($nvmeRows.Count) { Add-Grid 'SSD NVMe : compteurs internes (SMART)' $nvmeRows }
$c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeC = 0; $sizeC = 0; if ($c) { $freeC = GB $c.FreeSpace; $sizeC = GB $c.Size }
$sections.Add("<p>Espace libre sur C: : <b>$freeC Go</b> sur $sizeC Go</p>")
if ($sizeC -gt 0 -and $freeC / $sizeC -lt 0.1) { Add-Alert ORANGE "Disque C: presque plein ($freeC Go libres) : le PC ralentit." }

# CrystalDiskInfo (optionnel)
$cdi = Get-ChildItem (Join-Path $root 'CrystalDiskInfo') -Recurse -Filter 'DiskInfo64.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($cdi) {
    Write-Host '   CrystalDiskInfo trouvé, lecture SMART complète...'
    try {
        Start-Process -FilePath $cdi.FullName -ArgumentList '/CopyExit' -Wait -WindowStyle Hidden
        $txt = Join-Path $cdi.DirectoryName 'DiskInfo.txt'
        if (Test-Path $txt) {
            $keep = (Get-Content $txt) | Where-Object { $_ -match 'Model|Firmware|Health Status|Temperature|Power On (Hours|Count)|Host Writes|Host Reads' }
            $sections.Add("<h3>CrystalDiskInfo (résumé)</h3><pre>$(Enc ($keep -join "`n"))</pre>")
        }
    } catch { Write-Host '   Échec CrystalDiskInfo.' -ForegroundColor Yellow }
}

# ---------------------------------------------------------------- 6
Step 6 'Historique des pannes (6 derniers mois)'
$since = (Get-Date).AddDays(-180)
function Count-Events($provider, $ids) {
    $f = @{ LogName = 'System'; ProviderName = $provider; StartTime = $since }
    if ($ids) { $f.Id = $ids }
    try { @(Get-WinEvent -FilterHashtable $f -ErrorAction Stop).Count } catch { 0 }
}
$kp        = Count-Events 'Microsoft-Windows-Kernel-Power' 41
$bsod      = Count-Events 'Microsoft-Windows-WER-SystemErrorReporting' 1001
$wheaFatal = Count-Events 'Microsoft-Windows-WHEA-Logger' @(1, 18, 20)
$wheaCorr  = Count-Events 'Microsoft-Windows-WHEA-Logger' @(17, 19, 47)
$diskBad   = Count-Events 'disk' @(7, 11)
$diskWarn  = Count-Events 'disk' @(51, 153)
Add-Table 'Historique des pannes (180 jours)' ([ordered]@{
    'Arrêts brutaux (coupure, plantage, bouton maintenu)' = $kp
    'Écrans bleus'                                         = $bsod
    'Erreurs matérielles graves (WHEA)'                    = $wheaFatal
    'Erreurs matérielles corrigées (WHEA, souvent bénignes)' = $wheaCorr
    'Secteurs défectueux / erreurs contrôleur disque'     = $diskBad
    'Avertissements disque (clé USB retirée, délais...)'   = $diskWarn
})
if ($bsod -gt 3) { Add-Alert ROUGE "$bsod écrans bleus en 6 mois." 20 } elseif ($bsod -gt 0) { Add-Alert ORANGE "$bsod écran(s) bleu(s) en 6 mois." (5 * $bsod) }
if ($wheaFatal -gt 0) { Add-Alert ROUGE "$wheaFatal erreur(s) matérielle(s) grave(s) (processeur, RAM ou carte graphique)." 20 }
if ($wheaCorr -gt 50) { Add-Alert ORANGE "$wheaCorr erreurs matérielles corrigées (souvent un réglage PCIe ou un pilote ; à surveiller)." 3 }
if ($diskBad -gt 0) { Add-Alert ROUGE "$diskBad erreur(s) de secteur ou de contrôleur disque." 15 }
if ($diskWarn -gt 20) { Add-Alert ORANGE "$diskWarn avertissements disque dans le journal." 3 }
if ($kp -gt 5) { Add-Alert ORANGE "$kp arrêts brutaux (coupures de courant ou plantages)." 5 }
if ($bsod -eq 0 -and $wheaFatal -eq 0 -and $diskBad -eq 0) { Add-Alert OK 'Aucun écran bleu, aucune erreur matérielle grave ni erreur disque.' }

# ---------------------------------------------------------------- 7
Step 7 'Benchmark Windows (WinSAT) - 2 à 5 min'
Write-Host '   Lʼécran peut clignoter, cʼest normal. Ne touchez à rien.' -ForegroundColor DarkGray
$ws = $null; $wx = $null
try {
    Start-Process -FilePath "$env:windir\System32\winsat.exe" -ArgumentList 'formal -restart clean' -Wait -WindowStyle Hidden
    $ws = Get-CimInstance Win32_WinSAT -ErrorAction Stop
    $xmlFile = Get-ChildItem "$env:windir\Performance\WinSAT\DataStore" -Filter '*Formal.Assessment*.xml' -ErrorAction Stop | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($xmlFile) { [xml]$wx = Get-Content $xmlFile.FullName -Raw }
} catch { Write-Host "   WinSAT indisponible : $_" -ForegroundColor Yellow }
function XVal($xpath) { if ($wx) { $nd = $wx.SelectSingleNode($xpath); if ($nd) { return [double]$nd.InnerText } }; return $null }
$memBwWs = XVal '//MemoryMetrics/Bandwidth'
$seqRead = $null
if ($wx) {
    foreach ($nd in $wx.SelectNodes('//DiskMetrics/AvgThroughput')) {
        if (("" + $nd.kind + $nd.OuterXml) -match 'Sequential Read') { $seqRead = [double]$nd.InnerText; break }
    }
}
if ($ws -and $ws.CPUScore -gt 0) {
    Add-Table 'Notes Windows WinSAT (maximum 9,9)' ([ordered]@{
        'Processeur' = $ws.CPUScore; 'Mémoire' = $ws.MemoryScore; 'Graphisme bureau' = $ws.GraphicsScore
        'Graphisme 3D' = $ws.D3DScore; 'Disque' = "$($ws.DiskScore) (lecture séquentielle $([int]$seqRead) Mo/s)"
    })
    if ($mainGpu -and -not $mainGpu.Igpu -and $mainGpu.G -ge 15 -and $ws.D3DScore -gt 0 -and $ws.D3DScore -lt 8) {
        Add-Alert ORANGE "La carte graphique obtient une note 3D Windows basse ($($ws.D3DScore)/9,9) : pilote à mettre à jour ou carte qui ne fonctionne pas à pleine vitesse." 5
    }
}

# ---------------------------------------------------------------- 8
Step 8 'Benchmark processeur : 1 cœur puis tous les cœurs (2 x 15 s)'
$benchCode = @'
using System;
using System.Threading;
public static class DiagBench {
    static long _units, _errors;
    static Thread[] _threads = new Thread[0];
    // Un "bloc" de calcul : entiers + virgule flottante, résultat toujours identique sur un CPU sain
    static ulong Unit(ulong seed) {
        ulong x = seed; double f = 1.0;
        for (int i = 0; i < 20000; i++) {
            x ^= x << 13; x ^= x >> 7; x ^= x << 17;
            x = x * 0x9E3779B97F4A7C15UL + (ulong)i;
            f = f * 1.0000001 + (double)(x & 0xFF) * 1e-9;
            if (f > 2.0) f -= 1.0;
        }
        return x ^ (ulong)(f * 1e9);
    }
    public static void Start(int threads, int seconds) {
        _units = 0; _errors = 0;
        ulong expected = Unit(0x1234567UL);
        DateTime end = DateTime.UtcNow.AddSeconds(seconds);
        _threads = new Thread[threads];
        for (int t = 0; t < threads; t++) {
            Thread th = new Thread(delegate() {
                long n = 0, e = 0;
                while (DateTime.UtcNow < end) {
                    if (Unit(0x1234567UL) != expected) e++;
                    n++;
                }
                Interlocked.Add(ref _units, n);
                Interlocked.Add(ref _errors, e);
            });
            th.IsBackground = true;
            _threads[t] = th;
            th.Start();
        }
    }
    public static bool IsRunning() { foreach (Thread t in _threads) { if (t.IsAlive) return true; } return false; }
    public static long[] Finish() {
        foreach (Thread t in _threads) t.Join();
        return new long[] { Interlocked.Read(ref _units), Interlocked.Read(ref _errors) };
    }
    // Bande passante mémoire (Go/s), lecture + écriture
    public static double MemBandwidth(int threads, int seconds) {
        long bytes = 0;
        DateTime start = DateTime.UtcNow;
        DateTime end = start.AddSeconds(seconds);
        Thread[] ts = new Thread[threads];
        for (int t = 0; t < threads; t++) {
            ts[t] = new Thread(delegate() {
                byte[] a = new byte[64 * 1024 * 1024];
                byte[] b = new byte[64 * 1024 * 1024];
                long local = 0;
                while (DateTime.UtcNow < end) { Buffer.BlockCopy(a, 0, b, 0, a.Length); local += a.Length; }
                Interlocked.Add(ref bytes, local);
            });
            ts[t].IsBackground = true;
            ts[t].Start();
        }
        foreach (Thread t in ts) t.Join();
        double sec = (DateTime.UtcNow - start).TotalSeconds;
        return Interlocked.Read(ref bytes) * 2.0 / sec / 1e9;
    }
}
'@
$benchOk = $false
try { if (-not ('DiagBench' -as [type])) { Add-Type -TypeDefinition $benchCode -ErrorAction Stop }; $benchOk = $true }
catch { Write-Host "   Benchmark impossible sur ce PC : $_" -ForegroundColor Yellow }
function Run-Bench([int]$nThreads, [int]$sec, [string]$label) {
    [DiagBench]::Start($nThreads, $sec)
    $t0 = Get-Date
    while ([DiagBench]::IsRunning()) {
        Start-Sleep -Milliseconds 500
        $el = ((Get-Date) - $t0).TotalSeconds
        Write-Progress -Activity 'Benchmark processeur' -Status $label -PercentComplete ([math]::Min(100, 100 * $el / $sec))
    }
    $r = [DiagBench]::Finish()
    Write-Progress -Activity 'Benchmark processeur' -Completed
    [math]::Round($r[0] / $sec, 1)
}
$mono = $null; $multi = $null; $scaling = $null; $memBw = $null
if ($benchOk) {
    $mono  = Run-Bench 1 15 '1 cœur'
    $multi = Run-Bench $threads 15 "$threads threads"
    if ($mono -gt 0) { $scaling = [math]::Round($multi / $mono, 1) }
    try { $memBw = [math]::Round([DiagBench]::MemBandwidth([math]::Min($threads, 8), 4), 1) } catch {}
    Write-Host "   1 cœur : $mono pts | $threads threads : $multi pts | gain x$scaling | mémoire : $memBw Go/s"
    if ($scaling -lt $cores * 0.4) { Add-Alert ORANGE "Le processeur monte mal en charge (x$scaling pour $cores cœurs) : bridage, surchauffe ou programme en arrière-plan." 5 }
}

# ---------------------------------------------------------------- 9
Step 9 'Vitesse du disque Windows (écriture de 2 Go)'
$tmp = Join-Path $env:TEMP 'diag_vitesse_disque.bin'
$writeMBs = $null; $fs = $null
try {
    $buf = New-Object byte[] (8MB); (New-Object Random 42).NextBytes($buf)
    $total = 2GB
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $fs = New-Object IO.FileStream($tmp, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None, 8MB, [IO.FileOptions]::WriteThrough)
    for ($w = 0; $w -lt $total; $w += $buf.Length) { $fs.Write($buf, 0, $buf.Length) }
    $fs.Flush($true); $fs.Close(); $sw.Stop()
    $writeMBs = [int](($total / 1MB) / $sw.Elapsed.TotalSeconds)
    Write-Host "   Écriture : $writeMBs Mo/s"
} catch { Write-Host "   Test impossible : $_" -ForegroundColor Yellow }
finally { if ($fs) { $fs.Dispose() }; Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
Add-Table 'Vitesse du disque Windows' ([ordered]@{
    'Écriture séquentielle (2 Go)' = "$writeMBs Mo/s"
    'Lecture séquentielle (WinSAT)' = $(if ($seqRead) { "$([int]$seqRead) Mo/s" } else { 'non mesurée' })
})

# ---------------------------------------------------------------- 10
Step 10 'Test de la mémoire vive (écriture / vérification)'
[GC]::Collect()
$freeBytes = [int64]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory) * 1KB
$testBytes = [math]::Min([int64]8GB, $freeBytes - [int64]2GB)
$chunk = 256MB
$ramErrors = 0; $ramTested = 0
if ($testBytes -ge 512MB) {
    $nb = [int][math]::Floor($testBytes / $chunk)
    $sha = [Security.Cryptography.SHA256]::Create()
    $pattern = New-Object byte[] (1MB)
    foreach ($pass in 1..2) {
        (New-Object Random (100 + $pass)).NextBytes($pattern)
        $ref = New-Object byte[] $chunk
        for ($o = 0; $o -lt $chunk; $o += $pattern.Length) { [Buffer]::BlockCopy($pattern, 0, $ref, $o, $pattern.Length) }
        $expected = [BitConverter]::ToString($sha.ComputeHash($ref)); $ref = $null
        $blocks = New-Object System.Collections.Generic.List[byte[]]
        for ($i = 0; $i -lt $nb; $i++) {
            Write-Progress -Activity "Test RAM - passe $pass/2" -Status "Écriture bloc $($i+1)/$nb" -PercentComplete (100 * $i / $nb)
            $b = New-Object byte[] $chunk
            for ($o = 0; $o -lt $chunk; $o += $pattern.Length) { [Buffer]::BlockCopy($pattern, 0, $b, $o, $pattern.Length) }
            $blocks.Add($b)
        }
        for ($i = 0; $i -lt $nb; $i++) {
            Write-Progress -Activity "Test RAM - passe $pass/2" -Status "Vérification bloc $($i+1)/$nb" -PercentComplete (100 * $i / $nb)
            if ([BitConverter]::ToString($sha.ComputeHash($blocks[$i])) -ne $expected) { $ramErrors++ }
        }
        $blocks.Clear(); $blocks = $null; [GC]::Collect()
    }
    Write-Progress -Activity 'Test RAM' -Completed
    $ramTested = GB ($nb * $chunk)
    Write-Host "   $ramTested Go testés, $ramErrors erreur(s)"
    if ($ramErrors -gt 0) { Add-Alert ROUGE "RAM : $ramErrors erreur(s) détectée(s) !" 50 } else { Add-Alert OK "RAM : $ramTested Go testés sans erreur." }
} else { Write-Host '   Pas assez de mémoire libre pour tester.' -ForegroundColor Yellow }
Add-Table 'Mémoire vive : tests' ([ordered]@{
    'Quantité testée'      = "$ramTested Go (mémoire libre uniquement ; MemTest86 reste la référence)"
    'Erreurs'              = $ramErrors
    'Bande passante'       = $(if ($memBw) { "$memBw Go/s" } else { 'non mesurée' })
})

# ---------------------------------------------------------------- 11
Step 11 "Test de charge du processeur ($stressMin min, tous les cœurs)"
$seconds = $stressMin * 60
$samples = New-Object System.Collections.Generic.List[object]
$okTot = 0; $badTot = 0
if ($benchOk) {
    [DiagBench]::Start($threads, $seconds)
    $start = Get-Date
    while ([DiagBench]::IsRunning()) {
        Start-Sleep -Seconds 5
        $load = $null; $freq = $null; $temp = $null
        try { $load = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime } catch {}
        try { $perf = (Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -Filter "Name='_Total'").PercentProcessorPerformance; $freq = [int]($cpu.MaxClockSpeed * $perf / 100) } catch {}
        if ($lhmCpuOk) { $lt = Read-Lhm; if ($lt.Cpu) { $temp = [math]::Round($lt.Cpu) } }
        if (-not $temp -and -not $lhmCpuOk) { try { $tz = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop | Select-Object -First 1; $temp = [math]::Round($tz.CurrentTemperature / 10 - 273.15) } catch {} }
        if (-not $temp -and -not $lhmCpuOk) { try { $tz = Get-CimInstance Win32_PerfFormattedData_Counters_ThermalZoneInformation -ErrorAction Stop | Select-Object -First 1; if ($tz.HighPrecisionTemperature) { $temp = [math]::Round($tz.HighPrecisionTemperature / 10 - 273.15) } } catch {} }
        $el = [int]((Get-Date) - $start).TotalSeconds
        $samples.Add([pscustomobject]@{ T = $el; Charge = $load; MHz = $freq; Temp = $temp })
        Write-Progress -Activity 'Test de charge processeur' -Status "Charge $load %  |  $freq MHz  |  temp. capteur : $temp C" -PercentComplete ([math]::Min(100, 100 * $el / $seconds))
    }
    $r = [DiagBench]::Finish(); $okTot = $r[0]; $badTot = $r[1]
    Write-Progress -Activity 'Test de charge processeur' -Completed
}
$avgLoad = [int](($samples | Where-Object { $null -ne $_.Charge } | Measure-Object -Property Charge -Average).Average)
$firstF = ($samples | Where-Object { $_.T -le 60 -and $_.MHz } | Measure-Object -Property MHz -Average).Average
$lastF  = ($samples | Where-Object { $_.T -gt ($seconds / 2) -and $_.MHz } | Measure-Object -Property MHz -Average).Average
$maxT   = ($samples | Where-Object { $_.Temp -and $_.Temp -gt 0 -and $_.Temp -lt 120 } | Measure-Object -Property Temp -Maximum).Maximum
$freqDrop = ($firstF -and $lastF -and $lastF -lt 0.75 * $firstF)
Add-Table 'Test de charge processeur' ([ordered]@{
    'Durée'                          = "$stressMin min sur $threads threads"
    'Calculs vérifiés'               = "$okTot corrects / $badTot faux"
    'Charge moyenne'                 = "$avgLoad %"
    'Fréquence début / fin de test'  = "$([int]$firstF) / $([int]$lastF) MHz"
    'Température max du processeur' = $(if ($maxT) { "$maxT C $(if ($lhmCpuOk) { '(capteur du processeur)' } else { '(capteur ACPI, indicatif)' })" } else { 'non disponible (ajouter LibreHardwareMonitor)' })
})
if ($benchOk) {
    if ($badTot -gt 0) { Add-Alert ROUGE "Processeur instable : $badTot calcul(s) faux sous charge." 50 } else { Add-Alert OK "Processeur stable : $okTot blocs de calcul vérifiés sans erreur." }
}
if ($freqDrop) { Add-Alert ORANGE "La fréquence chute de $([int]$firstF) à $([int]$lastF) MHz sous charge (surchauffe probable)." 10 }
if ($maxT -and $lhmCpuOk) {
    # vraie température du processeur (certains processeurs récents montent volontairement à 95 C)
    if ($maxT -ge 100) { Add-Alert ROUGE "Processeur à $maxT C sous charge : il atteint sa limite et se bride (refroidissement insuffisant)." 15 }
    elseif ($maxT -ge 95) { Add-Alert ORANGE "Processeur à $maxT C sous charge : très chaud (normal pour certains Ryzen 7000/9000 et Core i9, sinon refroidissement à revoir)." 5 }
    else { Add-Alert OK "Température du processeur sous charge : $maxT C." }
} elseif ($maxT -and $maxT -gt 95) { Add-Alert ORANGE "Température mesurée $maxT C (capteur ACPI, indicatif)." 5 }

# ---------------------------------------------------------------- 12
Step 12 'Test de la carte graphique (puissance, stabilité, chauffe) - 2 min'
Write-Host '   Une fenêtre plein écran va sʼouvrir avec des motifs qui bougent. Ne touchez à rien.' -ForegroundColor DarkGray
$gpuSec = 90
$gpuHtml = @'
<!doctype html><html lang="fr"><head><meta charset="utf-8"><title>Test carte graphique</title>
<style>html,body{margin:0;height:100%;background:#111;color:#eee;font:16px Segoe UI,Arial,sans-serif;overflow:hidden}
canvas{width:100vw;height:100vh;display:block}#hud{position:fixed;left:16px;top:12px;background:rgba(0,0,0,.65);padding:10px 14px;border-radius:8px;line-height:1.5}</style></head>
<body><canvas id="c"></canvas><div id="hud">Test de la carte graphique en cours : ne touchez à rien...</div>
<script>
(async function () {
  const DURATION = __DURATION__;
  const hud = document.getElementById('hud');
  const res = { ok: false, renderer: '', vendor: '', windows: [], errors: 0, checks: 0, lost: false, msg: '' };
  const send = (path, obj) => fetch(path, { method: 'POST', body: JSON.stringify(obj) }).catch(() => {});
  try {
    const cv = document.getElementById('c'); cv.width = 1024; cv.height = 1024;
    const gl = cv.getContext('webgl2', { powerPreference: 'high-performance', antialias: false, depth: false });
    if (!gl) { res.msg = 'WebGL2 indisponible'; await send('/result', res); hud.textContent = res.msg; return; }
    cv.addEventListener('webglcontextlost', e => { res.lost = true; e.preventDefault(); });
    const dbg = gl.getExtension('WEBGL_debug_renderer_info');
    res.renderer = dbg ? gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
    res.vendor = dbg ? gl.getParameter(dbg.UNMASKED_VENDOR_WEBGL) : gl.getParameter(gl.VENDOR);
    const vs = '#version 300 es\nin vec2 p; void main(){ gl_Position = vec4(p, 0.0, 1.0); }';
    const fs = '#version 300 es\nprecision highp float; uniform int it; uniform float seed; out vec4 o;\n' +
      'void main(){ vec4 a = vec4(gl_FragCoord.xy * 0.000977, seed, 0.5);\n' +
      ' for (int i = 0; i < it; i++) { a = fract(a * 1.0013 + sin(a.yzwx * 3.17 + float(i) * 0.013) * 0.71); }\n' +
      ' o = a; }';
    const mk = (type, src) => { const s = gl.createShader(type); gl.shaderSource(s, src); gl.compileShader(s);
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s)); return s; };
    const pr = gl.createProgram(); gl.attachShader(pr, mk(gl.VERTEX_SHADER, vs)); gl.attachShader(pr, mk(gl.FRAGMENT_SHADER, fs));
    gl.linkProgram(pr); gl.useProgram(pr);
    const vb = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, vb);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
    const loc = gl.getAttribLocation(pr, 'p'); gl.enableVertexAttribArray(loc); gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);
    const uIt = gl.getUniformLocation(pr, 'it'), uSeed = gl.getUniformLocation(pr, 'seed');
    const target = (w, h) => { const t = gl.createTexture(); gl.bindTexture(gl.TEXTURE_2D, t); gl.texStorage2D(gl.TEXTURE_2D, 1, gl.RGBA8, w, h);
      const f = gl.createFramebuffer(); gl.bindFramebuffer(gl.FRAMEBUFFER, f);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, t, 0); return f; };
    const W = 1024, H = 1024, big = target(W, H), small = target(64, 64);
    const px = new Uint8Array(4), chk = new Uint8Array(64 * 64 * 4);
    const run = (n, it) => { gl.bindFramebuffer(gl.FRAMEBUFFER, big); gl.viewport(0, 0, W, H); gl.uniform1i(uIt, it);
      for (let k = 0; k < n; k++) { gl.uniform1f(uSeed, (k % 7) * 0.1); gl.drawArrays(gl.TRIANGLES, 0, 3); }
      gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, px); };   // attend la fin du calcul
    const check = () => { gl.bindFramebuffer(gl.FRAMEBUFFER, small); gl.viewport(0, 0, 64, 64); gl.uniform1i(uIt, 3000);
      gl.uniform1f(uSeed, 0.37); gl.drawArrays(gl.TRIANGLES, 0, 3); gl.readPixels(0, 0, 64, 64, gl.RGBA, gl.UNSIGNED_BYTE, chk); return chk; };
    const show = () => { gl.bindFramebuffer(gl.READ_FRAMEBUFFER, big); gl.bindFramebuffer(gl.DRAW_FRAMEBUFFER, null);
      gl.blitFramebuffer(0, 0, W, H, 0, 0, W, H, gl.COLOR_BUFFER_BIT, gl.NEAREST); };
    const ch = new MessageChannel(); const yieldNow = () => new Promise(r => { ch.port1.onmessage = () => r(); ch.port2.postMessage(0); });
    // calibrage : chaque paquet de calcul doit durer environ 50 ms
    let it = 128, n = 1;
    for (;;) { const t0 = performance.now(); run(n, it); const dt = performance.now() - t0;
      if (dt > 30) { n = Math.max(1, Math.round(n * 50 / dt)); break; }
      if (it < 16384) it *= 2; else if (n < 100000) n *= 2; else break; }
    const ref = check().slice();
    const start = performance.now(); let winStart = start, winWork = 0, lastChk = start;
    while (performance.now() - start < DURATION * 1000 && !res.lost) {
      const t0 = performance.now(); run(n, it); const dt = performance.now() - t0; winWork += n * it;
      if (dt > 0) n = Math.max(1, Math.min(n * 2, Math.round(n * 50 / dt)));
      const now = performance.now();
      if (now - lastChk > 2000) { const c = check(); let bad = 0; for (let i = 0; i < c.length; i++) if (c[i] !== ref[i]) bad++;
        res.checks++; if (bad) res.errors++; lastChk = now; }
      if (now - winStart >= 5000) {
        const g = winWork * W * H / ((now - winStart) / 1000) / 1e9; res.windows.push(Math.round(g * 10) / 10);
        winWork = 0; winStart = now; show();
        const el = Math.round((now - start) / 1000);
        hud.innerHTML = 'Test de la carte graphique : ' + el + ' / ' + DURATION + ' s<br>Puissance : ' + g.toFixed(1) +
          ' G ops/s<br>Vérifications : ' + res.checks + ', erreurs : ' + res.errors + '<br><small>' + res.renderer + '</small>';
        send('/progress', { t: el, g: g, e: res.errors });
      }
      await yieldNow();
    }
    res.ok = !res.lost && res.windows.length > 0;
  } catch (e) { res.msg = String(e && e.message || e); }
  await send('/result', res);
  hud.innerHTML = 'Test terminé. Cette fenêtre va se fermer.';
})();
</script></body></html>
'@
$gpuHtml = $gpuHtml.Replace('__DURATION__', "$gpuSec")
$gpuRes = $null; $gpuSamples = New-Object System.Collections.Generic.List[object]
$udd = Join-Path $env:TEMP 'diag-gpu-navigateur'
$listener = $null
try {
    $listener = New-Object System.Net.HttpListener
    $port = Get-Random -Minimum 49200 -Maximum 49900
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Start()
    $url = "http://localhost:$port/"
    $edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    if ($edge) {
        # instance séparée du navigateur, forcée sur la carte graphique la plus puissante
        Start-Process -FilePath $edge -ArgumentList "--user-data-dir=`"$udd`" --no-first-run --no-default-browser-check --force_high_performance_gpu --disable-background-timer-throttling --disable-renderer-backgrounding --start-fullscreen --app=$url"
    } else { Start-Process $url }
    $deadline = (Get-Date).AddSeconds($gpuSec + 90)
    $t0 = Get-Date; $lastSample = Get-Date
    while (-not $gpuRes -and (Get-Date) -lt $deadline) {
        $task = $listener.GetContextAsync()
        while (-not $task.Wait(1000)) {
            if (((Get-Date) - $lastSample).TotalSeconds -ge 3) {
                $lastSample = Get-Date
                $nv = Get-NvSample; $lt = Read-Lhm
                $gt = $null; if ($nv -and $nv.Temp) { $gt = $nv.Temp } elseif ($lt.Gpu) { $gt = $lt.Gpu }
                $gpuSamples.Add([pscustomobject]@{ T = [int]((Get-Date) - $t0).TotalSeconds; Temp = $gt; Hot = $lt.GpuHot; Util = $(if ($nv) { $nv.Util }); Clock = $(if ($nv) { $nv.Clock }); Power = $(if ($nv) { $nv.Power }) })
            }
            if ((Get-Date) -gt $deadline) { break }
        }
        if (-not $task.IsCompleted) { break }
        $ctx = $task.Result; $req = $ctx.Request; $resp = $ctx.Response
        $path = $req.Url.AbsolutePath
        if ($req.HttpMethod -eq 'GET') {
            if ($path -eq '/') { $bytes = [Text.Encoding]::UTF8.GetBytes($gpuHtml); $resp.ContentType = 'text/html; charset=utf-8'; $resp.OutputStream.Write($bytes, 0, $bytes.Length) }
            else { $resp.StatusCode = 404 }
        } else {
            $body = (New-Object IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)).ReadToEnd()
            if ($path -eq '/result') { $gpuRes = $body | ConvertFrom-Json }
            elseif ($path -eq '/progress') {
                try { $pg = $body | ConvertFrom-Json; $lastS = $gpuSamples | Select-Object -Last 1
                    Write-Progress -Activity 'Test carte graphique' -Status ("{0:N1} G ops/s | erreurs : {1} | temp. : {2} C" -f $pg.g, $pg.e, $(if ($lastS) { $lastS.Temp } else { '?' })) -PercentComplete ([math]::Min(100, 100 * $pg.t / $gpuSec)) } catch {}
            }
        }
        $resp.Close()
    }
} catch { Write-Host "   Test de la carte graphique impossible : $($_.Exception.Message)" -ForegroundColor Yellow }
finally {
    Write-Progress -Activity 'Test carte graphique' -Completed
    if ($listener) { try { $listener.Stop(); $listener.Close() } catch {} }
    Start-Sleep -Seconds 1
    Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*diag-gpu-navigateur*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}
$gpuScore = $null; $gpuDrop = $null; $gpuOnMain = $true
$gpuMaxT = ($gpuSamples | Where-Object { $_.Temp } | Measure-Object -Property Temp -Maximum).Maximum
$gpuMaxHot = ($gpuSamples | Where-Object { $_.Hot } | Measure-Object -Property Hot -Maximum).Maximum
$gpuUtil = ($gpuSamples | Where-Object { $null -ne $_.Util -and $_.T -gt 15 } | Measure-Object -Property Util -Average).Average
if ($gpuRes) {
    $wins = @($gpuRes.windows | ForEach-Object { [double]$_ })
    if ($wins.Count -ge 2) {
        $sorted = @($wins | Sort-Object); $gpuScore = [math]::Round($sorted[[int][math]::Floor($sorted.Count / 2)], 1)
        $peak = ($wins | Select-Object -First 4 | Measure-Object -Maximum).Maximum
        $end = ($wins | Select-Object -Last 3 | Measure-Object -Average).Average
        if ($peak -gt 0) { $gpuDrop = [int][math]::Round(100 * (1 - $end / $peak)) }
    }
    # le navigateur a-t-il bien utilisé la carte graphique principale ?
    if ($mainGpu -and -not $mainGpu.Igpu) {
        $rd = ("" + $gpuRes.renderer).ToUpper()
        $want = @{ NVIDIA = 'NVIDIA|GEFORCE|RTX|GTX'; AMD = 'AMD|RADEON'; Intel = 'INTEL|ARC' }[$mainGpu.Vendor]
        if ($want -and $rd -and $rd -notmatch $want) { $gpuOnMain = $false }
    }
    Add-Table 'Test de la carte graphique (WebGL, 90 s)' ([ordered]@{
        'Carte utilisée par le test'   = $gpuRes.renderer
        'Puissance mesurée'            = $(if ($gpuScore) { "$gpuScore G ops/s (médiane)" } else { 'non mesurée' })
        'Évolution pendant le test'    = $(if ($wins.Count) { ($wins -join ' / ') + ' G ops/s' } else { '' })
        'Chute de performance (chauffe)' = $(if ($null -ne $gpuDrop) { "$gpuDrop %" } else { '?' })
        'Vérifications de calcul'      = "$($gpuRes.checks) dont $($gpuRes.errors) en erreur"
        'Température max'              = $(if ($gpuMaxT) { "$gpuMaxT C$(if ($gpuMaxHot) { " (point chaud $gpuMaxHot C)" })" } else { 'non lisible (ajouter LibreHardwareMonitor)' })
        'Utilisation de la carte'      = $(if ($gpuUtil) { "$([int]$gpuUtil) %" } else { 'non lisible' })
        'Plantage du pilote'           = $(if ($gpuRes.lost) { 'OUI' } else { 'non' })
    })
    Write-Host "   Carte : $($gpuRes.renderer)"
    Write-Host "   Puissance : $gpuScore G ops/s | chute : $gpuDrop % | erreurs : $($gpuRes.errors)/$($gpuRes.checks) | temp. max : $gpuMaxT C"
    if ($gpuRes.lost) { Add-Alert ROUGE 'Le pilote de la carte graphique a planté pendant le test (carte instable, surchauffe ou pilote défectueux).' 25 }
    elseif ($gpuRes.errors -gt 0) { Add-Alert ROUGE "Carte graphique instable : $($gpuRes.errors) vérification(s) de calcul fausse(s) sur $($gpuRes.checks) (artefacts, mémoire vidéo ou overclocking)." 30 }
    elseif ($gpuRes.ok) { Add-Alert OK "Carte graphique stable : $($gpuRes.checks) vérifications de calcul sans erreur." }
    if (-not $gpuRes.ok -and $gpuRes.msg) { Add-Alert INFO "Test de la carte graphique incomplet : $($gpuRes.msg)" }
    if (-not $gpuOnMain) { Add-Alert INFO "Le navigateur a utilisé « $($gpuRes.renderer) » au lieu de la carte principale : la puissance mesurée concerne la puce intégrée." }
    if ($gpuOnMain -and $null -ne $gpuDrop -and $gpuDrop -ge 20) { Add-Alert ORANGE "La carte graphique perd $gpuDrop % de puissance en chauffant (ventilateurs encrassés ou pâte thermique sèche)." 8 }
    if ($gpuMaxHot -and $gpuMaxHot -ge 105) { Add-Alert ROUGE "Point chaud de la carte graphique à $gpuMaxHot C." 10 }
    if ($gpuMaxT -and $gpuMaxT -ge 90) { Add-Alert ROUGE "Carte graphique à $gpuMaxT C : beaucoup trop chaude." 10 }
    elseif ($gpuMaxT -and $gpuMaxT -ge 84) { Add-Alert ORANGE "Carte graphique à $gpuMaxT C : chaude." 4 }
} else { Write-Host '   Pas de résultat du test de la carte graphique.' -ForegroundColor Yellow; Add-Alert INFO 'Test de la carte graphique non réalisé : faire un test OCCT à la main.' }

# ---------------------------------------------------------------- 13
Step 13 'Sécurité, logiciels suspects (minage, overclocking), périphériques'
$bl = $null; try { $bl = Get-BitLockerVolume -MountPoint 'C:' -ErrorAction Stop } catch {}
$tpm = $null; try { $tpm = Get-Tpm -ErrorAction Stop } catch {}
$sb = $null; try { $sb = Confirm-SecureBootUEFI -ErrorAction Stop } catch {}
$mp = $null; try { $mp = Get-MpComputerStatus -ErrorAction Stop } catch {}
$threatsN = 0; try { $threatsN = @(Get-MpThreatDetection -ErrorAction Stop).Count } catch {}
$rel = $null; try { $rel = Get-CimInstance Win32_ReliabilityStabilityMetrics -ErrorAction Stop | Sort-Object TimeGenerated -Descending | Select-Object -First 1 } catch {}
$users = @(); try { $users = @(Get-LocalUser -ErrorAction Stop | Where-Object Enabled | ForEach-Object Name) } catch {}
$startupN = @(Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue).Count
Add-Table 'Sécurité et état de Windows' ([ordered]@{
    'Chiffrement BitLocker (C:)'   = $(if ($bl) { "$($bl.ProtectionStatus) - $($bl.VolumeStatus)" } else { 'Non disponible / désactivé' })
    'Puce TPM (Windows 11)'        = $(if ($tpm) { "Présente : $($tpm.TpmPresent), prête : $($tpm.TpmReady)" } else { 'Inconnu' })
    'Démarrage sécurisé'           = $(if ($sb -eq $true) { 'Activé' } elseif ($sb -eq $false) { 'Désactivé' } else { 'Inconnu' })
    'Antivirus Windows'            = $(if ($mp) { "Protection temps réel : $($mp.RealTimeProtectionEnabled), menaces dans lʼhistorique : $threatsN" } else { 'Inconnu (autre antivirus ?)' })
    'Indice de fiabilité Windows'  = $(if ($rel) { "$([math]::Round($rel.SystemStabilityIndex,1)) / 10" } else { 'Non disponible' })
    'Comptes utilisateurs actifs'  = ($users -join ', ')
    'Programmes au démarrage'      = $startupN
})
if ($bl -and "$($bl.ProtectionStatus)" -eq 'On') { Add-Alert ORANGE 'Disque C: chiffré par BitLocker : noter la clé de récupération (compte Microsoft) avant toute intervention.' }
if ($threatsN -gt 0) { Add-Alert ORANGE "$threatsN menace(s) dans lʼhistorique de lʼantivirus." 3 }
if ($rel -and $rel.SystemStabilityIndex -lt 5) { Add-Alert ORANGE "Indice de fiabilité Windows bas : $([math]::Round($rel.SystemStabilityIndex,1)) / 10." 5 }
if ($sb -eq $false) { Add-Alert ORANGE 'Démarrage sécurisé désactivé (à réactiver dans le BIOS).' }
if ($startupN -gt 15) { Add-Alert ORANGE "$startupN programmes se lancent au démarrage : le PC démarre plus lentement." }

$mining = 'NiceHash|PhoenixMiner|T-Rex|lolMiner|XMRig|NBMiner|TeamRedMiner|GMiner|Claymore|Awesome ?Miner|Cudo ?Miner|Kryptex|Ethminer|HiveOS|SRBMiner|BzMiner|minerstat'
$ocTools = 'Afterburner|Extreme Tuning|\bXTU\b|Ryzen Master|Precision X|ThrottleStop|RivaTuner'
$apps = @()
foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*') {
    $apps += @(Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | ForEach-Object { $_.DisplayName })
}
$folders = @()
foreach ($base in @("$env:ProgramFiles", "${env:ProgramFiles(x86)}", 'C:\') + @(Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue | ForEach-Object { "$($_.FullName)\AppData\Local"; "$($_.FullName)\AppData\Roaming"; "$($_.FullName)\Desktop"; "$($_.FullName)\Downloads" })) {
    if ($base -and (Test-Path $base)) { $folders += @(Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object Name) }
}
$procs = @(Get-Process -ErrorAction SilentlyContinue | ForEach-Object ProcessName)
$minHits = @(($apps + $folders + $procs) | Where-Object { $_ -match $mining } | Sort-Object -Unique)
$ocHits  = @(($apps + $folders) | Where-Object { $_ -match $ocTools } | Sort-Object -Unique)
Add-Table 'Traces de minage et dʼoverclocking' ([ordered]@{
    'Logiciels de minage'     = $(if ($minHits.Count) { $minHits -join ', ' } else { 'Aucun trouvé' })
    'Outils dʼoverclocking'   = $(if ($ocHits.Count) { $ocHits -join ', ' } else { 'Aucun trouvé' })
})
if ($minHits.Count) { Add-Alert ROUGE "Traces de MINAGE de cryptomonnaie : $($minHits -join ', '). La carte graphique a pu tourner à fond pendant des mois." 15 }
else { Add-Alert OK 'Aucune trace de logiciel de minage.' }
if ($ocHits.Count) { Add-Alert INFO "Outils dʼoverclocking installés ($($ocHits -join ', ')) : le PC a peut-être été overclocké." }

$badDev = @(Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.ConfigManagerErrorCode -and $_.ConfigManagerErrorCode -ne 0 } |
    ForEach-Object { [pscustomobject]@{ 'Périphérique' = $_.Name; 'Code erreur' = $_.ConfigManagerErrorCode } })
if ($badDev.Count) { Add-Grid 'Périphériques en erreur' $badDev; Add-Alert ORANGE "$($badDev.Count) périphérique(s) en erreur ou sans pilote." 3 }
else { Add-Alert OK 'Aucun périphérique en erreur.' }
$netRows = @(); try { $netRows = @(Get-NetAdapter -Physical -ErrorAction Stop | ForEach-Object { [pscustomobject]@{ 'Carte réseau' = $_.InterfaceDescription; 'État' = $_.Status; 'Vitesse' = $_.LinkSpeed } }) } catch {}
Add-Grid 'Réseau (Ethernet / Wi-Fi)' $netRows
$bt = @(); try { $bt = @(Get-PnpDevice -Class Bluetooth -PresentOnly -ErrorAction Stop) } catch {}
$snd = @(Get-CimInstance Win32_SoundDevice -ErrorAction SilentlyContinue | ForEach-Object Name)
Add-Table 'Autres périphériques' ([ordered]@{
    'Wi-Fi'           = $(if (@($netRows | Where-Object { $_.'Carte réseau' -match 'Wi-?Fi|Wireless|802\.11' }).Count) { 'Présent' } else { 'Absent ou non détecté' })
    'Bluetooth'       = $(if ($bt.Count) { 'Présent' } else { 'Absent ou non détecté' })
    'Audio'           = ($snd -join ', ')
    'Contrôleurs USB' = @(Get-CimInstance Win32_USBController -ErrorAction SilentlyContinue).Count
})

# ---------------------------------------------------------------- 14
Step 14 'Clé USB / disque externe : vraie capacité (facultatif)'
$extRes = $null
$toolLetter = $root.Substring(0, 1).ToUpper()
$usbNums = @(Get-Disk -ErrorAction SilentlyContinue | Where-Object { "$($_.BusType)" -eq 'USB' } | ForEach-Object { [int]$_.Number })
$extVols = @()
foreach ($v in @(Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and $_.Size -gt 0 })) {
    $L = "$($v.DriveLetter)".ToUpper()
    if ($L -eq $toolLetter -or $L -eq 'C') { continue }
    $isUsb = ("$($v.DriveType)" -eq 'Removable')
    if (-not $isUsb) { try { $isUsb = $usbNums -contains [int](Get-Partition -DriveLetter $L -ErrorAction Stop | Select-Object -First 1).DiskNumber } catch {} }
    if ($isUsb) { $extVols += $v }
}
if ($extVols.Count -eq 0) {
    Write-Host '   Aucune autre clé USB ni disque externe branché : étape sautée.' -ForegroundColor DarkGray
    Write-Host '   (Pour vérifier un disque acheté en ligne, branche-le en plus de cette clé et relance le diagnostic.)' -ForegroundColor DarkGray
} else {
    Write-Host '   Ce test vérifie quʼune clé ou un disque externe a vraiment la capacité annoncée (détecte les contrefaçons).'
    foreach ($v in $extVols) { Write-Host ("   {0}:  {1,-20} annoncé {2} Go, libre {3} Go, {4}" -f $v.DriveLetter, $v.FileSystemLabel, (GB $v.Size), (GB $v.SizeRemaining), $v.FileSystem) }
    $pick = (Read-Host '   Lettre du disque à tester (ex : E), ou Entrée pour passer').Trim().TrimEnd(':').ToUpper()
    $vol = $extVols | Where-Object { "$($_.DriveLetter)".ToUpper() -eq $pick } | Select-Object -First 1
    if ($vol) {
        Write-Host '   ATTENTION : sur un disque contrefait, ce test peut abîmer les fichiers déjà présents. Copie-les ailleurs avant.' -ForegroundColor Yellow
        $mode = Read-Host '   1 = rapide (écrit jusquʼà 100 Go, détecte la plupart des contrefaçons)   2 = complet (tout lʼespace libre)   Entrée = annuler'
        if ($mode -match '^[12]$') {
            $capCode = @'
using System;
using System.IO;
public static class CapCheck {
    static byte[] _base;
    public static void Init(int size) { _base = new byte[size]; new Random(1234).NextBytes(_base); }
    // remplit le bloc et y inscrit tous les 64 Ko un repère unique (fichier, bloc, position)
    public static void Stamp(byte[] buf, int file, int block) {
        Buffer.BlockCopy(_base, 0, buf, 0, _base.Length);
        for (int o = 0; o + 16 <= buf.Length; o += 65536) {
            BitConverter.GetBytes(0x44494147).CopyTo(buf, o);
            BitConverter.GetBytes(file).CopyTo(buf, o + 4);
            BitConverter.GetBytes(block).CopyTo(buf, o + 8);
            BitConverter.GetBytes(o).CopyTo(buf, o + 12);
        }
    }
    public static bool Same(byte[] a, int n, byte[] b) {
        if (n != b.Length) return false;
        for (int i = 0; i < n; i++) if (a[i] != b[i]) return false;
        return true;
    }
    public static int ReadFull(Stream s, byte[] b) {
        int t = 0;
        while (t < b.Length) { int r = s.Read(b, t, b.Length - t); if (r <= 0) break; t += r; }
        return t;
    }
}
'@
            try {
                if (-not ('CapCheck' -as [type])) { Add-Type -TypeDefinition $capCode -ErrorAction Stop }
                $L = "$($vol.DriveLetter)".ToUpper()
                $blk = 8MB; $perFile = 128          # fichiers de 1 Go
                [CapCheck]::Init($blk)
                $buf = New-Object byte[] $blk
                $usedBefore = [double]$vol.Size - [double]$vol.SizeRemaining
                $limit = [double]$vol.SizeRemaining - 256MB
                if ($mode -eq '1') { $limit = [math]::Min($limit, 100GB) }
                $files = New-Object System.Collections.Generic.List[object]
                $written = 0.0; $fi = 0; $stop = $false; $writeErr = $false
                Write-Host '   Écriture en cours (Échap pour arrêter et vérifier ce qui a déjà été écrit)...' -ForegroundColor DarkGray
                $sw = [Diagnostics.Stopwatch]::StartNew()
                while (-not $stop -and $written + $blk -le $limit) {
                    $fi++
                    $path = "${L}:\DIAGCAP_{0:D5}.bin" -f $fi
                    $nb = [int][math]::Min($perFile, [math]::Floor(($limit - $written) / $blk))
                    $fs = $null; $done = 0
                    try {
                        $fs = New-Object IO.FileStream($path, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None, 1MB, [IO.FileOptions]::WriteThrough)
                        for ($bi = 0; $bi -lt $nb; $bi++) {
                            [CapCheck]::Stamp($buf, $fi, $bi); $fs.Write($buf, 0, $blk); $written += $blk; $done++
                            if ($bi % 8 -eq 0) {
                                $sp = $written / 1MB / [math]::Max(1, $sw.Elapsed.TotalSeconds)
                                $rest = ($limit - $written) / 1MB / [math]::Max(1, $sp)
                                Write-Progress -Activity "Test de capacité ${L}:" -Status ("Écrit {0:N1} Go sur {1:N1} Go - {2:N0} Mo/s - reste environ {3:N0} min" -f ($written / 1GB), ($limit / 1GB), $sp, ($rest / 60)) -PercentComplete ([math]::Min(100, 100 * $written / $limit))
                                try { if ([Console]::KeyAvailable -and [Console]::ReadKey($true).Key -eq 'Escape') { $stop = $true; break } } catch {}
                            }
                        }
                    } catch { $writeErr = $true; $stop = $true }
                    finally { if ($fs) { try { $fs.Close() } catch {} } }
                    $files.Add([pscustomobject]@{ Path = $path; File = $fi; Blocks = $done })
                }
                $writeMBs2 = [int]($written / 1MB / [math]::Max(0.1, $sw.Elapsed.TotalSeconds))
                # vider le cache de Windows pour relire réellement le disque
                & fsutil volume dismount "${L}:" 2>&1 | Out-Null
                Start-Sleep -Seconds 3
                $exp = New-Object byte[] $blk; $rb = New-Object byte[] $blk
                $goodB = 0.0; $badB = 0.0; $firstBad = $null; $pos = 0.0
                $sw = [Diagnostics.Stopwatch]::StartNew()
                foreach ($f in $files) {
                    $fs = $null; $bi = 0
                    try {
                        $fs = New-Object IO.FileStream($f.Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read, 1MB, [IO.FileOptions]::SequentialScan)
                        for ($bi = 0; $bi -lt $f.Blocks; $bi++) {
                            $n = [CapCheck]::ReadFull($fs, $rb); [CapCheck]::Stamp($exp, $f.File, $bi)
                            if ([CapCheck]::Same($rb, $n, $exp)) { $goodB += $blk } else { $badB += $blk; if ($null -eq $firstBad) { $firstBad = $pos } }
                            $pos += $blk
                            if ($bi % 8 -eq 0) { Write-Progress -Activity "Test de capacité ${L}:" -Status ("Vérification {0:N1} Go sur {1:N1} Go" -f ($pos / 1GB), ($written / 1GB)) -PercentComplete ([math]::Min(100, 100 * $pos / [math]::Max(1, $written))) }
                        }
                    } catch {
                        $left = $f.Blocks - $bi; $badB += $left * $blk; if ($null -eq $firstBad) { $firstBad = $pos }; $pos += $left * $blk
                    } finally { if ($fs) { try { $fs.Close() } catch {} } }
                }
                $readMBs2 = [int]($pos / 1MB / [math]::Max(0.1, $sw.Elapsed.TotalSeconds))
                Write-Progress -Activity "Test de capacité ${L}:" -Completed
                foreach ($f in $files) { Remove-Item $f.Path -Force -ErrorAction SilentlyContinue }
                $announced = GB $vol.Size
                if ($badB -gt 0 -or $writeErr) {
                    $realGB = GB ($usedBefore + $(if ($null -ne $firstBad) { $firstBad } else { $written }))
                    $verdict = "CONTREFAÇON PROBABLE : capacité réelle dʼenviron $realGB Go au lieu des $announced Go annoncés. Les fichiers copiés au-delà seront perdus. Demande le remboursement."
                    $cls = 'r'
                } elseif ($written -ge [double]$vol.SizeRemaining - 1GB) {
                    $verdict = "CAPACITÉ AUTHENTIQUE : tout lʼespace libre ($(GB $written) Go) a été écrit et relu sans erreur."
                    $cls = 'g'
                } else {
                    $verdict = "Aucune anomalie sur les $(GB $written) Go testés (test partiel : une contrefaçon plus grande ne serait pas détectée, faire le test complet pour être sûr)."
                    $cls = 'o'
                }
                $extRes = [pscustomobject]@{ Letter = $L; Label = $vol.FileSystemLabel; Announced = $announced; Tested = (GB $written); Bad = (GB $badB); Write = $writeMBs2; Read = $readMBs2; Verdict = $verdict; Cls = $cls }
                Write-Host "   $verdict" -ForegroundColor (@{ g = 'Green'; o = 'Yellow'; r = 'Red' }[$cls])
                Write-Host "   Vitesse : écriture $writeMBs2 Mo/s, lecture $readMBs2 Mo/s"
            } catch { Write-Host "   Test de capacité impossible : $($_.Exception.Message)" -ForegroundColor Yellow }
        }
    }
}

# ---------------------------------------------------------------- 15
Step 15 'Contrôles manuels (écran, bruit, ports, état physique)'
$manual = [ordered]@{}
$doScreen = Read-Host 'Lancer le test de lʼécran en plein écran (pixels morts, taches) ? (O/N)'
if ($doScreen -match '^[oOyY]') {
    Write-Host '   Plein écran : cliquez ou appuyez sur une touche pour changer de couleur, Échap pour quitter.' -ForegroundColor Yellow
    Write-Host '   Regardez bien tout lʼécran à chaque couleur (points noirs, blancs ou colorés, taches, zones plus claires).' -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    try {
        Add-Type -AssemblyName System.Windows.Forms, System.Drawing
        $colors = @([Drawing.Color]::Black, [Drawing.Color]::White, [Drawing.Color]::Red, [Drawing.Color]::Lime, [Drawing.Color]::Blue, [Drawing.Color]::Gray)
        $script:ci = 0
        $f = New-Object Windows.Forms.Form
        $f.FormBorderStyle = 'None'; $f.WindowState = 'Maximized'; $f.TopMost = $true; $f.BackColor = $colors[0]; $f.KeyPreview = $true
        $next = { $script:ci++; if ($script:ci -ge $colors.Count) { $f.Close() } else { $f.BackColor = $colors[$script:ci] } }
        $f.Add_KeyDown({ if ($_.KeyCode -eq 'Escape') { $f.Close() } else { & $next } })
        $f.Add_MouseClick({ & $next })
        [Windows.Forms.Cursor]::Hide(); [void]$f.ShowDialog(); [Windows.Forms.Cursor]::Show()
    } catch { Write-Host '   Test écran impossible.' -ForegroundColor Yellow }
}
$questions = [ordered]@{
    'Écran sans pixel mort ni tache'                          = 'Écran : pixels morts ou taches signalés.'
    'Aucun bruit anormal (grésillement, ventilateur bruyant)' = 'Bruit anormal signalé pendant les tests.'
    'Ports USB testés et fonctionnels'                        = 'Port(s) USB défectueux signalé(s).'
    'État physique correct (pas de choc, poussière normale)'  = 'État physique douteux signalé.'
}
foreach ($q in $questions.Keys) {
    $a = Read-Host "   $q ? (O/N, Entrée = pas vérifié)"
    if ($a -match '^[oOyY]') { $manual[$q] = 'OUI' }
    elseif ($a -match '^[nN]') { $manual[$q] = 'NON'; Add-Alert ORANGE $questions[$q] 5 }
    else { $manual[$q] = 'Non vérifié' }
}
Add-Table 'Contrôles manuels' $manual

# =====================================================================
#  CALCUL DES NOTES
# =====================================================================
# Processeur : indice 1 cœur (base de données) x gain multi-cœurs MESURÉ
#   (100 = Ryzen 9 9950X / Core Ultra 9 285K : environ 17 fois un cœur seul)
$S = [double]$cpuInfo.ST
if ($scaling) { $M = Clamp ($S * $scaling / 17) }
else { $M = Clamp ($S * ($cores + 0.25 * ($threads - $cores)) * 0.9 / 17) }
$M = [math]::Round($M, 1)
# Carte graphique
$G = 0.0; $V = 0.0; $hasNvidia = $false; $hasDgpu = $false
if ($mainGpu) {
    $G = [double]$mainGpu.G
    if (-not $mainGpu.Igpu) { $V = [double]$mainGpu.V; $hasDgpu = $true }
    $hasNvidia = ($mainGpu.Vendor -eq 'NVIDIA')
}
$gpuName = $(if ($mainGpu) { $mainGpu.Name } else { 'aucune' })
# Mémoire vive
$R = [double]$ramTotal
$Ridx = Interp $R @(@(4, 8), @(8, 25), @(16, 55), @(32, 85), @(64, 100))
if ($channels -eq 1 -and $slots -ge 2) { $Ridx -= 10 }
if ($ramType -match 'DDR3|DDR2') { $Ridx -= 10 } elseif ($ramType -match 'DDR5') { $Ridx += 5 }
if ($ramErrors -gt 0) { $Ridx = 5 }
$Ridx = [math]::Round((Clamp $Ridx), 0)
# Stockage (disque où Windows est installé)
$isHdd = ($sysKind -like 'Disque dur*')
if ($isHdd) { $D = 15.0 }
elseif ($writeMBs) { $D = Interp $writeMBs @(@(100, 35), @(400, 60), @(800, 75), @(1500, 88), @(2500, 100)) }
elseif ($sysKind -eq 'NVMe') { $D = 80.0 } else { $D = 60.0 }
if ($sizeC -gt 0 -and $freeC / $sizeC -lt 0.1) { $D -= 15 }
elseif ($freeC -lt 50) { $D -= 10 }
if ($sizeC -gt 0 -and $sizeC -lt 400) { $D -= 5 }
if ($null -ne $sysWear -and $sysWear -ge 50) { $D -= 10 }
$D = [math]::Round((Clamp $D), 0)

# Score de puissance globale /100
$power = [int][math]::Round(0.40 * $G + 0.20 * $M + 0.15 * $S + 0.125 * $Ridx + 0.125 * $D)
$power = [int](Clamp $power)
$cat = $(if ($power -ge 75) { 'Très haut de gamme' } elseif ($power -ge 55) { 'Haut de gamme' } elseif ($power -ge 35) { 'Milieu de gamme' } elseif ($power -ge 20) { 'Entrée de gamme' } else { 'Basique (bureautique)' })
if ($hasDgpu -and $G -ge 20) { $cat = "PC gamer / création - $cat" } elseif (-not $hasDgpu) { $cat = "$cat - sans carte graphique dédiée" }
$health = [int](Clamp $health)

$comp = @{ S = $S; M = $M; G = $G; V = $V; R = $R; D = $D; Nvidia = $hasNvidia; Hdd = $isHdd }

# ---------------------------------------------------------------------
#  Note d'un usage /100
# ---------------------------------------------------------------------
function Score-Usage($u, $c) {
    $sw = 0.0; $sum = 0.0
    foreach ($k in $u.T.Keys) {
        $ratio = Clamp ([double]$c[$k] / [double]$u.T[$k]) 0 1
        $sum += [double]$u.W[$k] * $ratio; $sw += [double]$u.W[$k]
    }
    $s = 100.0 * $sum / $sw
    if ($u.C) { $cr = Clamp ([double]$c[$u.C] / [double]$u.T[$u.C]) 0 1; $s *= (0.4 + 0.6 * $cr) }   # le composant critique pèse plus lourd
    if ($u.Id -eq 9 -and -not $c.Nvidia) { $s *= 0.8 }     # IA : la plupart des outils sont faits pour NVIDIA (CUDA)
    if ($u.Id -ne 1) {                                     # un composant très en dessous du besoin empêche d'être "très bien"
        foreach ($k in $u.T.Keys) { if ([double]$c[$k] / [double]$u.T[$k] -lt 0.6) { $s = [math]::Min($s, 69) } }
    }
    if ($c.R -lt 7.5) { $s = [math]::Min($s, $(if ($u.Id -eq 1) { 60 } else { 35 })) }
    if ($c.Hdd) { $s = [math]::Min($s, $(if ($u.Id -eq 1) { 50 } else { 60 })) }
    [int][math]::Round($s)
}
$LABEL = @{ G = 'carte graphique'; V = 'mémoire vidéo'; S = 'processeur (1 cœur)'; M = 'processeur (multi-cœurs)'; R = 'RAM'; D = 'stockage' }
function Fmt-Val([string]$k, $v) { if ($k -eq 'V' -or $k -eq 'R') { "$([math]::Round([double]$v, 1)) Go" } else { "$([int][math]::Round([double]$v))/100" } }
function Limits($u, $c) {
    $l = @()
    foreach ($k in $u.T.Keys) {
        if ([double]$c[$k] / [double]$u.T[$k] -lt 0.9) { $l += "$($LABEL[$k]) $(Fmt-Val $k $c[$k]) (conseillé : $(Fmt-Val $k $u.T[$k]))" }
    }
    if ($u.Id -eq 9 -and -not $c.Nvidia) { $l += 'carte non NVIDIA (moins compatible avec les outils dʼIA)' }
    $l
}

# ---------------------------------------------------------------------
#  Plan d'amélioration pour un ou plusieurs usages
# ---------------------------------------------------------------------
function Get-Plan($usageList, $c) {
    $need = @{ G = 0.0; V = 0.0; S = 0.0; M = 0.0; R = 0.0; D = 0.0 }
    $pieceOf = @{ G = 'GPU'; V = 'GPU'; S = 'CPU'; M = 'CPU'; R = 'RAM'; D = 'DISK' }
    $deficit = @{ GPU = 0.0; CPU = 0.0; RAM = 0.0; DISK = 0.0 }
    foreach ($u in $usageList) {
        foreach ($k in $u.T.Keys) {
            $t = [double]$u.T[$k]; $ratio = [double]$c[$k] / $t
            if ($ratio -lt 0.9) {
                if ($t -gt $need[$k]) { $need[$k] = $t }
                $deficit[$pieceOf[$k]] += [double]$u.W[$k] * (1 - (Clamp $ratio 0 1))
            }
        }
    }
    $items = @()
    $c2 = $c.Clone()
    $aiWanted = @($usageList | Where-Object { $_.Id -eq 9 }).Count -gt 0

    # Carte graphique
    if ($need.G -gt 0 -or $need.V -gt 0) {
        if ($isLaptop) {
            $items += [pscustomobject]@{ Piece = 'Carte graphique'; Key = 'GPU'; D = $deficit.GPU; Short = 'GPU non remplaçable (portable)'
                Action = 'PC portable : la carte graphique est soudée et ne peut pas être changée. Seule solution : un boîtier eGPU (Thunderbolt / OCuLink), coûteux, ou un autre PC.' }
        } else {
            $ng = [math]::Max($need.G, $c.G); $nv = [math]::Max($need.V, $c.V)
            $sug = $GPU_SHOP | Where-Object { $_.G -ge $ng -and $_.V -ge $nv -and ($_.Nv -or -not $aiWanted) } | Select-Object -First 1
            if (-not $sug) { $sug = $GPU_SHOP[$GPU_SHOP.Count - 1] }
            $alt = $GPU_SHOP | Where-Object { $_.G -ge $ng -and $_.V -ge $nv -and $_.N -ne $sug.N -and ($_.Nv -or -not $aiWanted) } | Select-Object -First 1
            $c2.G = [math]::Max($c.G, $sug.G); $c2.V = [math]::Max($c.V, $sug.V); if ($sug.Nv) { $c2.Nvidia = $true }
            $txt = "Installer une $($sug.N)"
            if ($alt) { $txt += " (ou $($alt.N))" }
            $txt += ". Alimentation dʼau moins $($sug.W) W avec les câbles PCIe nécessaires ; vérifier la longueur de carte acceptée par le boîtier."
            $items += [pscustomobject]@{ Piece = 'Carte graphique'; Key = 'GPU'; D = $deficit.GPU; Short = $sug.N; Action = $txt }
        }
    }
    # Processeur
    if ($need.S -gt 0 -or $need.M -gt 0) {
        $ns = [math]::Max($need.S, $c.S) * 0.95; $nm = [math]::Max($need.M, $c.M) * 0.95
        if ($cpuInfo.Mobile -or $isLaptop) {
            $items += [pscustomobject]@{ Piece = 'Processeur'; Key = 'CPU'; D = $deficit.CPU; Short = 'CPU non remplaçable (portable)'
                Action = 'PC portable : le processeur est soudé. Pour plus de puissance de calcul, il faut un autre PC.' }
        } else {
            $sug = $null
            if ($cpuInfo.Socket -and $CPU_SHOP.ContainsKey($cpuInfo.Socket)) {
                $sug = $CPU_SHOP[$cpuInfo.Socket] | Where-Object { $_.S -ge $ns -and $_.M -ge $nm -and ($_.S -gt $c.S + 3 -or $_.M -gt $c.M + 3) } | Select-Object -First 1
            }
            if ($sug) {
                $c2.S = [math]::Max($c.S, $sug.S); $c2.M = [math]::Max($c.M, $sug.M)
                $items += [pscustomobject]@{ Piece = 'Processeur'; Key = 'CPU'; D = $deficit.CPU; Short = $sug.N
                    Action = "Remplacer le processeur par un $($sug.N) (même carte mère, support $($cpuInfo.Socket)). $($CPU_SOCKET_NOTE[$cpuInfo.Socket])" }
            } else {
                $pl = $PLATFORM_NEW | Where-Object { $_.S -ge $ns -and $_.M -ge $nm } | Select-Object -First 1
                if (-not $pl) { $pl = $PLATFORM_NEW[$PLATFORM_NEW.Count - 1] }
                $c2.S = [math]::Max($c.S, $pl.S); $c2.M = [math]::Max($c.M, $pl.M); $c2.R = [math]::Max($c.R, $pl.R)
                $items += [pscustomobject]@{ Piece = 'Processeur + carte mère'; Key = 'CPU'; D = $deficit.CPU; Short = 'nouvelle plateforme'
                    Action = "Le support actuel ($(if ($cpuInfo.Socket) { $cpuInfo.Socket } else { 'non identifié' })) nʼa pas de processeur assez puissant : changer de plateforme, $($pl.N). La carte graphique et les disques se gardent." }
            }
        }
    }
    # RAM
    if ($need.R -gt 0 -and $c2.R -lt $need.R) {
        $target = [math]::Max(16, [math]::Pow(2, [math]::Ceiling([math]::Log([math]::Max($need.R, 8)) / [math]::Log(2))))
        if ($ramSoldered) {
            $items += [pscustomobject]@{ Piece = 'Mémoire vive'; Key = 'RAM'; D = $deficit.RAM; Short = 'RAM soudée'
                Action = "RAM $ramType soudée sur la carte mère : impossible dʼen ajouter. Ce PC restera à $ramTotal Go." }
        } else {
            $type = $(if ($ramType -and $ramType -notlike 'LP*') { $ramType } else { 'DDR4/DDR5 (selon la carte mère)' })
            $fmt = $(if ($isLaptop) { 'SO-DIMM (format portable)' } else { 'DIMM' })
            $m0 = $mods | Select-Object -First 1
            $size0 = 0; if ($m0) { $size0 = GB $m0.Capacity }
            $free = [int]$slots - $mods.Count
            if ($m0 -and $free -ge $mods.Count -and ($ramTotal * 2) -ge $target -and ($ramTotal * 2) -le $target * 1.5) {
                $ref0 = ('' + $m0.PartNumber).Trim()
                $act = "Ajouter $($mods.Count) barrette(s) IDENTIQUE(S) : $($m0.Manufacturer) $ref0 ($size0 Go $type, $($m0.Speed) MT/s) -> $($ramTotal * 2) Go en double canal."
                $c2.R = $ramTotal * 2
            } else {
                $per = $target / 2
                $act = "Remplacer la RAM par un kit 2 x $per Go $type $fmt -> $target Go en double canal$(if ($m0) { " (vitesse $($m0.Speed) MT/s ou plus)" })."
                $c2.R = $target
            }
            $items += [pscustomobject]@{ Piece = 'Mémoire vive'; Key = 'RAM'; D = $deficit.RAM; Short = "$($c2.R) Go de RAM"; Action = $act }
        }
    }
    # Stockage
    if ($need.D -gt 0) {
        if ($c.Hdd) {
            $act = 'Remplacer le disque dur par un SSD NVMe de 1 à 2 To (ou un SSD SATA si le PC nʼa pas dʼemplacement M.2) et y réinstaller / cloner Windows.'
            $c2.Hdd = $false; $c2.D = 88
        } elseif ($sysKind -ne 'NVMe' -and $writeMBs -and $writeMBs -lt 700) {
            $act = 'Passer à un SSD NVMe PCIe 4.0 de 2 To (si un emplacement M.2 est libre sur la carte mère) : 3 à 10 fois plus rapide.'
            $c2.D = 92
        } else {
            $act = "Ajouter un 2e SSD NVMe de 2 To pour les projets et les jeux (actuellement $freeC Go libres sur C:)."
            $c2.D = [math]::Min(100, $c.D + 20)
        }
        $items += [pscustomobject]@{ Piece = 'Stockage'; Key = 'DISK'; D = $deficit.DISK; Short = 'SSD NVMe'; Action = $act }
    }
    [pscustomobject]@{ Items = @($items | Sort-Object D -Descending); C2 = $c2 }
}

# Notes de chaque usage + plan individuel
$usageRes = foreach ($u in $USAGES) {
    $sc = Score-Usage $u $comp
    $lv = Get-Level $sc
    $plan = $null; $after = $null
    if ($sc -lt 70) {
        $plan = Get-Plan @($u) $comp
        $after = Score-Usage $u $plan.C2
    }
    [pscustomobject]@{ U = $u; Score = $sc; Lv = $lv; Plan = $plan; After = $after; Sel = ($selected -contains $u.Id); Lim = @(Limits $u $comp) }
}

# Plan global : usages choisis (ou, à défaut, les usages "Correct" à portée de main)
$targets = @($usageRes | Where-Object { $_.Sel -and $_.Score -lt 70 } | ForEach-Object { $_.U })
if ($selected.Count -eq 0) { $targets = @($usageRes | Where-Object { $_.Score -ge 50 -and $_.Score -lt 70 } | ForEach-Object { $_.U }) }
$gPlan = $null
if ($targets.Count) { $gPlan = Get-Plan $targets $comp }

# Recommandations finales (matériel + réglages)
$upg = New-Object System.Collections.Generic.List[object]
function Add-Upg([int]$prio, [string]$piece, [string]$action, [string]$gain) { $upg.Add([pscustomobject]@{ P = $prio; Piece = $piece; Action = $action; Gain = $gain }) }
if ($gPlan) {
    $all = $gPlan.Items
    $single = $gPlan.C2
    for ($i = 0; $i -lt $all.Count; $i++) {
        $it = $all[$i]
        # Gain de cette pièce seule, sur tous les usages
        $cOne = $comp.Clone()
        switch ($it.Key) {
            'GPU'  { $cOne.G = $single.G; $cOne.V = $single.V; $cOne.Nvidia = $single.Nvidia }
            'CPU'  { $cOne.S = $single.S; $cOne.M = $single.M }
            'RAM'  { $cOne.R = $single.R }
            'DISK' { $cOne.D = $single.D; $cOne.Hdd = $single.Hdd }
        }
        $gains = @()
        foreach ($ur in $usageRes) {
            $na = Score-Usage $ur.U $cOne
            if ($na -ge $ur.Score + 5) { $gains += "$($ur.U.Nom) $($ur.Score) -> $na" }
        }
        $gainTxt = $(if ($gains.Count) { 'Notes : ' + ($gains -join ' ; ') } else { 'Gain limité seul : à combiner avec les autres améliorations.' })
        Add-Upg ([math]::Min(2, $i + 1)) $it.Piece $it.Action $gainTxt
    }
}
if ($xmpOff) { Add-Upg 1 'Réglage BIOS (gratuit)' "Activer le profil XMP/EXPO dans le BIOS pour que la RAM tourne à $($mods[0].Speed) MT/s (actuellement $($mods[0].ConfiguredClockSpeed))." 'Performance mémoire gratuite, en 2 minutes.' }
if (($gpuOnMain -and $null -ne $gpuDrop -and $gpuDrop -ge 20) -or ($gpuMaxT -and $gpuMaxT -ge 84) -or ($gpuMaxHot -and $gpuMaxHot -ge 100)) { Add-Upg 1 'Refroidissement carte graphique' 'Dépoussiérer la carte graphique et le boîtier, vérifier que ses ventilateurs tournent ; si la carte a plus de 3 ans, faire changer sa pâte et ses pads thermiques. Améliorer la ventilation du boîtier.' 'La carte garde toute sa puissance en jeu et dure plus longtemps.' }
if ($gpuRes -and ($gpuRes.lost -or $gpuRes.errors -gt 0)) { Add-Upg 1 'Carte graphique' 'Instabilité détectée : réinstaller proprement le pilote (DDU), retirer tout overclocking (MSI Afterburner), vérifier lʼalimentation et les câbles PCIe, puis refaire le test. Si les erreurs persistent : carte défectueuse.' 'Plus de plantages ni dʼartefacts en jeu.' }
if ($freqDrop -or ($maxT -and $maxT -gt 90)) { Add-Upg 1 'Refroidissement' 'Nettoyer la poussière, vérifier les ventilateurs / le ventirad et refaire la pâte thermique.' 'Le processeur ne sera plus bridé par la chaleur.' }
if ($badTot -gt 0) { Add-Upg 1 'Processeur' 'Calculs faux sous charge : remettre le BIOS par défaut (désactiver lʼoverclocking), vérifier le refroidissement, puis tester à nouveau.' 'Stabilité (plantages, fichiers corrompus).' }
if ($ramErrors -gt 0) { Add-Upg 1 'Mémoire vive' 'Erreurs RAM : désactiver XMP pour tester, puis tester chaque barrette seule avec MemTest86 et remplacer la barrette défectueuse.' 'Stabilité.' }
if ($channels -eq 1 -and $slots -ge 2 -and -not $ramSoldered -and -not ($gPlan -and @($gPlan.Items | Where-Object Key -eq 'RAM').Count)) {
    $m0 = $mods[0]; Add-Upg 2 'Mémoire vive' "Ajouter une barrette identique ($($m0.Manufacturer) $((''+$m0.PartNumber).Trim()), $(GB $m0.Capacity) Go) pour passer en double canal." 'Bande passante mémoire x2 (jeux et montage plus fluides avec une puce graphique intégrée).'
}
if ($c -and $sizeC -gt 0 -and $freeC / $sizeC -lt 0.1) { Add-Upg 1 'Stockage' "Libérer de la place sur C: ($freeC Go libres) ou ajouter un SSD." 'Un disque plein ralentit tout le PC.' }
foreach ($r in $nvmeRows) { if ($r.'Usure %' -ge 50) { Add-Upg 1 'Stockage' "SSD $($r.Disque) usé à $($r.'Usure %') % : sauvegarder les données et prévoir son remplacement." 'Éviter une perte de données.' } }
if ($battHealth -and $battHealth -lt 70) { Add-Upg 2 'Batterie' "Batterie à $battHealth % : la remplacer (référence exacte selon le modèle $($cs.Model))." 'Retrouver lʼautonomie dʼorigine.' }
try { if (((Get-Date) - $bios.ReleaseDate).TotalDays -gt 365) { Add-Upg 2 'BIOS' "BIOS du $biosDate : le mettre à jour depuis le site du fabricant ($($bb.Manufacturer) $($bb.Product))." 'Corrections de stabilité, de sécurité et de compatibilité.' } } catch {}
if (-not $winActive) { Add-Upg 1 'Windows' 'Windows non activé : installer une licence valide.' 'Mises à jour et personnalisation complètes.' }
foreach ($g in $gpus) {
    try { if (-not $g.Igpu -and $g.DriverDate -and ((Get-Date) - $g.DriverDate).TotalDays -gt 180) { Add-Upg 2 'Pilote graphique' "Pilote du $($g.DriverDate.ToString('dd/MM/yyyy')) : installer le dernier (NVIDIA App / AMD Adrenalin / Intel Arc Control)." 'Performances en jeu et compatibilité des logiciels de montage et dʼIA.' } } catch {}
}
if ($badDev.Count) { Add-Upg 2 'Pilotes' "Installer les pilotes manquants ($($badDev.Count) périphérique(s) en erreur) via Windows Update ou le site du fabricant." 'Tous les composants fonctionnels (Wi-Fi, audio, USB...).' }
if ($minHits.Count -or $threatsN -gt 0) { Add-Upg 2 'Windows' 'Réinitialiser Windows (Paramètres > Système > Récupération > Réinitialiser ce PC).' 'Repartir dʼun système propre.' }
if ($startupN -gt 15) { Add-Upg 3 'Windows' 'Désactiver les programmes inutiles au démarrage (Gestionnaire des tâches > Applications de démarrage).' 'Démarrage plus rapide.' }

# =====================================================================
#  VERDICT
# =====================================================================
$redHealth = @($alerts | Where-Object Level -eq 'ROUGE')
$orangeN = @($alerts | Where-Object Level -eq 'ORANGE').Count
$healthLv = $(if ($redHealth.Count -or $health -lt 50) { 'r' } elseif ($health -lt 80 -or $orangeN -gt 3) { 'o' } else { 'g' })
$healthTxt = @{ r = 'PROBLÈME DE SANTÉ DÉTECTÉ'; o = 'Bonne santé, quelques points à surveiller'; g = 'Excellente santé' }[$healthLv]

$selRes = @($usageRes | Where-Object Sel)
if ($selRes.Count) {
    $ko = @($selRes | Where-Object { $_.Score -lt 50 }); $mid = @($selRes | Where-Object { $_.Score -ge 50 -and $_.Score -lt 70 })
    if ($ko.Count) { $confCls = 'r'; $confTxt = 'NON CONFORME pour : ' + (($ko | ForEach-Object { $_.U.Nom }) -join ', ') }
    elseif ($mid.Count) { $confCls = 'o'; $confTxt = 'CONFORME AVEC RÉSERVES pour : ' + (($mid | ForEach-Object { $_.U.Nom }) -join ', ') }
    else { $confCls = 'g'; $confTxt = 'CONFORME pour tous tes usages : ' + (($selRes | ForEach-Object { $_.U.Nom }) -join ', ') }
} else {
    $good = @($usageRes | Where-Object { $_.Score -ge 70 } | ForEach-Object { $_.U.Nom })
    $bad  = @($usageRes | Where-Object { $_.Score -lt 50 } | ForEach-Object { $_.U.Nom })
    $confCls = $(if ($good.Count -ge 5) { 'g' } elseif ($good.Count -ge 2) { 'o' } else { 'r' })
    $confTxt = 'Idéal pour : ' + $(if ($good.Count) { $good -join ', ' } else { 'aucun usage exigeant' })
    if ($bad.Count) { $confTxt += '  |  Déconseillé pour : ' + ($bad -join ', ') }
}

Write-Host ''
Write-Host '=====================================================' -ForegroundColor Cyan
Write-Host "  $pcType - $cat" -ForegroundColor Cyan
Write-Host "  PUISSANCE : $power / 100    |    SANTÉ : $health / 100 ($healthTxt)" -ForegroundColor Cyan
Write-Host '=====================================================' -ForegroundColor Cyan
foreach ($ur in $usageRes) {
    $col = @{ g = 'Green'; o = 'Yellow'; r = 'Red' }[$ur.Lv.Cls]
    $star = $(if ($ur.Sel) { '*' } else { ' ' })
    $line = "{0} {1,-45} {2,3}/100  {3}" -f $star, $ur.U.Nom, $ur.Score, $ur.Lv.Txt
    if ($null -ne $ur.After -and $ur.After -gt $ur.Score) { $line += "  (-> $($ur.After) avec : $((@($ur.Plan.Items | ForEach-Object { $_.Short })) -join ' + '))" }
    Write-Host $line -ForegroundColor $col
}
Write-Host ''
Write-Host "  $confTxt" -ForegroundColor (@{ g = 'Green'; o = 'Yellow'; r = 'Red' }[$confCls])
if ($upg.Count) {
    Write-Host ''
    Write-Host '  AMÉLIORATIONS CONSEILLÉES :' -ForegroundColor Cyan
    foreach ($x in ($upg | Sort-Object P)) { Write-Host "  [$($x.P)] $($x.Piece) : $($x.Action)" }
}

# =====================================================================
#  RAPPORT HTML
# =====================================================================
$compRows = @()
$compRows += ,@('Processeur', "$cpuName ($cores cœurs / $threads threads)", [int][math]::Round(0.4 * $S + 0.6 * $M), "1 cœur : $([int]$S)/100 - multi-cœurs : $([int]$M)/100$(if ($scaling) { " (gain mesuré x$scaling)" })$(if (-not $cpuInfo.Known) { ' - estimation' })", '100 = Ryzen 9 9950X / Core Ultra 9 285K')
$compRows += ,@('Carte graphique', "$gpuName$(if ($hasDgpu) { " - $V Go" } else { ' (intégrée)' })", [int]$G, "$(if ($gpuScore -and $gpuOnMain) { "Mesurée : $gpuScore G ops/s, " })$(if ($gpuRes -and $gpuRes.ok) { "stable ($($gpuRes.errors) erreur), " })$(if ($gpuMaxT) { "$gpuMaxT C max, " })encodage AV1 matériel : $(if ($mainGpu -and $mainGpu.Av1) { 'oui' } else { 'non' })", '100 = RTX 5090 ; 40 = bonne carte 1440p ; 20 = carte 1080p')
$compRows += ,@('Mémoire vive', "$ramTotal Go $ramType, $channels canal(aux)$(if ($ramSoldered) { ', soudée' })", [int]$Ridx, $(if ($memBw) { "Bande passante mesurée : $memBw Go/s" } else { '' }), '100 = 64 Go double canal ; 85 = 32 Go ; 55 = 16 Go')
$compRows += ,@('Stockage', "$(if ($sysDisk) { $sysDisk.FriendlyName } else { 'Disque C:' }) - $sysKind", [int]$D, "Écriture $writeMBs Mo/s$(if ($seqRead) { ", lecture $([int]$seqRead) Mo/s" }), $freeC Go libres$(if ($null -ne $sysWear) { ", usure $sysWear %" })", '100 = SSD NVMe rapide (> 2 500 Mo/s) avec de la place')
$h = "<table><tr><th>Composant</th><th>Modèle</th><th style='min-width:150px'>Note</th><th>Détail</th><th>Référence</th></tr>"
foreach ($r in $compRows) { $h += "<tr><td><b>$(Enc $r[0])</b></td><td>$(Enc $r[1])</td><td>$(Bar $r[2])</td><td>$(Enc $r[3])</td><td class='small'>$(Enc $r[4])</td></tr>" }
$compHtml = $h + '</table>'

$h = "<table><tr><th>Usage</th><th style='min-width:150px'>Note</th><th>Verdict</th><th>Pour lʼaméliorer</th></tr>"
foreach ($ur in $usageRes) {
    $todo = ''
    if ($ur.Score -lt 70) {
        if ($ur.Lim.Count) { $todo = "<div class='small'>Limité par : $(Enc ($ur.Lim -join ' ; '))</div>" }
        if ($ur.Plan -and $ur.Plan.Items.Count) {
            $todo += '<ul>' + (($ur.Plan.Items | ForEach-Object { "<li>$(Enc $_.Short)</li>" }) -join '') + '</ul>'
            if ($ur.After -gt $ur.Score) { $todo += "<b>Note estimée après : $($ur.After)/100 ($((Get-Level $ur.After).Txt))</b>" }
        }
    } else { $todo = '<span class="small">Rien à faire.</span>' }
    $name = Enc $ur.U.Nom; if ($ur.Sel) { $name = "&#11088; <b>$name</b>" }
    $h += "<tr class='u$($ur.Lv.Cls)'><td>$name</td><td>$(Bar $ur.Score)</td><td>$($ur.Lv.Ic) $($ur.Lv.Txt)</td><td>$todo</td></tr>"
}
$usageHtml = $h + '</table>'

$upgHtml = ''
if ($upg.Count -eq 0) { $upgHtml = '<p>Aucune amélioration nécessaire.</p>' }
else {
    $prioTxt = @{ 1 = '<b style="color:#c62828">1 - En premier</b>'; 2 = '<b style="color:#b26a00">2 - Conseillé</b>'; 3 = '<b style="color:#2e7d32">3 - Plus tard</b>' }
    $upgHtml = "<table><tr><th>Priorité</th><th>Pièce</th><th>Quoi faire</th><th>Ce que ça apporte</th></tr>"
    foreach ($x in ($upg | Sort-Object P)) { $upgHtml += "<tr><td>$($prioTxt[$x.P])</td><td><b>$(Enc $x.Piece)</b></td><td>$(Enc $x.Action)</td><td>$(Enc $x.Gain)</td></tr>" }
    $upgHtml += '</table>'
    if ($gPlan -and $gPlan.Items.Count) {
        $after = @(); foreach ($u in $targets) { $after += "$($u.Nom) : $(Score-Usage $u $gPlan.C2)/100" }
        $upgHtml += "<p><b>Avec toutes les améliorations matérielles ci-dessus :</b> $(Enc ($after -join ' ; '))</p>"
    }
}

$alertHtml = '<ul>'
foreach ($a in ($alerts | Sort-Object { @{ ROUGE = 0; ORANGE = 1; INFO = 2; OK = 3 }[$_.Level] })) { $alertHtml += "<li class='$($a.Level)'><b>$($a.Level)</b> - $(Enc $a.Text)</li>" }
$alertHtml += '</ul>'

$html = @"
<!DOCTYPE html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Diagnostic PC</title>
<style>
:root{--bg:#f4f5f7;--card:#fff;--fg:#1d2228;--mut:#5f6b76;--line:#dde1e6;--g:#2e7d32;--o:#ef8c00;--r:#c62828}
@media (prefers-color-scheme:dark){:root{--bg:#15181c;--card:#1f242a;--fg:#e8ebee;--mut:#9aa5b0;--line:#323941}}
body{font-family:Segoe UI,Arial,sans-serif;max-width:1050px;margin:20px auto;padding:0 16px;background:var(--bg);color:var(--fg);line-height:1.45}
h1{margin:0 0 4px}h2{margin-top:34px;border-bottom:2px solid var(--line);padding-bottom:4px}h3{margin-top:22px}
table{border-collapse:collapse;width:100%;background:var(--card);font-size:14px}th,td{border:1px solid var(--line);padding:7px 9px;text-align:left;vertical-align:top}
th{background:rgba(127,127,127,.08)}.grid th{white-space:nowrap}.scroll{overflow-x:auto}
pre{background:var(--card);border:1px solid var(--line);padding:10px;overflow:auto}
.small{color:var(--mut);font-size:13px}ul{margin:6px 0;padding-left:20px}
.banner{padding:14px 18px;border-radius:10px;color:#fff;font-size:18px;font-weight:600;margin:10px 0}
.banner.g{background:var(--g)}.banner.o{background:var(--o)}.banner.r{background:var(--r)}
.scores{display:flex;gap:14px;flex-wrap:wrap;margin:14px 0}
.big{flex:1;min-width:200px;background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px 18px}
.big .n{font-size:44px;font-weight:700}.big .l{color:var(--mut)}
.bar{background:rgba(127,127,127,.2);border-radius:4px;height:10px;width:100%;margin-bottom:4px}.bar div{height:10px;border-radius:4px}
tr.ug td:first-child{border-left:5px solid var(--g)}tr.uo td:first-child{border-left:5px solid var(--o)}tr.ur td:first-child{border-left:5px solid var(--r)}
li.ROUGE{color:var(--r)}li.ORANGE{color:#b26a00}li.OK{color:var(--g)}li.INFO{color:var(--mut)}
details{margin-top:24px}summary{cursor:pointer;font-size:20px;font-weight:600}
</style></head><body>
<h1>Diagnostic PC</h1>
<div class="small">$(Enc $pcType) - $(Enc $cs.Manufacturer) $(Enc $cs.Model) - testé le $(Get-Date -Format 'dd/MM/yyyy à HH:mm') - outil v$VERSION</div>
<div class="scores">
 <div class="big"><div class="l">Puissance globale</div><div class="n">$power<span style="font-size:20px">/100</span></div><div>$(Bar $power)</div><div><b>$(Enc $cat)</b></div></div>
 <div class="big"><div class="l">Santé / fiabilité</div><div class="n">$health<span style="font-size:20px">/100</span></div><div>$(Bar $health)</div><div><b>$(Enc $healthTxt)</b></div></div>
</div>
<div class="banner $confCls">$(Enc $confTxt)</div>
$(if ($healthLv -eq 'r') { "<div class='banner r'>Problème de santé : $(Enc (($redHealth | ForEach-Object { $_.Text }) -join ' | '))</div>" })
<h2>Ce que ce PC peut faire</h2>
<p class="small">Note par usage : 85+ excellent, 70+ très bien, 50+ correct, 30+ faible, en dessous insuffisant. $(if ($selected.Count) { '&#11088; = usages que tu as choisis.' })</p>
$usageHtml
<h2>Notes par composant</h2>
$compHtml
<h2>Améliorations conseillées</h2>
$upgHtml
$(if ($extRes) { "<h2>Clé / disque externe testé ($(Enc $extRes.Letter): $(Enc $extRes.Label))</h2><div class='banner $($extRes.Cls)'>$(Enc $extRes.Verdict)</div><p class='small'>Annoncé : $($extRes.Announced) Go - testé : $($extRes.Tested) Go - zones défectueuses : $($extRes.Bad) Go - écriture $($extRes.Write) Mo/s, lecture $($extRes.Read) Mo/s</p>" })
<h2>Santé : points relevés</h2>
$alertHtml
<details><summary>Détails techniques</summary>
$($sections -join "`n")
</details>
<h2>À compléter à la main</h2><ul>
$(if (-not ($gpuRes -and $gpuRes.ok)) { '<li>Carte graphique : le test intégré nʼa pas pu se faire ; lancer OCCT (dossier OCCT), test « 3D Adaptive » 10 min, vérifier 0 erreur et GPU &lt; 85 °C.</li>' } else { '<li>Carte graphique : pour un test de stabilité plus long (30 min), OCCT « 3D Adaptive ».</li>' })
<li>RAM : pour un test complet, MemTest86 sur clé USB (1 à 2 h).</li>
<li>Ports USB, Wi-Fi / Ethernet, prises audio.</li></ul>
<p class="small">Les indices de performance sont des ordres de grandeur issus de moyennes publiques (jeu 1440p, rendu, encodage) et du benchmark intégré. $(if ($lhmCpuOk) { 'Températures lues par LibreHardwareMonitor sur les capteurs du processeur et de la carte graphique.' } else { 'Sans LibreHardwareMonitor, la température du processeur vient du capteur ACPI (indicatif).' }) La puissance mesurée de la carte graphique (G ops/s) sert de référence pour comparer des PC entre eux.</p>
</body></html>
"@
$html | Out-File -FilePath $reportPath -Encoding UTF8

# Résumé texte
$txtPath = [IO.Path]::ChangeExtension($reportPath, '.txt')
$sum = @("DIAGNOSTIC PC - $(Get-Date -Format 'dd/MM/yyyy HH:mm') - outil v$VERSION",
         "$pcType | $($cs.Manufacturer) $($cs.Model)",
         "$cpuName | $gpuName | $ramTotal Go $ramType | $sysKind",
         '', "PUISSANCE : $power / 100 ($cat)", "SANTÉ : $health / 100 ($healthTxt)", "VERDICT : $confTxt", '',
         'COMPOSANTS :')
foreach ($r in $compRows) { $sum += " - $($r[0]) : $($r[2])/100 - $($r[1]) - $($r[3])" }
$sum += ''; $sum += 'USAGES :'
foreach ($ur in $usageRes) {
    $line = " $(if ($ur.Sel) { '*' } else { '-' }) $($ur.U.Nom) : $($ur.Score)/100 ($($ur.Lv.Txt))"
    if ($ur.Lim.Count) { $line += " | limité par : $($ur.Lim -join ' ; ')" }
    if ($null -ne $ur.After -and $ur.After -gt $ur.Score) { $line += " | avec $((@($ur.Plan.Items | ForEach-Object { $_.Short })) -join ' + ') : $($ur.After)/100" }
    $sum += $line
}
$sum += ''; $sum += "TEST CARTE GRAPHIQUE : $(if ($gpuRes) { "$($gpuRes.renderer) | $gpuScore G ops/s | chute $gpuDrop % | erreurs $($gpuRes.errors)/$($gpuRes.checks) | temp. max $gpuMaxT C | utilisation $([int]$gpuUtil) %" } else { 'non réalisé' })"
$sum += "TEST PROCESSEUR : 1 cœur $mono pts | multi $multi pts | gain x$scaling | temp. max $maxT C | calculs faux $badTot"
if ($extRes) { $sum += "DISQUE EXTERNE $($extRes.Letter): : $($extRes.Verdict) (écriture $($extRes.Write) Mo/s, lecture $($extRes.Read) Mo/s)" }
$sum += ''; $sum += 'POINTS RELEVÉS :'
foreach ($a in ($alerts | Sort-Object { @{ ROUGE = 0; ORANGE = 1; INFO = 2; OK = 3 }[$_.Level] })) { $sum += " [$($a.Level)] $($a.Text)" }
$sum += ''; $sum += 'AMÉLIORATIONS CONSEILLÉES :'
foreach ($x in ($upg | Sort-Object P)) { $sum += " [Priorité $($x.P)] $($x.Piece) : $($x.Action) => $($x.Gain)" }
$sum | Out-File -FilePath $txtPath -Encoding UTF8

Write-Host ''
Write-Host "Rapport enregistré : $reportPath"
Write-Host "Résumé texte (à envoyer à Claude) : $txtPath"
Start-Process $reportPath
if ($lhm) { try { $lhm.Close() } catch {} }

$occt = Get-ChildItem (Join-Path $root 'OCCT') -Recurse -Filter '*.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($occt) {
    $go = Read-Host 'Lancer OCCT pour tester la carte graphique ? (O/N)'
    if ($go -match '^[oOyY]') { Start-Process $occt.FullName }
}
