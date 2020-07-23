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

#Load ScreenshotFunction
. .\Take-ScreenShot.ps1

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


#Reset globals
$global:WPFInputString = $null
$Script:Files = $null
$Script:Lineindex = 0

##############################################################
#                Config                                      #
##############################################################
function New-Config {
    #Checks for target directory and creates if non-existent 
    if (!(Test-Path -Path "$Path\res\settings")) {
        New-Item -ItemType Directory -Path "$Path\res\settings"
    }
	
    #Setup default preferences	
    #Creates hash table and .clixml config file
    $Config = @{
        'ScreenshotSavePath' = ""
    }
    $Config | Export-Clixml -Path "$Path\res\settings\options.config"
    Import-Config
} #end function New-Config

function Import-Config {
    #If a config file exists for the current user in the expected location, it is imported
    #and values from the config file are placed into global variables
    if (Test-Path -Path "$Path\res\settings\options.config") {
        try {
            #Imports the config file and saves it to variable $Config
            $Config = Import-Clixml -Path "$Path\res\settings\options.config"
			
            #Creates global variables for each config property and sets their values
            $global:SaveFolder = $Config.ScreenshotSavePath
            #Set path in settings flyout on start
            $WPFSavePath.Text = $global:SaveFolder         
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("An error occurred importing your Config file. A new Config file will be generated for you. $_", 'Import Config Error', 'OK', 'Error')
            New-Config
        }
    } #end if config file exists
    else {
        New-Config
    }
} #end function Import-Config

function Update-Config {
    #Creates a new Config hash table with the current preferences set by the user
    $Config = @{
        'ScreenshotSavePath' = $global:SaveFolder 
    }
    #Export the updated config
    $Config | Export-Clixml -Path "$Path\res\settings\options.config"
} #end function Update-Config

##############################################################
#                Functions                                   #
##############################################################
Function ClearFunction {
    $WPFDataGridPack.Items.Clear()
    $WPFDataGridInc.Items.Clear()
    $WPFTextbox.Clear()
    $WPFParsedLicenseFileValue.Text = $null
    $WPFLicenseTypeValue.Text = $null
    $WPFComputerHostnameValue.Text = $null
    $WPFMACAdressValue.Text = $null
    $global:WPFInputString = $null
    $global:ServerName = $null
    $global:MACAdress = $null
    $Script:Files = $null
    $global:FileName = $null
    $Script:Lineindex = 0
    $global:LicenseTypeValue = $null
}

Function ClearBeforeRead {
    $WPFDataGridPack.Items.Clear()
    $WPFDataGridInc.Items.Clear()
    $WPFParsedLicenseFileValue.Text = $null
    $WPFLicenseTypeValue.Text = $null
    $WPFComputerHostnameValue.Text = $null
    $WPFMACAdressValue.Text = $null
    $global:ServerName = $null
    $global:MACAdress = $null
    $global:LicenseTypeValue = $null
    $Script:Lineindex = 0
}

function ClearText {
    $WPFTextbox.Clear()
    $WPFParsedLicenseFileValue.Text = $null
    $WPFLicenseTypeValue.Text = $null
    $WPFComputerHostnameValue.Text = $null
    $WPFMACAdressValue.Text = $null  
    $WPFDataGridPack.Items.Clear()
    $WPFDataGridInc.Items.Clear()
    $global:WPFInputString = $null
    $global:ServerName = $null
    $global:MACAdress = $null
    $Script:Files = $null
    $global:FileName = $null
}
Function ClearDroppedFile {
    $Script:Files = $null
    $WPFTextBlockDrop.Text = $null  
    $WPFParsedLicenseFileValue.Text = $null
    $WPFLicenseTypeValue.Text = $null
    $WPFComputerHostnameValue.Text = $null
    $WPFMACAdressValue.Text = $null
    $WPFDataGridPack.Items.Clear()
    $WPFDataGridInc.Items.Clear()
    $global:ServerName = $null
    $global:MACAdress = $null
    $Script:Files = $null
    $global:FileName = $null
}

