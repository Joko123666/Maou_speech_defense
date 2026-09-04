param(
    [string]$GeneratedDirectory = "C:\Users\USER\.codex\generated_images\01a03d6d-4ce4-7d92-a159-aa2c60eac938",
    [string]$StageDirectory = "assets\graphics\style_refresh_v019\effects",
    [string]$OutputDirectory = "assets\graphics\effects"
)

$ErrorActionPreference = "Stop"
try
{
    Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop
}
catch
{
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}

$drawingAssembly = [System.Drawing.Bitmap].Assembly.Location
$primitivesAssembly = [System.Drawing.Rectangle].Assembly.Location
$source = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class CombatVisualArtPrep
{
    private static Bitmap NormalizeAlpha(string path)
    {
        using (var source = new Bitmap(path))
        {
            var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
            using (var graphics = Graphics.FromImage(bitmap))
            {
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(source, 0, 0);
            }

            for (int y = 0; y < bitmap.Height; y++)
            {
                for (int x = 0; x < bitmap.Width; x++)
                {
                    Color color = bitmap.GetPixel(x, y);
                    int alpha;
                    if (color.A <= 8)
                    {
                        alpha = 0;
                    }
                    else if (color.A >= 192)
                    {
                        alpha = 255;
                    }
                    else
                    {
                        alpha = Math.Min(255, Math.Max(0, (color.A - 8) * 255 / 184));
                    }
                    bitmap.SetPixel(x, y, Color.FromArgb(alpha, color.R, color.G, color.B));
                }
            }
            return bitmap;
        }
    }

    public static void Prepare(string input, string output, int canvas, float scale, bool stretchSquare)
    {
        using (var source = NormalizeAlpha(input))
        using (var destination = new Bitmap(canvas, canvas, PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(destination))
        {
            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = SmoothingMode.HighQuality;

            int targetWidth;
            int targetHeight;
            if (stretchSquare)
            {
                targetWidth = (int)Math.Round(canvas * scale);
                targetHeight = targetWidth;
            }
            else
            {
                float fit = Math.Min((float)canvas / source.Width, (float)canvas / source.Height) * scale;
                targetWidth = (int)Math.Round(source.Width * fit);
                targetHeight = (int)Math.Round(source.Height * fit);
            }
            int offsetX = (canvas - targetWidth) / 2;
            int offsetY = (canvas - targetHeight) / 2;
            graphics.DrawImage(
                source,
                new Rectangle(offsetX, offsetY, targetWidth, targetHeight),
                new Rectangle(0, 0, source.Width, source.Height),
                GraphicsUnit.Pixel
            );
            destination.Save(output, ImageFormat.Png);
        }
    }

    public static string Describe(string path)
    {
        using (var bitmap = new Bitmap(path))
        {
            int minimumX = bitmap.Width;
            int minimumY = bitmap.Height;
            int maximumX = -1;
            int maximumY = -1;
            int alphaPixels = 0;
            for (int y = 0; y < bitmap.Height; y++)
            {
                for (int x = 0; x < bitmap.Width; x++)
                {
                    if (bitmap.GetPixel(x, y).A <= 8)
                    {
                        continue;
                    }
                    minimumX = Math.Min(minimumX, x);
                    minimumY = Math.Min(minimumY, y);
                    maximumX = Math.Max(maximumX, x);
                    maximumY = Math.Max(maximumY, y);
                    alphaPixels++;
                }
            }
            return String.Format(
                "{0}: {1}x{2} {3} bounds=({4},{5})-({6},{7}) margins={4},{5},{8},{9} alphaPixels={10}",
                System.IO.Path.GetFileName(path),
                bitmap.Width,
                bitmap.Height,
                bitmap.PixelFormat,
                minimumX,
                minimumY,
                maximumX,
                maximumY,
                bitmap.Width - 1 - maximumX,
                bitmap.Height - 1 - maximumY,
                alphaPixels
            );
        }
    }
}
'@

$drawingReferences = @($drawingAssembly)
if ($primitivesAssembly -ne $drawingAssembly)
{
    $drawingReferences += $primitivesAssembly
}
Add-Type -TypeDefinition $source -ReferencedAssemblies $drawingReferences

$resolvedGenerated = (Resolve-Path -LiteralPath $GeneratedDirectory).Path
$resolvedStage = New-Item -ItemType Directory -Path $StageDirectory -Force
$resolvedOutput = New-Item -ItemType Directory -Path $OutputDirectory -Force

$assets = @(
    @{
        Name = "status_effect_icon_atlas_v019.png"
        Source = "exec-2447dba7-4841-458e-a7d5-590f66809acd.png"
        Canvas = 1024
        Scale = 1.0
        StretchSquare = $true
    },
    @{
        Name = "reaper_summon_v019.png"
        Source = "exec-63a85f1f-fa4e-4ef0-91e0-b07228906e42.png"
        Canvas = 1024
        Scale = 0.94
        StretchSquare = $false
    },
    @{
        Name = "death_vanguard_member_token_v019.png"
        Source = "exec-ea9e5605-ea1f-4490-8931-9da7d59b191c.png"
        Canvas = 512
        Scale = 0.90
        StretchSquare = $false
    }
)

foreach ($asset in $assets)
{
    $inputPath = Join-Path $resolvedGenerated $asset.Source
    $stagePath = Join-Path $resolvedStage.FullName $asset.Name
    $outputPath = Join-Path $resolvedOutput.FullName $asset.Name
    [CombatVisualArtPrep]::Prepare(
        $inputPath,
        $stagePath,
        [int]$asset.Canvas,
        [float]$asset.Scale,
        [bool]$asset.StretchSquare
    )
    Copy-Item -LiteralPath $stagePath -Destination $outputPath -Force
    [CombatVisualArtPrep]::Describe($outputPath)
}
