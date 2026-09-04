param(
    [string]$GeneratedDirectory = "C:\Users\USER\.codex\generated_images\01a03d6d-4ce4-7d92-a159-aa2c60eac938",
    [string]$StageDirectory = "assets\graphics\style_refresh_v019\enemy_p2",
    [string]$ActiveDirectory = "assets\graphics\enemies",
    [string]$BackupRoot = "C:\Users\USER\.codex\backups\td-survival\enemy-art-p2",
    [switch]$Activate
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$source = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class EnemyArtP2Prep
{
    private static bool IsCyanBackground(Color color)
    {
        return color.R <= 100
            && color.G >= 45
            && color.B >= 45
            && color.G - color.R >= 25
            && color.B - color.R >= 25
            && Math.Abs(color.G - color.B) <= 80;
    }

    public static Bitmap RemoveCyanBackground(string path)
    {
        using (var source = new Bitmap(path))
        {
            var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
            using (var graphics = Graphics.FromImage(bitmap))
            {
                graphics.DrawImageUnscaled(source, 0, 0);
            }
            for (int y = 0; y < bitmap.Height; y++)
            {
                for (int x = 0; x < bitmap.Width; x++)
                {
                    Color color = bitmap.GetPixel(x, y);
                    if (IsCyanBackground(color))
                    {
                        bitmap.SetPixel(x, y, Color.FromArgb(0, color.R, color.G, color.B));
                    }
                }
            }
            return bitmap;
        }
    }

    private static Rectangle AlphaBounds(Bitmap bitmap)
    {
        int minimumX = bitmap.Width;
        int minimumY = bitmap.Height;
        int maximumX = -1;
        int maximumY = -1;
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
            }
        }
        if (maximumX < minimumX || maximumY < minimumY)
        {
            throw new InvalidOperationException("No visible pixels remain after alpha cleanup.");
        }
        return Rectangle.FromLTRB(minimumX, minimumY, maximumX + 1, maximumY + 1);
    }

    public static void NormalizeContentToCanvas(Bitmap source, string output, int canvas, float maximumFill)
    {
        Rectangle bounds = AlphaBounds(source);
        float scale = Math.Min((canvas * maximumFill) / bounds.Width, (canvas * maximumFill) / bounds.Height);
        int width = Math.Max(1, (int)Math.Round(bounds.Width * scale));
        int height = Math.Max(1, (int)Math.Round(bounds.Height * scale));
        int offsetX = (canvas - width) / 2;
        int offsetY = (canvas - height) / 2;

        using (var destination = new Bitmap(canvas, canvas, PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(destination))
        {
            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = SmoothingMode.HighQuality;
            graphics.DrawImage(source, new Rectangle(offsetX, offsetY, width, height), bounds, GraphicsUnit.Pixel);
            destination.Save(output, ImageFormat.Png);
        }
    }

    public static string DescribeAlphaBounds(string path)
    {
        using (var bitmap = new Bitmap(path))
        {
            Rectangle bounds = AlphaBounds(bitmap);
            return String.Format(
                "{0}x{1} {2} bounds=({3},{4})-({5},{6}) margins={3},{4},{7},{8}",
                bitmap.Width,
                bitmap.Height,
                bitmap.PixelFormat,
                bounds.Left,
                bounds.Top,
                bounds.Right - 1,
                bounds.Bottom - 1,
                bitmap.Width - bounds.Right,
                bitmap.Height - bounds.Bottom
            );
        }
    }
}
'@

Add-Type -TypeDefinition $source -ReferencedAssemblies System.Drawing

$generatedFiles = [ordered]@{
    "civilian_slime.png" = "exec-ebf42964-88d9-4197-bf56-6f555ead3299.png"
    "jiane_succubus_bewitcher.png" = "exec-01ecd54e-cd6d-49a1-9387-03625486dd1b.png"
    "judaginda_cult_applicant.png" = "exec-21de9956-7881-47eb-b0d4-44d20f6640c1.png"
}

$resolvedStage = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $StageDirectory))
$resolvedActive = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $ActiveDirectory))
[System.IO.Directory]::CreateDirectory($resolvedStage) | Out-Null

$backupDirectory = ""
if ($Activate)
{
    $backupDirectory = Join-Path $BackupRoot (Get-Date -Format "yyyyMMdd_HHmmss")
    [System.IO.Directory]::CreateDirectory($backupDirectory) | Out-Null
}

foreach ($assetName in $generatedFiles.Keys)
{
    $inputPath = Join-Path $GeneratedDirectory $generatedFiles[$assetName]
    if (-not (Test-Path -LiteralPath $inputPath))
    {
        throw "Generated source does not exist: $inputPath"
    }

    $outputPath = Join-Path $resolvedStage $assetName
    $temporaryPath = Join-Path $resolvedStage (".tmp_" + $assetName)
    $cleaned = [EnemyArtP2Prep]::RemoveCyanBackground($inputPath)
    try
    {
        [EnemyArtP2Prep]::NormalizeContentToCanvas($cleaned, $temporaryPath, 1254, 0.84)
    }
    finally
    {
        $cleaned.Dispose()
    }
    Copy-Item -LiteralPath $temporaryPath -Destination $outputPath -Force
    Remove-Item -LiteralPath $temporaryPath -Force

    if ($Activate)
    {
        $activePath = Join-Path $resolvedActive $assetName
        Copy-Item -LiteralPath $activePath -Destination (Join-Path $backupDirectory $assetName) -Force
        Copy-Item -LiteralPath $outputPath -Destination $activePath -Force
    }

    "{0}: {1}" -f $assetName, [EnemyArtP2Prep]::DescribeAlphaBounds($outputPath)
}

if ($Activate)
{
    "Backup: $backupDirectory"
}