Function Get-Folder($initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"

    if ($foldername.ShowDialog() -eq "OK") {
        $folder += $foldername.SelectedPath
    }
    return $folder
}


Function ReadSource {
    #Start Lic File
    $LicenseFile = $null
    $IncrementArray = $null

    #groupnumber to extend or collapse
    $global:z = 1
    
    If ($Script:Files -eq $null) {
        #Text pasted
        $global:WPFInputString | Out-File ($env:TEMP + "\TempLicFile.txt")
        $LicenseFile = $env:TEMP + "\TempLicFile.txt"
        $LicenseFileString = Get-Content -Path $LicenseFile -Raw | Where-Object { $_.Trim() -ne '' } #dont add empty lines
    }
    else {
        #file dropped
        $LicenseFile = $Files
        $LicenseFileString = Get-Content -Path $LicenseFile -Raw | Where-Object { $_.Trim() -ne '' } #dont add empty lines
    }

    # Get FeatureCodeList
    $FeatureHashtableN = Get-Content -Path "H:\Dropbox (Data)\TWIProgrammierung\Autodesk\LicFileReader\FeatureCodes.txt" | ConvertFrom-StringData

    #Define Server and Macadress
    #regex find for serverlines and then splitting them up / special case if there are 3 servers

    $ServerLine = $LicenseFileString | Select-String -pattern 'SERVER\s\w+\s\w{12}' -AllMatches
    
    #decide if singel or redundant
    if ($ServerLine.Matches.Length -eq 3) {
        $ServerLineParts0 = $ServerLine.Matches[0].Value.Split(" ")
        $ServerLineParts1 = $ServerLine.Matches[1].Value.Split(" ")
        $ServerLineParts2 = $ServerLine.Matches[2].Value.Split(" ")

        $global:ServerName = $ServerLineParts0[1] + "  /  " + $ServerLineParts1[1] + "  /  " + $ServerLineParts2[1] 
        $global:MACAdress = $ServerLineParts0[2] + "  /  " + $ServerLineParts1[2] + "  /  " + $ServerLineParts2[2]
        $global:LicenseTypeValue = "Redundant"
    }
    else {
        if ($ServerLine) {
            $ServerLineParts = $ServerLine.Matches[0].Value.Split(" ")
            $global:ServerName = $ServerLineParts[1]
            $global:MACAdress = $ServerLineParts[2]
            $global:LicenseTypeValue = "Single / Distributed"
        }
        else {
            $global:ServerName = "Not found!"
            $global:MACAdress = "Not found!"
            $global:LicenseTypeValue = "Not defined!"
        }
    }

    #===========================================================================
    # Build Package and Increment Blocks
    #===========================================================================
 
    $PackageBlocks = $LicenseFileString | Select-String  -pattern 'PACKAGE.*((.|\n)+?)ISSUED=\d{2}-\w{3}-\d{4}' -AllMatches
    $IncrementBlocksAll = $LicenseFileString | Select-String  -pattern 'INCREMENT.*((.|\n)+?)SN=\d{3}-\d{8}' -AllMatches
    $IncrementsSingleProduct = @()
    $IncrementsPackage = @()
    
    #Define if Increment is belonging to Package or is single product
    Foreach ($item in $IncrementBlocksAll.Matches) {
        $result = $item.Value.Split(" ")
        If ($result[1] | Select-String -Pattern '_\d{1,4}_0F') {
            $IncrementsSingleProduct += $item
        }
        else {
            $IncrementsPackage += $item
        }
    }
    CheckPackage
    CheckIncrement
}

