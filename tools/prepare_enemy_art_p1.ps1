param(
    [string]$GeneratedDirectory = "C:\Users\USER\.codex\generated_images\01a03d6d-4ce4-7d92-a159-aa2c60eac938",
    [string]$StageDirectory = "assets\graphics\style_refresh_v019\enemy_p1",
    [string]$ActiveDirectory = "assets\graphics\enemies",
    [string]$BackupRoot = "C:\Users\USER\.codex\backups\td-survival\enemy-art-p1",
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

public static class EnemyArtP1Prep
{
    private static bool IsConnectedLightBackground(Color color)
    {
        int maximum = Math.Max(color.R, Math.Max(color.G, color.B));
        int minimum = Math.Min(color.R, Math.Min(color.G, color.B));
        return minimum >= 195 && (maximum - minimum) <= 48;
    }

    public static Bitmap RemoveConnectedLightBackground(string path)
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
            var queue = new Queue<int>();
            Action<int, int> seed = (x, y) =>
            {
                int index = y * width + x;
                if (!visited[index] && IsConnectedLightBackground(bitmap.GetPixel(x, y)))
                {
                    visited[index] = true;
                    queue.Enqueue(index);
                }
            };

            for (int x = 0; x < width; x++)
            {
                seed(x, 0);
                seed(x, height - 1);
            }
            for (int y = 1; y < height - 1; y++)
            {
                seed(0, y);
                seed(width - 1, y);
            }

            int[] deltaX = { 1, -1, 0, 0 };
            int[] deltaY = { 0, 0, 1, -1 };
            while (queue.Count > 0)
            {
                int index = queue.Dequeue();
                int x = index % width;
                int y = index / width;
                Color color = bitmap.GetPixel(x, y);
                bitmap.SetPixel(x, y, Color.FromArgb(0, color.R, color.G, color.B));
                for (int direction = 0; direction < 4; direction++)
                {
                    int nextX = x + deltaX[direction];
                    int nextY = y + deltaY[direction];
                    if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height)
                    {
                        continue;
                    }
                    int nextIndex = nextY * width + nextX;
                    if (!visited[nextIndex] && IsConnectedLightBackground(bitmap.GetPixel(nextX, nextY)))
                    {
                        visited[nextIndex] = true;
                        queue.Enqueue(nextIndex);
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
    "goblin_raider.png" = "exec-48ae47b9-61ab-492e-af3b-68747bfb31fa.png"
    "skeleton_raider.png" = "exec-81f6152e-3099-4626-9191-6737b3ead3ed.png"
    "orc_shield.png" = "exec-7fd41e67-2ea7-4359-8db7-b74e98d33d01.png"
    "partason_standard_shield.png" = "exec-9342a287-87eb-4412-976b-0ce5ee64b05c.png"
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
    $cleaned = [EnemyArtP1Prep]::RemoveConnectedLightBackground($inputPath)
    try
    {
        [EnemyArtP1Prep]::NormalizeContentToCanvas($cleaned, $temporaryPath, 1254, 0.84)
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

    "{0}: {1}" -f $assetName, [EnemyArtP1Prep]::DescribeAlphaBounds($outputPath)
}

if ($Activate)
{
    "Backup: $backupDirectory"
}
