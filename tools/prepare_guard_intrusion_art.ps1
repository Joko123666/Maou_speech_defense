param(
    [string]$GeneratedDirectory = "C:\Users\USER\.codex\generated_images\01a03d6d-4ce4-7d92-a159-aa2c60eac938",
    [string]$StageDirectory = "assets\graphics\style_refresh_v019\guard_intrusion_sd",
    [string]$ActiveDirectory = "assets\graphics\guard_intrusion_sd",
    [string]$BackupRoot = "C:\Users\USER\.codex\backups\td-survival\guard-intrusion-art",
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

public static class GuardIntrusionArtPrep
{
    private static bool IsGeneratedBackdrop(Color color)
    {
        if (color.A <= 8) return true;
        int minimum = Math.Min(color.R, Math.Min(color.G, color.B));
        int maximum = Math.Max(color.R, Math.Max(color.G, color.B));
        return minimum >= 224 && maximum - minimum <= 20;
    }

    public static Bitmap RemoveConnectedBackdrop(string path)
    {
        using (var source = new Bitmap(path))
        {
            var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
            using (var graphics = Graphics.FromImage(bitmap))
            {
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.DrawImageUnscaled(source, 0, 0);
            }

            int width = bitmap.Width;
            int height = bitmap.Height;
            bool sourceAlreadyTransparent = source.GetPixel(0, 0).A <= 8
                || source.GetPixel(width - 1, 0).A <= 8
                || source.GetPixel(0, height - 1).A <= 8
                || source.GetPixel(width - 1, height - 1).A <= 8;
            var visited = new bool[width * height];
            var queue = new Queue<Point>();
            Action<int, int> enqueue = (x, y) =>
            {
                int index = y * width + x;
                if (visited[index] || !IsGeneratedBackdrop(bitmap.GetPixel(x, y))) return;
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
                bitmap.SetPixel(point.X, point.Y, Color.Transparent);
                if (point.X > 0) enqueue(point.X - 1, point.Y);
                if (point.X + 1 < width) enqueue(point.X + 1, point.Y);
                if (point.Y > 0) enqueue(point.X, point.Y - 1);
                if (point.Y + 1 < height) enqueue(point.X, point.Y + 1);
            }

            // The built-in generator can bake its transparency checkerboard into
            // RGB. Remove large neutral checker components enclosed by limbs or a
            // weapon, while preserving tiny white eye/specular accents. Sources
            // that already carry real edge alpha do not need this second pass.
            if (!sourceAlreadyTransparent)
            {
                const int enclosedBackdropMinimumPixels = 1024;
                for (int y = 0; y < height; y++)
                {
                    for (int x = 0; x < width; x++)
                    {
                        int startIndex = y * width + x;
                        if (visited[startIndex] || !IsGeneratedBackdrop(bitmap.GetPixel(x, y))) continue;
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
                                if (visited[index] || !IsGeneratedBackdrop(bitmap.GetPixel(nextX, nextY))) return;
                                visited[index] = true;
                                queue.Enqueue(new Point(nextX, nextY));
                            };
                            if (point.X > 0) enqueueComponent(point.X - 1, point.Y);
                            if (point.X + 1 < width) enqueueComponent(point.X + 1, point.Y);
                            if (point.Y > 0) enqueueComponent(point.X, point.Y - 1);
                            if (point.Y + 1 < height) enqueueComponent(point.X, point.Y + 1);
                        }
                        if (component.Count < enclosedBackdropMinimumPixels) continue;
                        foreach (Point point in component)
                        {
                            bitmap.SetPixel(point.X, point.Y, Color.Transparent);
                        }
                    }
                }
            }

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    Color color = bitmap.GetPixel(x, y);
                    if (color.A <= 8) bitmap.SetPixel(x, y, Color.Transparent);
                }
            }

            // A generated checker sheet can include a stray colored stroke on an
            // outer edge. The authored subject is required to keep an 8% margin,
            // so any remaining visible component connected to the canvas edge is
            // unambiguously a generator artifact.
            var edgeVisited = new bool[width * height];
            Action<int, int> enqueueVisibleEdge = (x, y) =>
            {
                int index = y * width + x;
                if (edgeVisited[index] || bitmap.GetPixel(x, y).A <= 8) return;
                edgeVisited[index] = true;
                queue.Enqueue(new Point(x, y));
            };
            for (int x = 0; x < width; x++)
            {
                enqueueVisibleEdge(x, 0);
                enqueueVisibleEdge(x, height - 1);
            }
            for (int y = 0; y < height; y++)
            {
                enqueueVisibleEdge(0, y);
                enqueueVisibleEdge(width - 1, y);
            }
            while (queue.Count > 0)
            {
                Point point = queue.Dequeue();
                bitmap.SetPixel(point.X, point.Y, Color.Transparent);
                if (point.X > 0) enqueueVisibleEdge(point.X - 1, point.Y);
                if (point.X + 1 < width) enqueueVisibleEdge(point.X + 1, point.Y);
                if (point.Y > 0) enqueueVisibleEdge(point.X, point.Y - 1);
                if (point.Y + 1 < height) enqueueVisibleEdge(point.X, point.Y + 1);
            }

            const int minimumVisibleComponentPixels = 256;
            var visibleVisited = new bool[width * height];
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int startIndex = y * width + x;
                    if (visibleVisited[startIndex] || bitmap.GetPixel(x, y).A <= 8) continue;
                    var component = new List<Point>();
                    visibleVisited[startIndex] = true;
                    queue.Enqueue(new Point(x, y));
                    while (queue.Count > 0)
                    {
                        Point point = queue.Dequeue();
                        component.Add(point);
                        for (int offsetY = -1; offsetY <= 1; offsetY++)
                        {
                            for (int offsetX = -1; offsetX <= 1; offsetX++)
                            {
                                if (offsetX == 0 && offsetY == 0) continue;
                                int nextX = point.X + offsetX;
                                int nextY = point.Y + offsetY;
                                if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height) continue;
                                int index = nextY * width + nextX;
                                if (visibleVisited[index] || bitmap.GetPixel(nextX, nextY).A <= 8) continue;
                                visibleVisited[index] = true;
                                queue.Enqueue(new Point(nextX, nextY));
                            }
                        }
                    }
                    if (component.Count >= minimumVisibleComponentPixels) continue;
                    foreach (Point point in component)
                    {
                        bitmap.SetPixel(point.X, point.Y, Color.Transparent);
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
    "partason_faction.png" = "exec-a2111c33-0688-472e-88e1-b990a702d1de.png"
    "jiane_faction.png" = "exec-84e3cf4c-a2f9-484a-909c-c0c9e7de086a.png"
    "kasuha_faction.png" = "exec-2c98f7c9-3770-4b7b-acd7-9fc33856f878.png"
    "irelai_faction.png" = "exec-3d53aed1-d659-4ab8-8958-78e0316e6992.png"
    "judaginda_faction.png" = "exec-9fb48b6b-88d5-4cc4-8d55-b063ecf9dc56.png"
}

