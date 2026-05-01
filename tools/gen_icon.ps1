Add-Type -AssemblyName System.Drawing

# wolwo icon — dark, minimal, distinctive.
#
# Concept: a dark obsidian canvas with a single radial "moonrise" — a soft
# warm-amber gradient orb cresting a thin horizon line. The orb is partially
# clipped by the horizon so it reads as a sun/moon emerging from below. One
# strong accent color (amber #F5B062) on near-black (#0A0A10) gives the icon
# a confident, premium look that stands out on any home screen.
#
# Why this works:
#   - Dark theme: holds up on light *and* dark home screens; OLED-friendly
#   - One shape, one accent: instantly recognizable at 48dp
#   - Negative space below the horizon hints at "wallpaper" (a scene you'd
#     actually want behind your apps)

$size = 1024

$bgTop    = [System.Drawing.Color]::FromArgb(255,  16,  17,  24)   # near-black w/ cool tint
$bgBottom = [System.Drawing.Color]::FromArgb(255,   8,   9,  14)   # deeper at the floor
$accent     = [System.Drawing.Color]::FromArgb(255, 143, 168, 255) # cool periwinkle
$accentSoft = [System.Drawing.Color]::FromArgb(120, 143, 168, 255) # halo
$accentDim  = [System.Drawing.Color]::FromArgb( 40, 143, 168, 255) # outer halo
$ink        = [System.Drawing.Color]::FromArgb(255, 143, 168, 255)
$inkSoft    = [System.Drawing.Color]::FromArgb(110, 143, 168, 255)

function New-Bitmap($w, $h) {
    return New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}
function New-Graphics($bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    return $g
}
function New-RoundedRectPath($x, $y, $w, $h, $r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc($x,           $y,           $r*2, $r*2, 180, 90)
    $p.AddArc($x+$w-$r*2,   $y,           $r*2, $r*2, 270, 90)
    $p.AddArc($x+$w-$r*2,   $y+$h-$r*2,   $r*2, $r*2, 0,   90)
    $p.AddArc($x,           $y+$h-$r*2,   $r*2, $r*2, 90,  90)
    $p.CloseFigure()
    return $p
}

# Vertical near-black gradient — subtle, just enough to feel sculpted.
function New-BgBrush($x, $y, $w, $h) {
    $rect = New-Object System.Drawing.RectangleF([single]$x, [single]$y, [single]$w, [single]$h)
    return New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect, $bgTop, $bgBottom,
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
    )
}

function Render-Scene($g, $size, $drawCanvas) {
    if ($drawCanvas) {
        $canvas = New-RoundedRectPath 0 0 $size $size 230
        $bgBrush = New-BgBrush 0 0 $size $size
        $g.FillPath($bgBrush, $canvas)
        $bgBrush.Dispose()
        $g.SetClip($canvas)
    }

    # Geometry: horizon at 62% height (upper-third sky, lower-third ground).
    $horizonY = [int]($size * 0.62)
    $sunR     = [int]($size * 0.22)
    $sunCx    = $size / 2
    $sunCy    = $horizonY  # disc center sits ON the horizon → half above, half clipped

    # ── Outer halo (very soft, large) ─────────────────────────────────
    $haloR = [int]($size * 0.40)
    $haloRect = New-Object System.Drawing.RectangleF(
        [single]($sunCx - $haloR), [single]($sunCy - $haloR),
        [single]($haloR * 2), [single]($haloR * 2)
    )
    # Clip the halo to the sky region so it doesn't bleed below the horizon.
    $skyClip = New-Object System.Drawing.Drawing2D.GraphicsPath
    $skyClip.AddRectangle((New-Object System.Drawing.RectangleF(
        [single]0, [single]0, [single]$size, [single]$horizonY
    )))
    $g.SetClip($skyClip, [System.Drawing.Drawing2D.CombineMode]::Intersect)

    $haloPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $haloPath.AddEllipse($haloRect)
    $haloBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($haloPath)
    $haloBrush.CenterColor = $accentSoft
    $haloBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 143, 168, 255))
    $g.FillPath($haloBrush, $haloPath)
    $haloBrush.Dispose()
    $haloPath.Dispose()

    # ── Sun disc itself — solid amber, crisp edge ────────────────────
    $sunBrush = New-Object System.Drawing.SolidBrush($accent)
    $g.FillEllipse(
        $sunBrush,
        [single]($sunCx - $sunR), [single]($sunCy - $sunR),
        [single]($sunR*2), [single]($sunR*2)
    )
    $sunBrush.Dispose()

    # Reset the clip so we can draw the horizon line across full width.
    if ($drawCanvas) {
        $canvasClip = New-RoundedRectPath 0 0 $size $size 230
        $g.SetClip($canvasClip)
    } else {
        $g.ResetClip()
    }

    # ── Horizon — single thin amber line, full-width with soft caps ──
    $horizonPen = New-Object System.Drawing.Pen($ink, [single]([Math]::Max(6, $size * 0.014)))
    $horizonPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $horizonPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $pad = [int]($size * 0.10)
    $g.DrawLine($horizonPen,
        [single]$pad, [single]$horizonY,
        [single]($size - $pad), [single]$horizonY)
    $horizonPen.Dispose()

    # Two faint "ground" lines below — implied terrain, depth without commitment.
    $groundPen = New-Object System.Drawing.Pen($inkSoft, [single]([Math]::Max(3, $size * 0.006)))
    $groundPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $groundPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($groundPen,
        [single]([int]($size * 0.20)), [single]([int]($size * 0.74)),
        [single]($size - [int]($size * 0.20)), [single]([int]($size * 0.74)))
    $g.DrawLine($groundPen,
        [single]([int]($size * 0.32)), [single]([int]($size * 0.84)),
        [single]($size - [int]($size * 0.32)), [single]([int]($size * 0.84)))
    $groundPen.Dispose()

    if ($drawCanvas) { $g.ResetClip() }
}