Function CheckIncrement {
    $iNr = 0
    Foreach ($item in $IncrementsSingleProduct) {
 
        $IncrementParts = $IncrementsSingleProduct[$iNr].Value.Split(" ")

        for ($t = 0; $t -lt $IncrementParts.length; $t++) {
            $IncrementParts[$t] = $IncrementParts[$t] -replace '[\\]+', '' -replace '"', "" -replace '\s', ""   #remove backslash ; remove apostrophe; remove all whitespace
        }
        
        #Seat Count
        $varSeat = $IncrementParts[5]
        #Product Name (Feature)
        $varFeature = $FeatureHashtableN.($IncrementParts[1])
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
        $IncrementHeader = [pscustomobject]@{Seats = $varSeat; Feature = $varFeature; FeatureCode = $varFeatureCode; SerialNumber = $varSerialNumber; IssueDate = $varIssueDate; Expiration = $varExpiration }
        $WPFDatagridInc.AddChild($IncrementHeader)
        $iNr = $iNr + 1
    }
}
Function CheckPackage {
    $pNr = 0
    $MatchingIncrementBlock = @()
    Foreach ($item in $PackageBlocks.Matches) {
        $MatchingIncrementBlock = $null
        $PackageParts = $PackageBlocks.Matches[$pNr].Value.Split(" ")

        for ($t = 0; $t -lt $PackageParts.length; $t++) {
            $PackageParts[$t] = $PackageParts[$t] -replace '[\\]+', '' -replace '"', "" -replace '\s', ""   #remove backslash ; remove apostrophe; remove all whitespace
        }

        #create searchterm
        $IdentificationNr = "*" + $PackageParts[1].ToString() + "*"

        $t = 0
        #search for matching increment (this is needed to get some info that is not present in package block, like seat number and expiration)
        Foreach ($item in $IncrementsPackage) {
            $MatchingIncrementBlock += $IncrementsPackage[$t] | Where-Object { $_ -like $IdentificationNr }
            if ($MatchingIncrementBlock) {
                break #if found stop search / saves time
            }
            else {
                $t = $t + 1
            }
        }

        $MatchingIncrementBlockParts = $MatchingIncrementBlock.Value.Split(" ")

        for ($t = 0; $t -lt $MatchingIncrementBlockParts.length; $t++) {
            $MatchingIncrementBlockParts[$t] = $MatchingIncrementBlockParts[$t] -replace '[\\]+', '' -replace '"', "" -replace '\s', ""   #remove backslash ; remove apostrophe; remove all whitespace
        }

        #Seat Count
        $varSeat = $MatchingIncrementBlockParts[5]
        #Product Name (Feature)
        $varFeature = $FeatureHashtableN.($MatchingIncrementBlockParts[1])
        #FeatureCode
        $varFeatureCode = $MatchingIncrementBlockParts[1]
        #SerialNumber
        $varSerialNumber = $MatchingIncrementBlockParts | Where-Object { $_ -like "*SN=*" }
        $varSerialNumber = $varSerialNumber.SubString(3, $varSerialNumber.length - 3)
        #Issue Date
        $varIssueDate = $MatchingIncrementBlockParts | Where-Object { $_ -like "*ISSUED=*" }
        $varIssueDate = $varIssueDate.Substring(7, $varIssueDate.Length - 7)
        #Expiration Date
        $varExpiration = $MatchingIncrementBlockParts | Select-String -pattern '^\d{2}[\-]\w{3}[\-]\d{4}'
        If ($varExpiration -eq $null) {
            $varExpiration = "Permanent" #If there is no regex pattern matching it goes to permanent
        }

        #===========================================================================
        # Package Header
        #===========================================================================
        #Create Custom Object and add it to the grid
        $PackageHeader = [pscustomobject]@{Seats = $varSeat; Feature = $varFeature; FeatureCode = $varFeatureCode; SerialNumber = $varSerialNumber; IssueDate = $varIssueDate; Expiration = $varExpiration; Main = "True"; groupNumber = $z ; Expanded = "True"; Lineindex = $Script:Lineindex }
        $WPFDatagridPack.AddChild($PackageHeader)
        $Script:Lineindex = $Script:Lineindex + 1

        #===========================================================================
        # Components Line (what belongs to the package)
        #===========================================================================
        $matches = ([regex]'\d{5}\w{3,8}_\d{4}_0F').Matches($PackageParts)
    
        for ($i = 0; $i -lt $matches.count; $i++) {
        
            $ProductLine = $FeatureHashtableN.$($matches[$i].value)

            $IncrementLine = [pscustomobject]@{Seats = " " ; Feature = $ProductLine; FeatureCode = $matches[$i].value; Main = "False"; groupNumber = $z; Lineindex = $Script:Lineindex } #Seat is set to " " so it triggers style template from xaml
            $WPFDatagridPack.AddChild($IncrementLine)
            $Script:Lineindex = $Script:Lineindex + 1  
        }
        
        #next Package
        $pNr = $pNr + 1
        $global:z = $z + 1 #for referencing itemrow later (mainrow and secondrows have the same number)
    }
 

}