$resolvedStage = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $StageDirectory))
$resolvedActive = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $ActiveDirectory))
[System.IO.Directory]::CreateDirectory($resolvedStage) | Out-Null
if ($Activate)
{
    [System.IO.Directory]::CreateDirectory($resolvedActive) | Out-Null
}

$backupDirectory = ""
foreach ($assetName in $generatedFiles.Keys)
{
    $inputPath = Join-Path $GeneratedDirectory $generatedFiles[$assetName]
    if (-not (Test-Path -LiteralPath $inputPath))
    {
        throw "Generated source does not exist: $inputPath"
    }

    $outputPath = Join-Path $resolvedStage $assetName
    $temporaryPath = Join-Path $resolvedStage (".tmp_" + $assetName)
    $cleaned = [GuardIntrusionArtPrep]::RemoveConnectedBackdrop($inputPath)
    try
    {
        [GuardIntrusionArtPrep]::NormalizeContentToCanvas($cleaned, $temporaryPath, 1254, 0.84)
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
            if ($backupDirectory -eq "")
            {
                $backupDirectory = Join-Path $BackupRoot (Get-Date -Format "yyyyMMdd_HHmmss")
                [System.IO.Directory]::CreateDirectory($backupDirectory) | Out-Null
            }
            Copy-Item -LiteralPath $activePath -Destination (Join-Path $backupDirectory $assetName) -Force
        }
        Copy-Item -LiteralPath $outputPath -Destination $activePath -Force
    }

    "{0}: {1}" -f $assetName, [GuardIntrusionArtPrep]::DescribeAlphaBounds($outputPath)
}

if ($backupDirectory -ne "")
{
    "Backup: $backupDirectory"
}
