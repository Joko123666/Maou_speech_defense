param(
    [string]$GeneratedDirectory = "C:\Users\USER\.codex\generated_images\01a03d6d-4ce4-7d92-a159-aa2c60eac938",
    [string]$StageDirectory = "assets\graphics\style_refresh_v019\enemy_p0"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$source = @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class EnemyArtPrep
{
    private static bool IsBackground(Color color)
    {
        int maximum = Math.Max(color.R, Math.Max(color.G, color.B));
        int minimum = Math.Min(color.R, Math.Min(color.G, color.B));
        return minimum >= 205 && (maximum - minimum) <= 38;
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
                if (!visited[index] && IsBackground(bitmap.GetPixel(x, y)))
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
                    if (!visited[nextIndex] && IsBackground(bitmap.GetPixel(nextX, nextY)))
                    {
                        visited[nextIndex] = true;
                        queue.Enqueue(nextIndex);
                    }
                }
            }
            return bitmap;
        }
    }

    public static void NormalizeToCanvas(Bitmap source, string output, int canvas, float scale)
    {
        using (var destination = new Bitmap(canvas, canvas, PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(destination))
        {
            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = SmoothingMode.HighQuality;
            int size = (int)Math.Round(canvas * scale);
            int offset = (canvas - size) / 2;
            graphics.DrawImage(
                source,
                new Rectangle(offset, offset, size, size),
                new Rectangle(0, 0, source.Width, source.Height),
                GraphicsUnit.Pixel
            );
            destination.Save(output, ImageFormat.Png);
        }
    }

    public static string DescribeAlphaBounds(string path)
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
                "{0}x{1} {2} bounds=({3},{4})-({5},{6}) margins={3},{4},{7},{8} alphaPixels={9}",
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

Add-Type -TypeDefinition $source -ReferencedAssemblies System.Drawing

$resolvedStage = (Resolve-Path -LiteralPath $StageDirectory).Path
$generatedFiles = [ordered]@{
    "wraith_raider.png" = "exec-c74f4688-43ad-4365-815a-394d95bf0f99.png"
    "steel_golem.png" = "exec-989828c6-028f-45e4-a628-56fa308922bd.png"
    "hound_light_infantry.png" = "exec-a46350fa-988c-43f1-b982-45681fdb54f6.png"
    "irelai_skeleton_cavalry.png" = "exec-cb81eb83-1aee-4392-b426-cbd567158266.png"
    "enemy_test.png" = "exec-776e82cd-acfa-4628-b9b8-a25c86524c30.png"
}

foreach ($assetName in $generatedFiles.Keys)
{
    $inputPath = Join-Path $GeneratedDirectory $generatedFiles[$assetName]
    $temporaryPath = Join-Path $resolvedStage (".tmp_" + $assetName)
    $bitmap = [System.Drawing.Bitmap]::FromFile($inputPath)
    try
    {
        [EnemyArtPrep]::NormalizeToCanvas($bitmap, $temporaryPath, 1254, 0.84)
    }
    finally
    {
        $bitmap.Dispose()
    }
    Copy-Item -LiteralPath $temporaryPath -Destination (Join-Path $resolvedStage $assetName) -Force
    Remove-Item -LiteralPath $temporaryPath -Force
}

$kasuhaInputPath = Join-Path $GeneratedDirectory "exec-b81529c0-80c1-4972-ace8-7639fb57b8af.png"
$kasuhaTemporaryPath = Join-Path $resolvedStage ".tmp_kasuha_abyss_creature.png"
$kasuhaBitmap = [EnemyArtPrep]::RemoveConnectedLightBackground($kasuhaInputPath)
try
{
    [EnemyArtPrep]::NormalizeToCanvas($kasuhaBitmap, $kasuhaTemporaryPath, 1254, 0.84)
}
finally
{
    $kasuhaBitmap.Dispose()
}
Copy-Item -LiteralPath $kasuhaTemporaryPath -Destination (Join-Path $resolvedStage "kasuha_abyss_creature.png") -Force
Remove-Item -LiteralPath $kasuhaTemporaryPath -Force

Get-ChildItem -LiteralPath $resolvedStage -Filter "*.png" |
    Sort-Object Name |
    ForEach-Object {
        "{0}: {1}" -f $_.Name, [EnemyArtPrep]::DescribeAlphaBounds($_.FullName)
    }
