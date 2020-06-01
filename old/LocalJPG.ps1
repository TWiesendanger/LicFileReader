#=============================================================================#
# PowerShell script  for coolOrange powerJobs                                 #
# Creates a JPG file and adds it to Autodesk Vault as Design Vizualization    #                                                                             
#=============================================================================#

#region Debug
if ( $IAmRunningInJobProcessor -ne $true) {
    Import-Module powerJobs
    $global:powerJobs = Get-PowerJobs

    Open-VaultConnection -Server server06 -Vault Vault -User JobProzessor -Password "JobProzessor"
    $file = Get-VaultFile -File "$/Designs/00978.idw"

}

#ne = not equal / der oben gelistete Code wird nur ausgeführt wenn der Job Manuell angestossen wird
#endregion

$hidePDF = $false
$workingDirectory = "C:\Temp\$($file._Name)"
$Zeichnungsnummer1 = $file.'Zeichnung Nr.'

$Zeichnungsnummer = $Zeichnungsnummer1.Replace('/', '_')

Write-Host $Zeichnungsnummer

$localJPGLocation = "\\PROALPHA01\proalpha\pa-de-62e00\production\zv\jpg\" + $file._PartNumber + "-" + $file._Revision + "_" + $file.Artikelnummer + "_" + $Zeichnungsnummer + ".jpg"
#$localJPGLocation = "\\PROALPHA01\proalpha\pa-de-62e00\production\zv\jpg\" + $file._PartNumber +"-"+ $file._Revision + "-" + $file.Artikelnummer + "-" +  $file.'Zeichnung Nr.' + ".jpg"
$localPDFfileLocation = "$workingDirectory\$($file._Name).pdf"
$vaultJPGfileLocation = $file._EntityPath + "/" + (Split-Path -Leaf $localJPGLocation)
$fastOpen = $file._Extension -eq "idw" -or $file._Extension -eq "dwg" -and $file._ReleasedRevision


#region Function Convert PDF to JPG
 
function ConvertPdfToImage ($OriginalFile, $NewFile) {
    #Path to Ghostscript EXE
    $tool = 'C:\Program Files\gs\gs9.27\bin\gswin64c.exe'
   
    #Directory containing the PDF files that will be converted
    $inputDir = $OriginalFile
 
    #Output path where the TIF files will be saved
    $outputDir = $NewFile
 
    $pdf = get-childitem $OriginalFile
    $jpg = $outputDir
    Remove-Item $jpg -Force -ErrorAction SilentlyContinue
    'Processing ' + $pdf.Name       

    $param = "-sOutputFile=$jpg"
    & $tool -q -dNOPAUSE -sDEVICE=jpeg $param -r150 $pdf.FullName -c quit
}

#endregion

#region Create PDF and then convert
Write-Host "Starting job 'Create PDF to get a JPG' for file '$($file._Name)' ..."

if ( @("idw", "dwg") -notcontains $file._Extension ) {
    Write-Host "Files with extension: '$($file._Extension)' are not supported"
    return
}

$downloadedFiles = Save-VaultFile -File $file._FullPath -DownloadDirectory $workingDirectory -ExcludeChildren:$fastOpen -ExcludeLibraryContents:$fastOpen
$file = $downloadedFiles | select -First 1
$openResult = Open-Document -LocalFile $file.LocalPath -Options @{ FastOpen = $fastOpen } 

if ($openResult) {
    if ($openResult.Application.Name -like 'Inventor*') {
        $configFile = "C:\ProgramData\coolOrange\powerJobs\Jobs\Settings.Custom\Inventor_Default_to_PDF.ini"
    }
    else {
        $configFile = "C:\ProgramData\coolOrange\powerJobs\Jobs\Settings.Custom\PDF.dwg" 
    }                  
    $exportResult = Export-Document -Format 'PDF' -To $localPDFfileLocation -Options $configFile


    if ($exportResult) {  
        ConvertPdfToImage -OriginalFile $localPDFfileLocation -NewFile $localJPGLocation
    
        #$JPGFile = Add-VaultFile -From $localJPGLocation -To $vaultJPGfileLocation -FileClassification DesignVisualization

     
         
        #$updated = Update-VaultFile -File $JPGFile._FullPath -Category 'Nebendateien'
        #$file = Update-VaultFile -File $file._FullPath -AddAttachments @($JPGFile._FullPath)

    }
    $closeResult = Close-Document
}

#endregion

Clean-Up -folder $workingDirectory

if (-not $openResult) {
    throw("Failed to open document $($file.LocalPath)! Reason: $($openResult.Error.Message)")
}
if (-not $exportResult) {
    throw("Failed to export document $($file.LocalPath) to $localPDFfileLocation! Reason: $($exportResult.Error.Message)")
}
if (-not $closeResult) {
    throw("Failed to close document $($file.LocalPath)! Reason: $($closeResult.Error.Message))")
}
Write-Host "Completed job 'Create JPG as attachment'"