Function Fillout {
    If ($global:FileName -eq $null) {
        $WPFParsedLicenseFileValue.Text = "Input String"
    }
    else {
        $WPFParsedLicenseFileValue.Text = $global:FileName
    }
    

    $WPFLicenseTypeValue.Text = $LicenseTypeValue
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
    elseif ($WPFDataGridPack.Items.Count -eq 0) {
        #If Package Grid is empty use all remaining space for Increment Grid
        $WPFDataGridInc.MaxHeight = $RemainsSize
    }
    else {
        $WPFDataGridInc.MaxHeight = 0.3 * $RemainsSize
        $WPFDataGridPack.MaxHeight = 0.7 * $RemainsSize
    }
 
    <#    $WPFDataGridPackHeight = $WPFDataGridPack.Items.Count * $WPFDataGridPack.ActualHeight
    $WPFDataGridIncHeight = $WPFDataGridInc.Items.Count * $WPFDataGridInc.ActualHeight #>

}   

#region XAML Reader
# where is the XAML file?
$xamlFile = $path + "\res\LicenseGrid.xaml"

$inputXML = Get-Content $xamlFile -Raw
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
$inputXML | Out-File "C:\temp\XML.txt"
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

#Load Config
Import-Config

##############################################################
#                MANAGE EVENTS ON PANEL                      #
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

            if ($FileString.Substring($FileString.Length - 4) -eq ".lic" -or $FileString.Substring($FileString.Length - 4) -eq ".txt" ) {
                #Textfiles or Licfiles allowed
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
        ClearText #Clear Grid
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
        $WPFTextBlockDrop.Text = "Drop File here" #Reset text
        ClearFunction
    })

$WPFRead.add_Click( {
        #Check if there is input. Dropped File or Textinput / else show Warning Dialog
        If ($Script:Files -eq $null) {
            If ($global:WPFInputString -eq $null) {
                $ok = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
                [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form, "Read", "Nothing to read. No Input.", $ok)
            }
            else {
                ClearBeforeRead
                ReadSource
                Fillout
                SizeCalc
            }
        }
        else {
            ClearBeforeRead
            ReadSource
            Fillout
            SizeCalc
        }
    })

$WPFParsedLicenseFileValue.add_MouseRightButtonUp( {
        $WPFParsedLicenseFileValue.Text | Set-Clipboard
        $WPFInfoDialog.IsOpen = $true  
    })

$WPFLicenseTypeValue.add_MouseRightButtonUp( {
        $WPFLicenseTypeValue.Text | Set-Clipboard
        $WPFInfoDialog.IsOpen = $true  
    })

$WPFComputerHostNameValue.add_MouseRightButtonUp( {
        $WPFComputerHostNameValue.Text | Set-Clipboard
        $WPFInfoDialog.IsOpen = $true     
    })

$WPFMACAdressValue.add_MouseRightButtonUp( {
        $WPFMACAdressValue.Text | Set-Clipboard
        $WPFInfoDialog.IsOpen = $true     
    })

$WPFTextbox.Add_TextChanged( {
        ClearDroppedFile #Clear any File that was dropped
        $WPFTextBlockDrop.Text = "Drop File here" #Reset text
        $global:WPFInputString = $WPFTextbox.Text
    })

$WPFSettingsButton.Add_Click( {
        $WPFFlyOutContent.IsOpen = $true 
    })

