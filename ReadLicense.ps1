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


##############################################################
#                Functions                       #
##############################################################
Function ClearFunction {
    $WPFDataGridPack.Items.Clear()
    $WPFDataGridInc.Items.Clear()
    $WPFTextbox.Clear()
    $WPFParsedLicenseFileValue.Text = $null
    $WPFLicenseTypeValue.Text = $null
    $WPFComputerHostnameValue.Text = $null
    $WPFMACAdressValue.Text = $null
}

Function CheckPackage {

    #===========================================================================
    # Clean Up
    #===========================================================================
    $IncrementParts = $IncrementArray.Split(" ")

    for ($t = 0; $t -lt $IncrementParts.length; $t++) {
        $IncrementParts[$t] = $IncrementParts[$t] -replace '[\\]+', '' -replace '"', "" -replace '\s', ""   #remove backslash ; remove apostrophe; remove all whitespace
    }

    #===========================================================================
    # Search for Package
    #===========================================================================
    $searchVar = ("Package " + $IncrementParts[1] + "*") #Package + Featurecode from Increment

    foreach ($line in [System.IO.File]::ReadLines($LicenseFile)) { 
        If ($line | Where-Object { $_ -like $searchVar }) {
            if ($line | Where-Object { $_ -like "*SIGN*" }) {
                $searchVar = "Stop"
            }
            else {
                    
                $PackageArray += $line
                $searchVar = "*"
            }
        }
    }


    #===========================================================================
    # Package
    #===========================================================================
    If ($PackageArray -eq $null) {
        #No Package found / Must be Single Product

        #Seat Count
        $varSeat = $IncrementParts[5]
        #Product Name (Feature)
        $varFeature = $FeatureHashtable.($IncrementParts[1])
        #FeatureCode
        $varFeatureCode = $IncrementParts[1]
        #SerialNumber
        $varSerialNumber = $IncrementParts | Where-Object { $_ -like "*SN=*" }
        $varSerialNumber = $varSerialNumber.SubString(3, $varSerialNumber.length - 3)
        #Issue Date
        $varIssueDate = $IncrementParts | Where-Object { $_ -like "*ISSUED=*" }
        $varIssueDate = $varIssueDate.Substring(7, $varIssueDate.Length - 7)
        #Expiration Date
        $varExpiration = $IncrementParts | Select-String -pattern '^\d{2}[\-]\w{3}[\-]\d{4}'
        If ($varExpiration -eq $null) {
            $varExpiration = "Permanent" #If there is no regex pattern matching it goes to permanent
        }

        #Create Custom Object
        $SingleHeader = [pscustomobject]@{Seats = $varSeat; Feature = $varFeature; FeatureCode = $varFeatureCode; SerialNumber = $varSerialNumber; IssueDate = $varIssueDate; Expiration = $varExpiration }
        $WPFDatagridInc.AddChild($SingleHeader)
        #Log
        #"Single Product" | Out-File 'Logfile.txt' -Append
        #$SingleHeader | Out-File 'Logfile.txt' -Append
    }
    else {
        #Build Header Custom Object

        #Seat Count
        $varSeat = $IncrementParts[5]
        #Product Name (Feature)
        $varFeature = $FeatureHashtable.($IncrementParts[1])
        #FeatureCode
        $varFeatureCode = $IncrementParts[1]
        #SerialNumber
        $varSerialNumber = $IncrementParts | Where-Object { $_ -like "*SN=*" }
        $varSerialNumber = $varSerialNumber.SubString(3, $varSerialNumber.length - 3)
        #Issue Date
        $varIssueDate = $IncrementParts | Where-Object { $_ -like "*ISSUED=*" }
        $varIssueDate = $varIssueDate.Substring(7, $varIssueDate.Length - 7)
        #Expiration Date
        $varExpiration = $IncrementParts | Select-String -pattern '^\d{2}[\-]\w{3}[\-]\d{4}'

        #Create Custom Object
        $PackageHeader = [pscustomobject]@{Seats = $varSeat; Feature = $varFeature; FeatureCode = $varFeatureCode; SerialNumber = $varSerialNumber; IssueDate = $varIssueDate; Expiration = $varExpiration }
        $WPFDatagridPack.AddChild($PackageHeader)

        #Log
        #"Package" | Out-File 'Logfile.txt' -Append
        #$PackageHeader | Out-File 'Logfile.txt' -Append


        #===========================================================================
        # Components
        #===========================================================================
        $Component = $PackageArray -match '\"(.*?)\"' #regex match between " to "
        $ComponentParts = $Matches[0].Split(" ")
    
        for ($i = 0; $i -lt $ComponentParts.length; $i++) {
        
            $FeatureCodeCleaned = $ComponentParts[$i] -replace '[\\]+', '' -replace '"', "" -replace '\s', ""  #remove backslash ; remove apostrophe; remove all whitespace
            $ProductLine = $FeatureHashtable.$FeatureCodeCleaned

            $IncrementLine = [pscustomobject]@{Seats = " " ; Feature = $ProductLine; FeatureCode = $FeatureCodeCleaned } #Seat is set to " " so it triggers style template from xaml
            $WPFDatagridPack.AddChild($IncrementLine)
            #Log
            #"Product" | Out-File 'Logfile.txt' -Append
            #$IncrementLine | Out-File 'Logfile.txt' -Append    
        }
    }


}

