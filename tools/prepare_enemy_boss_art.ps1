param(
    [string]$GeneratedDirectory = "C:\Users\USER\.codex\generated_images\01a03d6d-4ce4-7d92-a159-aa2c60eac938",
    [string]$StageDirectory = "assets\graphics\style_refresh_v019\enemy_bosses",
    [string]$ActiveDirectory = "assets\graphics\enemies",
    [string]$BackupRoot = "C:\Users\USER\.codex\backups\td-survival\enemy-boss-art",
    [switch]$Activate
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$source = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class EnemyBossArtPrep
{
    private static bool IsCyanBackground(Color color)
    {
        return color.R <= 100
            && color.G >= 45
            && color.B >= 45
            && color.G - color.R >= 25
            && color.B - color.R >= 25
            && Math.Abs(color.G - color.B) <= 90;
    }

    public static Bitmap RemoveConnectedCyanBackground(string path)
    {
        using (var source = new Bitmap(path))
        {
            var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
            using (var graphics = Graphics.FromImage(bitmap))
            {
                graphics.DrawImageUnscaled(source, 0, 0);
            }

            int width = bitmap.Width;
            int height = bitmap.Height;
            var visited = new bool[width * height];
            var queue = new Queue<Point>();
            Action<int, int> enqueue = (x, y) =>
            {
                int index = y * width + x;
                if (visited[index] || !IsCyanBackground(bitmap.GetPixel(x, y)))
                {
                    return;
                }
                visited[index] = true;
                queue.Enqueue(new Point(x, y));
            };

            for (int x = 0; x < width; x++)
            {
                enqueue(x, 0);
                enqueue(x, height - 1);
            }
            for (int y = 0; y < height; y++)
            {
                enqueue(0, y);
                enqueue(width - 1, y);
            }

            while (queue.Count > 0)
            {
                Point point = queue.Dequeue();
                Color color = bitmap.GetPixel(point.X, point.Y);
                bitmap.SetPixel(point.X, point.Y, Color.FromArgb(0, color.R, color.G, color.B));
                if (point.X > 0) enqueue(point.X - 1, point.Y);
                if (point.X + 1 < width) enqueue(point.X + 1, point.Y);
                if (point.Y > 0) enqueue(point.X, point.Y - 1);
                if (point.Y + 1 < height) enqueue(point.X, point.Y + 1);
            }

            // Generated lightning rings and closed mechanical limbs can fully enclose
            // pieces of the keyed backdrop. Remove only large enclosed cyan regions;
            // the boss_15 subject's small cyan lamps remain below this threshold.
            const int enclosedBackgroundMinimumPixels = 1024;
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int startIndex = y * width + x;
                    if (visited[startIndex] || !IsCyanBackground(bitmap.GetPixel(x, y))) continue;
                    var component = new List<Point>();
                    visited[startIndex] = true;
                    queue.Enqueue(new Point(x, y));
                    while (queue.Count > 0)
                    {
                        Point point = queue.Dequeue();
                        component.Add(point);
                        Action<int, int> enqueueComponent = (nextX, nextY) =>
                        {
                            int index = nextY * width + nextX;
                            if (visited[index] || !IsCyanBackground(bitmap.GetPixel(nextX, nextY))) return;
                            visited[index] = true;
                            queue.Enqueue(new Point(nextX, nextY));
                        };
                        if (point.X > 0) enqueueComponent(point.X - 1, point.Y);
                        if (point.X + 1 < width) enqueueComponent(point.X + 1, point.Y);
                        if (point.Y > 0) enqueueComponent(point.X, point.Y - 1);
                        if (point.Y + 1 < height) enqueueComponent(point.X, point.Y + 1);
                    }
                    if (component.Count >= enclosedBackgroundMinimumPixels)
                    {
                        foreach (Point point in component)
                        {
                            Color color = bitmap.GetPixel(point.X, point.Y);
                            bitmap.SetPixel(point.X, point.Y, Color.FromArgb(0, color.R, color.G, color.B));
                        }
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
                if (bitmap.GetPixel(x, y).A <= 8) continue;
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
    "boss_5.png" = "exec-a6d3a272-fa71-4bef-aa55-e24f7af2098e.png"
    "boss_10.png" = "exec-92e1114c-66a3-4178-9e28-4bed513ec343.png"
    "boss_15.png" = "exec-f173b8b9-591e-4b31-8f88-7b7de20c1290.png"
    "final_boss.png" = "exec-491ce26e-6894-4805-bed6-d42ee2f9464c.png"
    "judgment_bell.png" = "exec-dab04438-a3c2-49b4-ac1d-9b16ae25801c.png"
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
    $cleaned = [EnemyBossArtPrep]::RemoveConnectedCyanBackground($inputPath)
    try
    {
        [EnemyBossArtPrep]::NormalizeContentToCanvas($cleaned, $temporaryPath, 1254, 0.84)
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
        if (Test-Path -LiteralPath $activePath)
        {
            Copy-Item -LiteralPath $activePath -Destination (Join-Path $backupDirectory $assetName) -Force
        }
        Copy-Item -LiteralPath $outputPath -Destination $activePath -Force
    }

    "{0}: {1}" -f $assetName, [EnemyBossArtPrep]::DescribeAlphaBounds($outputPath)
}

if ($Activate)
{
    "Backup: $backupDirectory"
}
