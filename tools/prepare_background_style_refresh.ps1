param(
    [string]$GeneratedDirectory = "C:\Users\USER\.codex\generated_images\01a03d6d-4ce4-7d92-a159-aa2c60eac938",
    [string]$StageDirectory = "assets\graphics\style_refresh_v019\backgrounds",
    [string]$OutputDirectory = "assets\graphics\backgrounds"
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

public static class BackgroundStylePrep
{
    public static void CoverResize(string input, string output, int width, int height)
    {
        using (var source = new Bitmap(input))
        using (var destination = new Bitmap(width, height, PixelFormat.Format24bppRgb))
        using (var graphics = Graphics.FromImage(destination))
        {
            graphics.Clear(Color.Black);
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = SmoothingMode.HighQuality;

            float targetRatio = (float)width / height;
            float sourceRatio = (float)source.Width / source.Height;
            Rectangle crop;
            if (sourceRatio > targetRatio)
            {
                int cropWidth = (int)Math.Round(source.Height * targetRatio);
                crop = new Rectangle((source.Width - cropWidth) / 2, 0, cropWidth, source.Height);
            }
            else
            {
                int cropHeight = (int)Math.Round(source.Width / targetRatio);
                crop = new Rectangle(0, (source.Height - cropHeight) / 2, source.Width, cropHeight);
            }
            graphics.DrawImage(source, new Rectangle(0, 0, width, height), crop, GraphicsUnit.Pixel);
            destination.Save(output, ImageFormat.Png);
        }
    }

    public static string Describe(string path)
    {
        using (var bitmap = new Bitmap(path))
        {
            Color topLeft = bitmap.GetPixel(0, 0);
            Color bottomRight = bitmap.GetPixel(bitmap.Width - 1, bitmap.Height - 1);
            return String.Format(
                "{0}: {1}x{2} {3} corners=A{4}/A{5}",
                System.IO.Path.GetFileName(path),
                bitmap.Width,
                bitmap.Height,
                bitmap.PixelFormat,
                topLeft.A,
                bottomRight.A
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
$resolvedOutput = (Resolve-Path -LiteralPath $OutputDirectory).Path
$assets = [ordered]@{
    "demon_election_campaign_hq_v019.png" = "exec-8b2bb201-8a44-44bc-9a00-2b2ff62d2d7c.png"
    "demon_election_campaign_arena_v019.png" = "exec-a960d989-ddbc-4acf-930e-7ca0e9a495ea.png"
}

foreach ($assetName in $assets.Keys)
{
    $inputPath = Join-Path $resolvedGenerated $assets[$assetName]
    $stagePath = Join-Path $resolvedStage.FullName $assetName
    $outputPath = Join-Path $resolvedOutput $assetName
    [BackgroundStylePrep]::CoverResize($inputPath, $stagePath, 1280, 720)
    Copy-Item -LiteralPath $stagePath -Destination $outputPath -Force
    [BackgroundStylePrep]::Describe($outputPath)
}
