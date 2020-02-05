#TODO
#Paste Text from Clipboard
#Multiple Files

#Next Step
#Fill Grid with Product Information from Grid



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

Write-Host $Path
$MainformIcon = $Path + "\res\mum.png"


#===========================================================================
#Functions
#===========================================================================


Function CreateIncrement {

    #Line 1
    $lineNo = 1
    $IncrementLine = ($IncrementArray -split '\r?\n')[$lineNo - 1]  # -> 'line 1 Increment

    $IncrementLineParts = $IncrementLine.Split(" ")

    $Featurecode = $IncrementLineParts[1]
    $ExpirationDate = $IncrementLineParts[4]

    #Line 4
    $lineNo = 4
    $IssuedLine = ($IncrementArray -split '\r?\n')[$lineNo - 1]  # -> 'line 4 Issued / SerialNr

    $IssuedLineParts = $IssuedLine.Split(" ")

    $IssuedDate = $IssuedLineParts[0].Substring(8)
    $SerialNr = $IssuedLineParts[2].Substring(3)


    Write-Host "Feature Code: $Featurecode"  
    Write-Host "Expiration Date: $ExpirationDate"  
    Write-Host "Issue Date: $IssuedDate"  
    Write-Host "Serial Number: $SerialNr"  

}

Function ReadSource {
    #Start Lic File
    $LicenseFile = $null
    $LicenseFile = $Files

    # #Get FeatureCodeList
    $content = ( Get-Content "H:\Dropbox (Data)\TWIWork\01_MuM\04_Programmierung\06_Powershell\Tools\LicFileReader\FeatureCodes.txt" | Out-String )
    $Hashtable = ( Invoke-Expression $content )

    #Define Server and Macadress
    $ServerLine = Get-Content $LicenseFile | Where-Object { $_ -like "*Server*" }
    $ServerLineParts = $ServerLine.Split(" ")
    $global:ServerName = $ServerLineParts[1]
    $global:MACAdress = $ServerLineParts[2]


    #Write-Host $IncrementBlock
    $string = "*INCREMENT*"
    $lineNumber = 0
    $IncrementArray = $null #make sure it is empty

    foreach ($line in [System.IO.File]::ReadLines($LicenseFile)) {   
        $lineNumber++
        if ($line | Where-Object { $_ -like $string }) {
            Write-Host "Linenumber" + $lineNumber
            if ($line | Where-Object { $_ -like "PACKAGE" }) {
                CreateIncrement
                $string = "*INCREMENT*"
            }
            else {
                    
                $IncrementArray += $line
                $string = "*"
                $IncrementArray += " `n" #New Line
            }
        }        
    }

    Write-Host $IncrementArray
}

Function Fillout {
    $WPFParsedLicenseFileValue.Text = $FileName
    $WPFLicenseTypeValue.Text = "Single / Distributed"
    $WPFComputerHostnameValue.Text = $ServerName
    $WPFMACAdressValue.Text = $MACAdress
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

$WPFTest.Add_Click( {
        $NewButton2 = New-Object System.Windows.Controls.Label
        $newButton2.Name = "SecondLabel"

        $row1 = new-object system.windows.controls.rowdefinition
        $text1 = New-Object System.Windows.Controls.TextBlock
        $text1.Text = "TEST"

        $row1.height = "Auto"

        $WPFDataGrid | Get-Member 

        $WPFDataGrid.RowDefinitions.Add($row1)
        # $WPFDataGrid.SetRow($text1,1)
        # $WPFDataGrid.SetColumn($text1,0)

        #$WPFDataGrid.Rows[1].Cells[1].Value ="Test"

        $WPFDataGrid.SetRow($text1, 1)
        $WPFDataGrid.SetColumn($text1, 0)
    })


$WPFSource.Add_PreviewDragOver( {
        [System.Object]$script:sender = $args[0]
        [System.Windows.DragEventArgs]$e = $args[1]


        $Script:Files = $e.Data.GetData([System.Windows.DataFormats]::FileDrop)
        If ($Files.Count -gt 1) {
            $e.Effects = [System.Windows.DragDropEffects]::None #Show Icon not allowed (Only one File)
            $WPFTextBlockDrop.Text = "Only 1 File allowed!"
        }
        else {
            #Write-Host $Files[0]
            #Convert System.String to String
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

        [System.Object]$script:sender = $args[0]
        [System.Windows.DragEventArgs]$e = $args[1]
    

        If ($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {

            $Script:Files = $e.Data.GetData([System.Windows.DataFormats]::FileDrop)
            $FileName = [System.IO.Path]::GetFileName($Files)
            Write-Host $FileName
            $WPFTextBlockDrop.Text = $FileName
            ReadSource
            Fillout
        }
    })


#===========================================================================
# Shows the form
#===========================================================================
#Initialize Form
#$Form.Icon = $MainformIcon

$Form.ShowDialog() | out-null






# #Get Increments / Feature Code / Date (Use Increment Block to limit search) / Create Function for this later
# # $Increment =  $IncrementBlock | Where-Object {$_ -like 'INCREMENT*'}
# # $IncrementParts = $Increment.Split(" ")
# # Write-Host "---------------------"
# # Write-Host $IncrementParts[0]
# # Write-Host $IncrementParts[1]
# # Write-Host $IncrementParts[2]
# # Write-Host $IncrementParts[3]
# # Write-Host $IncrementParts[4]



# $FeatureCode = $IncrementParts[1]
# $Date = $IncrementParts[4]
# Write-Host $Date
# Write-Host $FeatureCode

# #Get Product Name
# $Product = $Hashtable.Get_Item($FeatureCode)
# Write-Host $Product

# #Get Issue Date and Serial
# $IssuedLine = Get-Content $LicenseFile | Where-Object {$_ -like '*ISSUED*'}
# Write-Host $IssuedLine
# $IssuedLineParts = $IssuedLine.Split(" ")
# Write-Host $IssuedLineParts[0]
# Write-Host $IssuedLineParts[1]
# Write-Host $IssuedLineParts[2]