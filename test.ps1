function Save-Screenshot {
    <#
    .Synopsis
        Saves a screenshot of a UI element
    .Description
        Saves a screenshot of a WPF UI element to many different file formats
    .Example
        New-Button -FontFamily "Webdings" -Content ([char]0xcf) -FontSize 36 |
            Save-Screenshot -AsPng -outputPath .\LockButton.jpg
    #>
    [CmdletBinding(DefaultParameterSetName = 'Jpeg')]
    [OutputType([Byte[]], [IO.FileInfo])]
    param(
        # The inputObject
        [Parameter(ValueFromPipeline = $true)]
        [Windows.Media.Visual]
        $InputObject,        
    
        # the pixel format used to save the image
        [Windows.Media.PixelFormat]
        $pixelFormat = [Windows.Media.PixelFormats]::Default,
    
        # The JPEG Quality
        [Parameter(ParameterSetName = 'Jpeg')]
        [int]$JpegQuality = 100,

        # The dots per inch
        [Alias('DPI')]
        [int]$DotsPerInch = 96,
        
        # If set, will save as a jpeg
        [Parameter(ParameterSetName = 'Jpeg')]
        [Alias('AsJpg', 'Jpg', 'Jpeg')]
        [switch]
        $AsJpeg,

        # If set, will save as a png
        [Parameter(ParameterSetName = 'Png')]
        [Alias('Png')]
        [switch]
        $AsPng,
    
        # If set, interlaces the output PNG
        [Parameter(ParameterSetName = 'Png')]
        [switch]
        $Interlace,
    
        # If set, outputs a BMP
        [Parameter(ParameterSetName = 'Bmp')]
        [Alias('Bmp')]
        [switch]
        $AsBmp,
    
        # If set, outputs a GIF
        [Parameter(ParameterSetName = 'Gif')]
        [Alias('Gif')]
        [switch]
        $AsGif,
    
        # If set, outputs a TIFF
        [Parameter(ParameterSetName = 'Tiff')]
        [Alias('Tiff', 'Tif')]
        [switch]
        $AsTiff,
    
        # Changes the Tiff Compression
        [Parameter(ParameterSetName = 'Tiff')]
        [Windows.Media.Imaging.TiffCompressOption]
        $TiffCompression = 'Zip',
    
        # If set, outputs HDPhoto
        [Parameter(ParameterSetName = 'Wmp')]
        [Alias('Wmp', 'HDPhoto')]
        [switch]
        $AsWmp,
    
        # If set, returns the item as a frame
        [Parameter(ParameterSetName = 'Frame')]
        [switch]
        $AsFrame,
    
        # The output path. If this is not set, it will be saved to a randomly named file in the
        # current directory.
        [string]$OutputPath,
    
        # If set, will output bytes instead of a file
        [switch]$InMemory,
    
        # The amount of time to wait before closing the window
        [Timespan]
        $ScreenShotTimer = 10
    )
    
    process {
        #region Process Parameters Before Launching UI
        if ($psCmdlet.ParameterSetName -eq 'Jpeg') {
            $psBoundParameters.AsJpeg = $true
            $asJpeg = $true
        } 
        $psBoundParameters."As$($psCmdlet.ParameterSetName)" = $true
        if (-not $psBoundParameters.PixelFormat) {
            $psBoundParameters.PixelFormat = $pixelFormat
        }
        if (-not $psBoundParameters.DotsPerInch) {
            $psBoundParameters.DotsPerInch = $DotsPerInch
        }
        if (-not $psBoundParameters.JpegQuality) {
            $psBoundParameters.JpegQuality = $jpegQuality
        }
        if (-not $psBoundParameters.TiffCompression) {
            $psBoundParameters.TiffCompression = $tiffCompression 
        }
        
        if (-not $psBoundParameters.OutputPath) {
            if ($asJpeg) {
                $psBoundParameters.OutputPath = Join-Path $pwd "Screenshot.$(Get-Random).jpeg"
            }
            elseif ($asPng) {
                $psBoundParameters.OutputPath = Join-Path $pwd "Screenshot.$(Get-Random).png"
            }
            elseif ($asbmp) {
                $psBoundParameters.OutputPath = Join-Path $pwd "Screenshot.$(Get-Random).bmp"
            }
            elseif ($astiff) {
                $psBoundParameters.OutputPath = Join-Path $pwd "Screenshot.$(Get-Random).tiff"
            }
            elseif ($aswmp) {
                $psBoundParameters.OutputPath = Join-Path $pwd "Screenshot.$(Get-Random).wmp"
            }
            elseif ($asgif) {
                $psBoundParameters.OutputPath = Join-Path $pwd "Screenshot.$(Get-Random).gif"
            }
            elseif ($asFrame) {
                $psBoundParameters.OutputPath = $null
            }
            elseif ($InMemory) {
                $psBoundParameters.OutputPath = $null
            }
            
        }
        else {
            $psBoundParameters.OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($psBoundParameters.OutputPath)
            
        }
        #endregion
        
        foreach ($kv in $psBoundParameters.GetEnumerator()) {
            $inputObject.Resources[$kv.Key] = $kv.Value
        }


        if ($Window) {
            # Already in ShowUI

        }
        else {

            $inputObject.Resources['ScreenshotTimer'] = $screenShotTimer
            $inputObject |
            Add-EventHandler -EventName On_SizeChanged -Handler {
                if ($_.PreviousSize.Width -eq 0 -and $_.PreviousSize.Height -eq 0) {
                
                    $visual = $This
                    $window | Add-EventHandler -EventName On_LocationChanged -Handler { $window.Close() } 
                    $waitScript = [ScriptBlock]::Create("
                    Start-Sleep -Milliseconds $($ScreenshotTimer.TotalMilliseconds); `$true
                ")
                
                    $this.DataContext = Get-PowerShellDataSource -On_OutputChanged {
                        $visual = $This
                        if (-not $visual.Background -and 
                            -not ($AsPng -or $AsGif)) {
                            if ($visual -and $visual.GetType().GetProperty("Background")) {
                                try {
                                    # $visual.Background = "White"
                                }
                                catch {
                            
                                }
                            }
                        }
                        if (-not $DotsPerInch) { $DotsPerInch = 72 } 
                        $visual.UpdateLayout()
                        $actualWidth = $visual.ActualWidth
                        $actualHeight = $visual.ActualHeight
                        #$visual | select *height* | Out-Host
                        #$actualWidth, $actualHeight, $DotsPerInch | Out-Host
                        $renderBitmap = 
                        New-Object Windows.Media.Imaging.RenderTargetBitmap $actualWidth , $actualHeight, $DotsPerInch, $DotsPerInch, ([Windows.Media.PixelFormats]::Pbgra32)
                        $sourceBrush = New-Object Windows.Media.VisualBrush $visual
                        #$sourceBrush | Out-Host
                        $drawingVisual = New-Object Windows.Media.DrawingVisual 
                    
                        $drawingContext = $drawingVisual.RenderOpen()
                        $rect = New-Object Windows.Rect ((New-Object Windows.Point), (
                                New-Object Windows.Point $actualWidth, $actualHeight
                            ))
                    
                        $drawingContext.DrawRectangle($sourceBrush, $null, $rect)

                        $drawingContext.Close()
                        $renderBitmap.Render($drawingVisual)
                        $frame = [Windows.Media.Imaging.BitmapFrame]::Create($renderBitmap)

                        $fileOrInMemory = {
                            param($this, $encoder, $inMemory, $outputPath) 
                            $null = $encoder.Frames.Add($frame)          
                            if ($InMemory) {                        
                                $memStream = New-Object IO.MemoryStream
                                $encoder.Save($memStream) 
                                $memStream.Seek(0, 0)
                                $bytes = New-Object Byte[] $memStream.Length
                                $memStream.Read($bytes, 0, $memStream.Length)                        
                                $this.Parent.Tag = $bytes
                            }
                            else {
                                $fileStream = [IO.File]::Create($outputPath)                               
                                $encoder.Save($fileStream) 
                                $fileStream.Close()               
                            }
                        }
                    
                        if ($AsJpeg) {
                            $jpegEncoder = New-Object Windows.Media.Imaging.JpegBitmapEncoder
                            $jpegEncoder.QualityLevel = $jpegquality                    
                            & $fileOrInMemory $this $jpegEncoder $inMemory $outputPath                    
                        }
                        elseif ($AsPng) {                    
                            $pngEncoder = New-Object Windows.Media.Imaging.PngBitmapEncoder
                            if ($interlace) {
                                $pngEncoder.Interlace = 'On'
                            }
                            & $fileOrInMemory $this $pngEncoder $inMemory $outputPath                                                            
                        }
                        elseif ($AsBmp) {                    
                            $bmpEncoder = New-Object Windows.Media.Imaging.BmpBitmapEncoder                    
                            & $fileOrInMemory $this $bmpEncoder $inMemory $outputPath      
                        }
                        elseif ($asTiff) {
                            $TiffEncoder = New-Object Windows.Media.Imaging.TiffBitmapEncoder
                            $TiffEncoder.Compression = $TiffCompression
                            & $fileOrInMemory $this $TiffEncoder $inMemory $outputPath      
                        }
                        elseif ($asgif) {
                            $GifEncoder = New-Object Windows.Media.Imaging.GifBitmapEncoder
                            & $fileOrInMemory $this $GifEncoder $inMemory $outputPath      
                        }
                        elseif ($aswmp) {
                            $WmpEncoder = New-Object Windows.Media.Imaging.WmpBitmapEncoder
                            & $fileOrInMemory $this $WmpEncoder $inMemory $outputPath      
                        }
                        elseif ($AsFrame) {
                            $frame
                            $this.Parent.Tag = $frame
                        } 


                        $window.Close()
                    } -Script $waitScript
                }
            }
        
            $bytes = $inputObject | Show-Window -WindowProperty @{Sizetocontent = 'WidthAndHeight'; Top = -10000; Left = -10000 }
        }
        if ($byteS -and ($InMemory -or $asFrame)) { 
            $bytes
        }
        
        $params = $psBoundParameters     
        if ($psBoundparameters.OutputPath) {   
            Get-Item -ErrorAction SilentlyContinue $psBoundParameters.OutputPath                        
        }
    }
}

New-Button -FontFamily "Webdings" -Content ([char]0xcf) -FontSize 36 |
Save-Screenshot -AsPng -outputPath .\LockButton.jpg