Function ReadSource {
    #Start Lic File
    $LicenseFile = $null
    $LicenseFile = $Files

    #Log
    #$logFile = "StartFile"
    #$logFile | Out-File 'Logfile.txt'

    $string = "*INCREMENT*"
    $lineNumber = 0
    $IncrementArray = $null #make sure it is empty

    # Get FeatureCodeList
    $FeatureHashtable = Get-Content -Path "H:\Dropbox (Data)\TWIWork\01_MuM\04_Programmierung\06_Powershell\Tools\LicFileReader\FeatureCodes.txt" | ConvertFrom-StringData

    #Define Server and Macadress
    $ServerLine = Get-Content $LicenseFile | Where-Object { $_ -like "*Server*" }
    $ServerLineParts = $ServerLine.Split(" ")
    $global:ServerName = $ServerLineParts[1]
    $global:MACAdress = $ServerLineParts[2]

    #===========================================================================
    # Read Line after Line
    #===========================================================================

    foreach ($line in [System.IO.File]::ReadLines($LicenseFile)) {   
        #$lineNumber++
    
        if ($line | Where-Object { $_ -like $string }) {
            if ($line | Where-Object { $_ -like "*SIGN*" }) {
                $IncrementArray += $line #still add this last found line
                CheckPackage
                $string = "*INCREMENT*"
                $IncrementArray = $null
            }
            else {
                
                $IncrementArray += $line
                $string = "*"
            }
        }        
    }
}

Function Fillout {
    $WPFParsedLicenseFileValue.Text = $global:FileName
    $WPFLicenseTypeValue.Text = "Single / Distributed"
    $WPFComputerHostnameValue.Text = $ServerName
    $WPFMACAdressValue.Text = $MACAdress
}

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

$WPFSource.AllowDrop = $True

##############################################################
#                MANAGE EVENT ON PANEL                       #
##############################################################


$WPFSource.Add_PreviewDragOver( {
        [System.Object]$script:sender = $args[0]
        [System.Windows.DragEventArgs]$e = $args[1]

        $Script:Files = $e.Data.GetData([System.Windows.DataFormats]::FileDrop)
        If ($Files.Count -gt 1) {
            $e.Effects = [System.Windows.DragDropEffects]::None #Show Icon not allowed (Only one File)
            $WPFTextBlockDrop.Text = "Only 1 File allowed!"
        }
        else {
            $FileString = "$Files"

            if ($FileString.Substring($FileString.Length - 4) -eq ".lic") {
                $e.Effects = [System.Windows.DragDropEffects]::Move
                $WPFTextBlockDrop.Text = "Drop File here"
            }
            else {
                $e.Effects = [System.Windows.DragDropEffects]::None
                $WPFTextBlockDrop.Text = "Wrong Filetype!"  
            }
        }  
        $e.Handled = $true
    })

$WPFSource.Add_DragLeave( {
        $WPFTextBlockDrop.Text = "Drop File here"
    })

$WPFSource.Add_Drop( {
        ClearFunction #Clear Grid
        [System.Object]$script:sender = $args[0]
        [System.Windows.DragEventArgs]$e = $args[1]
    
        If ($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {

            $Script:Files = $e.Data.GetData([System.Windows.DataFormats]::FileDrop)
            $global:FileName = [System.IO.Path]::GetFileName($Files)
            $WPFTextBlockDrop.Text = $FileName

        }
    })

$WPFReset.add_Click( {
        #Reset Drop File
        $Script:Files = $null
        $WPFTextBlockDrop.Text = $null  
        ClearFunction
    })

$WPFRead.add_Click( {
        If ($Script:Files -eq $null) {

        }
        else {
            ClearFunction
            ReadSource
            Fillout
            SizeCalc
        }    
    
    })

$WPFParsedLicenseFileValue.add_MouseRightButtonUp( {
        $WPFParsedLicenseFileValue.Text | Set-Clipboard    
    })

$WPFLicenseTypeValue.add_MouseRightButtonUp( {
        $WPFLicenseTypeValue.Text | Set-Clipboard    
    })

$WPFComputerHostNameValue.add_MouseRightButtonUp( {
        $WPFComputerHostNameValue.Text | Set-Clipboard    
    })

$WPFMACAdressValue.add_MouseRightButtonUp( {
        $WPFMACAdressValue.Text | Set-Clipboard    
    })



#===========================================================================
# Shows the form
#===========================================================================
#Initialize Form
#$Form.Icon = $MainformIcon

$Form.ShowDialog() | out-null
