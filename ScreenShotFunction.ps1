Clear-Host
#Initialize
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.ComponentModel') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Data') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null

[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore') | out-null
[System.Reflection.Assembly]::LoadFrom('res\assembly\MahApps.Metro.dll') | out-null
[System.Reflection.Assembly]::LoadFrom('res\assembly\System.Windows.Interactivity.dll') | out-null

# When compiled with PS2EXE the variable MyCommand contains no path anymore

if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript") {
    # Powershell script
    $Path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
else {
    # PS2EXE compiled script
    $Path = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

#Write-Host $Path
$MainformIcon = $Path + "\res\mum.png"


Function SizeCalc {

    $TitelbarSize = 25 + 10
    $SourceSize = 80 + 10
    $ParsedLicenseFileSize = 32
    $LicenseTypeSize = 32
    $ComputerSize = 32
    $MACSize = 32 + 10
    $IncrementMatchedTextSize = 26 + 10
    $HeaderIncrementGridSize = 27 + 35
    $PackageIncrementsMatchedTextSize = 26 + 10
    $HeaderPackageGridSize = 27 + 10
    $ResetButtonSize = 27 + 5

    #Get MainMonitorSize
    $MHeight = [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize | Select-Object Height
    $MHeight -match '\d+'
    $MHeight = $Matches[0]

    $FixedSize = $TitelbarSize + $SourceSize + $ParsedLicenseFileSize + $LicenseTypeSize + $ComputerSize + $MACSize + 
    $IncrementMatchedTextSize + $HeaderIncrementGridSize + $PackageIncrementsMatchedTextSize + $HeaderPackageGridSize + $ResetButtonSize
    $Marginspace = 150

    $RemainsSize = $MHeight - $FixedSize - $Marginspace

    if ($WPFDataGridInc.Items.Count -eq 0) {
        #If Increment Grid is empty use all remaining space for Package Grid
        $WPFDataGridPack.MaxHeight = $RemainsSize
    }
    else {
        #$CountItems = 100 / ($WPFDataGridInc.Items.Count + $WPFDataGridPack.Items.Count)

        $WPFDataGridInc.MaxHeight = $WPFDataGridInc.Items.Count * ($WPFDataGridInc.ActualHeight + 5)
        $WPFDataGridPack.MaxHeight = $RemainsSize - $WPFDataGridInc.MaxHeight
        #$WPFDataGridPack.MaxHeight = $RemainsSize * (($WPFDataGridPack.Items.Count * $CountItems) / 100)
        #$WPFDatagridPack.MinHeight = 100
        #$WPFDataGridInc.MaxHeight = $RemainsSize * (($WPFDataGridInc.Items.Count * $CountItems) / 100)
        #$WPFDataGridInc.MinHeight = 100
    }
 
    $WPFDataGridPackHeight = $WPFDataGridPack.Items.Count * $WPFDataGridPack.ActualHeight
    $WPFDataGridIncHeight = $WPFDataGridInc.Items.Count * $WPFDataGridInc.ActualHeight

}   


#region XAML Reader
# where is the XAML file?
$xamlFile = "H:\Dropbox (Data)\TWIVisualStudioProcets\Powershell\LicFileReader\LicFileReader\LicFileReader\LicenseGrid.xaml"

$inputXML = Get-Content $xamlFile -Raw
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $Form = [Windows.Markup.XamlReader]::Load( $reader )
}
catch {
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}

#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
  
$xaml.SelectNodes("//*[@Name]") | ForEach-Object { "trying item $($_.Name)";
    try { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop }
    catch { throw }
}
 
Function Get-FormVariables {
    if ($global:ReadmeDisplay -ne $true) { Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true }
    write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    get-variable WPF*
} 
Get-FormVariables
#endregion XAML Reader


[Reflection.Assembly]::LoadWithPartialName("System.Drawing")
function screenshot([Drawing.Rectangle]$bounds, $path) {



 


    $bmp = New-Object Drawing.Bitmap $bounds.width, $bounds.height
    $graphics = [Drawing.Graphics]::FromImage($bmp)

    $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

    $bmp.Save($path)

    $graphics.Dispose()
    $bmp.Dispose()
}




$WPFRead.add_Click( {
        <#  $Form | Save-Screenshot -AsPng -outputPath .\LockButton.jpg #>
        $Form.Height
        $Form.Width

        $Form.Top
        $Form.Left



        $bounds = [Drawing.Rectangle]::FromLTRB($Form.Left, $Form.Top, $Form.Left + $Form.Width, $Form.Top + $Form.Height)
        screenshot $bounds "C:\temp\screenshot.png"
    })

$i = 0
do {
    $SingleHeader = [pscustomobject]@{Seats = $i; Feature = "test"; FeatureCode = "test2"; SerialNumber = 12552255; IssueDate = ""; Expiration = "" }
    $WPFDatagridInc.AddChild($SingleHeader)
    $i = $i + 1
} until ($i -eq 30)
#Create Custom Object


#===========================================================================
# Shows the form
#===========================================================================
#Initialize Form
#$Form.Icon = $MainformIcon

#SizeCalc
$Form.ShowDialog() | out-null