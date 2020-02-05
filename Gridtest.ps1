[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 				| out-null
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')      				| out-null
[System.Reflection.Assembly]::LoadFrom('res\assembly\MahApps.Metro.dll')       				| out-null
[System.Reflection.Assembly]::LoadFrom('res\assembly\System.Windows.Interactivity.dll') 	| out-null

##############################################################
#                      LOAD FUNCTION                         #
##############################################################
                      
# Load MainWindow
$XamlMainWindow=(New-Object System.Xml.XmlDocument)
$XamlMainWindow.Load("H:\Dropbox (Data)\TWIVisualStudioProcets\Powershell\LicFileReader\LicFileReader\LicFileReader\GridTest.xaml")
$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form=[Windows.Markup.XamlReader]::Load($Reader)


##############################################################
#                CONTROL INITIALIZATION                      #
##############################################################

$Grid = $Form.FindName("DataGrid")

$Grid.AddChild([pscustomobject]@{Name='Stephen';Type=123})
$Grid.AddChild([pscustomobject]@{Name='Geralt';Type=234})
$Grid.AddChild([pscustomobject]@{Name='Geralt2';Type=234})
$Grid.AddChild([pscustomobject]@{Name='Geralt3';Type=234})

$Form.ShowDialog() | Out-Null