$WPFScreenshot.Add_click( {
        $SaveFileDialog = New-Object windows.forms.savefiledialog   
        $SaveFileDialog.initialDirectory = [System.IO.Directory]::GetCurrentDirectory()   
        $SaveFileDialog.title = "Save File to Disk"   
        $SaveFileDialog.filter = "PNG|*.png" 
        $result = $SaveFileDialog.ShowDialog()    
        $result 
        if ($result -eq "OK") {    
            Write-Host "Selected File and Location:"  -ForegroundColor Green  
            $SaveFileDialog.filename   
            Take-ScreenShot -activewindow -file $SaveFileDialog.filename  -imagetype png 
        } 
        else { Write-Host "File Save Dialog Cancelled!" -ForegroundColor Yellow }  
    })

$WPFFastScreenshot.Add_Click( {
        
        if ($global:SaveFolder -ne $null -or $global:SaveFolder -ne "" ) {
            If (Test-Path $global:SaveFolder) {
                $global:SaveString = $global:SaveFolder + "\" + (get-date).ToString("dd-MM-yyyy HH_mm_ss") + ".png"
                Take-ScreenShot -activewindow -file $global:SaveString -imagetype png
                Write-Host "Screenshot Saved to $global:SaveFolder" -ForegroundColor Green 
            }
            else {
                $ok = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
                [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form, "Path not valid", "Save path does not exist. Define a new one from settings.", $ok)
            }

            
        }
        else {
            $ok = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form, "No save path", "No save path defined. Check settings.", $ok)
        }
    })

$WPFOpenPath.Add_Click( {
        $global:SaveFolder = Get-Folder
        $WPFSavePath.Text = $global:SaveFolder
        Update-Config 
    })

$WPFHelpButton.Add_click( {
        Start-Process "https://github.com/TWiesendanger/LicFileReader"
    })

$WPFDataGridPack.Add_PreviewMouseDoubleClick( {
        $items = @()
        $varName = "ItemArray"
        if ($WPFDataGridPack.SelectedItem.Main -eq "True") {
            $gNumber = $WPFDataGridPack.SelectedItem.groupNumber
            $mainItem = $WPFDataGridPack.SelectedItem

            
            #Selected Item is Expanded
            if ($WPFDataGridPack.SelectedItem.Expanded -eq "True") {
                Foreach ($item in $WPFDataGridPack.Items) {
                    if ($item.groupNumber -eq $gNumber) {
                        if ($item -ne $WPFDataGridPack.SelectedItem) {
                            $items += $item #build array to remove and later add (cant remove here / changes iteration which is not allowed)
                        }
                    }
                }
                
                New-Variable -Name ${varName}${gNumber} -Value $items -Scope global -Force
                    
                foreach ($item in $items) {
                    $WPFDataGridPack.Items.Remove($item)
                }
                $WPFDataGridPack.SelectedItem.Expanded = "False"
            }
            #Selected Item is not Expanded
            else {
                $addVar = Get-Variable -Name ${varName}${gNumber}
                $mainRowIndex = $WPFDataGridPack.Items.IndexOf($mainItem)
                foreach ($item in $addVar.Value) {
                    # $WPFDataGridPack.Items.Insert($item.Lineindex, $item)
                    $WPFDataGridPack.Items.Insert($mainRowIndex + 1, $item)

                }
                #destroy the array
                Write-Host $((Get-Variable -Name ${varName}${gNumber})).Name
                $((Get-Variable -Name ${varName}${gNumber})).Value = $null
                $WPFDataGridPack.SelectedItem.Expanded = "True"
            }          
        }
    })

#===========================================================================
# Shows the form
#===========================================================================
#Initialize Form
#$Form.Icon = $MainformIcon

$Form.ShowDialog() | out-null
#$WPFDataGridPack | Get-Member -Type Event
#Delete Temp Files created
if (Test-Path -Path ($env:TEMP + "\TempLicFile.txt")) {
    try {
        Remove-Item -path ($env:TEMP + "\TempLicFile.txt")
    }
    catch { }
}

Write-Host $performance
