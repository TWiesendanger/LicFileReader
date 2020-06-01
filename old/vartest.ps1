<# $number = 13
$test = "Test"

New-Variable ${test}${number} -value @()

Get-Variable ${test}${number} -value 5

Write-Host $test$number
 #>


$data = @{}
for ($i=1; $i -le 5; $i++) { $data["var$i"] = $i; Write-Host $data["var$i"] }




<# Write-Host Get-Variable -Name "test$number" -ValueOnly
$arraytest = Get-Variable -Name "test$number" -ValueOnly 

$ #>