# ----- Master icon (1024 with rounded canvas) -----
$bmp = New-Bitmap $size $size
$g = New-Graphics $bmp
Render-Scene $g $size $true
$g.Dispose()
$bmp.Save("C:\repos\wolwo\assets\launcher\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# ----- Adaptive foreground (transparent bg, scene inset for safe zone) -----
# Android adaptive icons clip to ~66% of the canvas. Inset the scene so the
# horizon and disc remain whole inside any mask shape.
$fg = New-Bitmap $size $size
$fgG = New-Graphics $fg
$inner = [int]($size * 0.70)
$inset = [int](($size - $inner) / 2)
$fgG.TranslateTransform([single]$inset, [single]$inset)
$fgG.ScaleTransform([single]($inner / $size), [single]($inner / $size))
Render-Scene $fgG $size $false
$fgG.Dispose()
$fg.Save("C:\repos\wolwo\assets\launcher\foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)
$fg.Dispose()

# ----- Adaptive background — flat near-black gradient -----
$bg = New-Bitmap $size $size
$bgG = New-Graphics $bg
$br = New-BgBrush 0 0 $size $size
$bgG.FillRectangle($br, 0, 0, $size, $size)
$br.Dispose()
$bgG.Dispose()
$bg.Save("C:\repos\wolwo\assets\launcher\background.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bg.Dispose()

# ----- Monochrome (Android 13+ themed icons) — same scene in pure white -----
$mono = New-Bitmap $size $size
$monoG = New-Graphics $mono
$inner2 = [int]($size * 0.70)
$inset2 = [int](($size - $inner2) / 2)
$monoG.TranslateTransform([single]$inset2, [single]$inset2)
$monoG.ScaleTransform([single]($inner2 / $size), [single]($inner2 / $size))

$white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
$whiteSoft = [System.Drawing.Color]::FromArgb(110, 255, 255, 255)
$horizonY = [int]($size * 0.62)
$sunR  = [int]($size * 0.22)
$sunCx = $size / 2
$sunCy = $horizonY

$skyClip = New-Object System.Drawing.Drawing2D.GraphicsPath
$skyClip.AddRectangle((New-Object System.Drawing.RectangleF(
    [single]0, [single]0, [single]$size, [single]$horizonY
)))
$monoG.SetClip($skyClip)
$monoG.FillEllipse(
    (New-Object System.Drawing.SolidBrush($white)),
    [single]($sunCx - $sunR), [single]($sunCy - $sunR),
    [single]($sunR*2), [single]($sunR*2)
)
$monoG.ResetClip()

$horizonPen = New-Object System.Drawing.Pen($white, [single]([Math]::Max(6, $size * 0.014)))
$horizonPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$horizonPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
$monoG.DrawLine($horizonPen,
    [single]([int]($size * 0.10)), [single]$horizonY,
    [single]($size - [int]($size * 0.10)), [single]$horizonY)

$groundPen = New-Object System.Drawing.Pen($whiteSoft, [single]([Math]::Max(3, $size * 0.006)))
$groundPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$groundPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
$monoG.DrawLine($groundPen,
    [single]([int]($size * 0.20)), [single]([int]($size * 0.74)),
    [single]($size - [int]($size * 0.20)), [single]([int]($size * 0.74)))
$monoG.DrawLine($groundPen,
    [single]([int]($size * 0.32)), [single]([int]($size * 0.84)),
    [single]($size - [int]($size * 0.32)), [single]([int]($size * 0.84)))

$monoG.Dispose()
$mono.Save("C:\repos\wolwo\assets\launcher\monochrome.png", [System.Drawing.Imaging.ImageFormat]::Png)
$mono.Dispose()

Write-Host "Generated icon set."
Get-ChildItem C:\repos\wolwo\assets\launcher\*.png | Format-Table Name, Length
