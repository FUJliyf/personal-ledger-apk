Add-Type -AssemblyName System.Drawing

$root = Join-Path (Join-Path $PSScriptRoot '..') ''
$root = [System.IO.Path]::GetFullPath($root)
$resources = Join-Path $root 'resources'
$out = Join-Path $root 'native-icons'

$full = [System.Drawing.Image]::FromFile((Join-Path $resources 'icon.png'))
$bg = [System.Drawing.Image]::FromFile((Join-Path $resources 'icon-background.png'))
$fg = [System.Drawing.Image]::FromFile((Join-Path $resources 'icon-foreground.png'))

function New-Graphics($bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return $g
}

function New-Square($src, $size) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = New-Graphics $bmp
    $g.DrawImage($src, 0, 0, $size, $size)
    $g.Dispose()
    return $bmp
}

function New-Circle($src, $size) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = New-Graphics $bmp
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(0, 0, $size, $size)
    $g.SetClip($path)
    $g.DrawImage($src, 0, 0, $size, $size)
    $g.Dispose(); $path.Dispose()
    return $bmp
}

$densities = [ordered]@{
    'mipmap-mdpi'    = @{ legacy = 48;  adaptive = 108 }
    'mipmap-hdpi'    = @{ legacy = 72;  adaptive = 162 }
    'mipmap-xhdpi'   = @{ legacy = 96;  adaptive = 216 }
    'mipmap-xxhdpi'  = @{ legacy = 144; adaptive = 324 }
    'mipmap-xxxhdpi' = @{ legacy = 192; adaptive = 432 }
}

foreach ($entry in $densities.GetEnumerator()) {
    $dir = Join-Path $out $entry.Key
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $ls = $entry.Value.legacy
    $ad = $entry.Value.adaptive

    $img = New-Square $full $ls
    $img.Save((Join-Path $dir 'ic_launcher.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()

    $img = New-Circle $full $ls
    $img.Save((Join-Path $dir 'ic_launcher_round.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()

    $img = New-Square $bg $ad
    $img.Save((Join-Path $dir 'ic_launcher_background.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()

    $img = New-Square $fg $ad
    $img.Save((Join-Path $dir 'ic_launcher_foreground.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
}

$full.Dispose(); $bg.Dispose(); $fg.Dispose()

$any = Join-Path $out 'mipmap-anydpi-v26'
New-Item -ItemType Directory -Force -Path $any | Out-Null
$xml = @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'@
[System.IO.File]::WriteAllText((Join-Path $any 'ic_launcher.xml'), $xml, (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText((Join-Path $any 'ic_launcher_round.xml'), $xml, (New-Object System.Text.UTF8Encoding($false)))

Write-Output 'android native icons generated into native-icons/'
