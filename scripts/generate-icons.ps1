Add-Type -AssemblyName System.Drawing

$resources = Join-Path (Join-Path $PSScriptRoot '..') 'resources'
$resources = [System.IO.Path]::GetFullPath($resources)

$c1 = [System.Drawing.ColorTranslator]::FromHtml('#6366f1')
$c2 = [System.Drawing.ColorTranslator]::FromHtml('#8b5cf6')
$green = [System.Drawing.ColorTranslator]::FromHtml('#10b981')
$lineColor = [System.Drawing.Color]::FromArgb(64, $c1.R, $c1.G, $c1.B)
$cardWhite = [System.Drawing.Color]::FromArgb(250, 255, 255, 255)

function New-Graphics($bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    return $g
}

function Add-RoundedRect($path, $x, $y, $w, $h, $r) {
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
}

function Draw-LedgerCard($g) {
    # card 520x406 at (252,309), scale 2.03125 of the original 256x200 design
    $x = 252.0; $y = 309.0; $w = 520.0; $h = 406.0; $r = 32.0
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    Add-RoundedRect $path $x $y $w $h $r
    $cardBrush = New-Object System.Drawing.SolidBrush $cardWhite
    $g.FillPath($cardBrush, $path)
    $cardBrush.Dispose(); $path.Dispose()

    $lineBrush = New-Object System.Drawing.SolidBrush $lineColor
    $g.FillRectangle($lineBrush, 252.0, 390.25, 520.0, 8.125)
    $g.FillRectangle($lineBrush, 252.0, 471.50, 520.0, 8.125)
    $g.FillRectangle($lineBrush, 252.0, 552.75, 520.0, 8.125)
    $lineBrush.Dispose()

    $cx = 690.75; $cy = 650.25; $rr = 56.875
    $greenBrush = New-Object System.Drawing.SolidBrush $green
    $g.FillEllipse($greenBrush, $cx - $rr, $cy - $rr, $rr * 2, $rr * 2)
    $greenBrush.Dispose()

    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), 10.0
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $points = [System.Drawing.PointF[]]@(
        (New-Object System.Drawing.PointF 670.4, 650.25),
        (New-Object System.Drawing.PointF 686.7, 666.5),
        (New-Object System.Drawing.PointF 715.1, 634.0)
    )
    $g.DrawLines($pen, $points)
    $pen.Dispose()
}

function Fill-Gradient($g) {
    $rect = New-Object System.Drawing.Rectangle 0, 0, 1024, 1024
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 45.0
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
}

# 1. background: full-bleed gradient
$bmp = New-Object System.Drawing.Bitmap 1024, 1024
$g = New-Graphics $bmp
Fill-Gradient $g
$g.Dispose()
$bmp.Save((Join-Path $resources 'icon-background.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 2. foreground: transparent, only the card (inside 66% safe zone)
$bmp = New-Object System.Drawing.Bitmap 1024, 1024
$g = New-Graphics $bmp
Draw-LedgerCard $g
$g.Dispose()
$bmp.Save((Join-Path $resources 'icon-foreground.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# 3. legacy icon: full square gradient + card
$bmp = New-Object System.Drawing.Bitmap 1024, 1024
$g = New-Graphics $bmp
Fill-Gradient $g
Draw-LedgerCard $g
$g.Dispose()
$bmp.Save((Join-Path $resources 'icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Output 'icons generated: icon.png, icon-background.png, icon-foreground.png'
