#Start Lic File
$LicenseFile = $null
$LicenseFile = "H:\Dropbox (Data)\TWIWork\01_MuM\04_Programmierung\06_Powershell\Tools\LicFileReader\lic\cadlan.lic"
#$LicenseFile = "H:\Dropbox (Data)\TWIWork\01_MuM\04_Programmierung\06_Powershell\Tools\LicFileReader\Rosta New - Kopie.lic"

$FeatureCodes = "H:\Dropbox (Data)\TWIWork\01_MuM\04_Programmierung\06_Powershell\Tools\LicFileReader\FeatureCodes.txt"

$FeatureHashtable = Get-Content -Path "H:\Dropbox (Data)\TWIWork\01_MuM\04_Programmierung\06_Powershell\Tools\LicFileReader\FeatureCodes.txt" | ConvertFrom-StringData

$logFile = "StartFile"
$logFile | Out-File 'Logfile.txt'

$string = "*INCREMENT*"
$lineNumber = 0
$IncrementArray = $null #make sure it is empty

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
        "Single Product" | Out-File 'Logfile.txt' -Append
        $SingleHeader | Out-File 'Logfile.txt' -Append
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
        "Package" | Out-File 'Logfile.txt' -Append
        $PackageHeader | Out-File 'Logfile.txt' -Append


        #===========================================================================
        # Components
        #===========================================================================
        $Component = $PackageArray -match '\"(.*?)\"' #regex match between " to "
        $ComponentParts = $Matches[0].Split(" ")
    
        for ($i = 0; $i -lt $ComponentParts.length; $i++) {
        
            $FeatureCodeCleaned = $ComponentParts[$i] -replace '[\\]+', '' -replace '"', "" -replace '\s', ""  #remove backslash ; remove apostrophe; remove all whitespace
            $ProductLine = $FeatureHashtable.$FeatureCodeCleaned

            $IncrementLine = [pscustomobject]@{Feature = $ProductLine; FeatureCode = $FeatureCodeCleaned }
            "Product" | Out-File 'Logfile.txt' -Append
            $IncrementLine | Out-File 'Logfile.txt' -Append    
        }
        Write-Host $PackageArray
    }


}

#===========================================================================
# Read Line after Line
#===========================================================================

foreach ($line in [System.IO.File]::ReadLines($LicenseFile)) {   
    $lineNumber++
    
    if ($line | Where-Object { $_ -like $string }) {
        Write-Host "Linenumber" + $lineNumber
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



