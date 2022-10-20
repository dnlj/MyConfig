. .\helpers.ps1

$Extensions = @(
	"https://marketplace.visualstudio.com/items?itemName=KirAntipov.LineSorterByKir",
	"https://marketplace.visualstudio.com/items?itemName=MadsKristensen.AddNewFile64",
	"https://marketplace.visualstudio.com/items?itemName=MadsKristensen.AddNewFile",
	"https://marketplace.visualstudio.com/items?itemName=MikeWard-AnnArbor.VSColorOutput",
	"https://marketplace.visualstudio.com/items?itemName=MadsKristensen.ShowSelectionLength",
	"https://marketplace.visualstudio.com/items?itemName=stkb.Rewrap-18980",
	##"https://marketplace.visualstudio.com/items?itemName=idex.colorthemedesigner2022",
	"https://marketplace.visualstudio.com/items?itemName=thomaswelen.SelectNextOccurrence"
)

# TODO: BeeDarkTheme
# TODO: DocHelper

$Delay = 3 # Avoid HTTP 429
& { $ProgressPreference = 'SilentlyContinue'
foreach ($ext in $Extensions) {
	try {
		Start-Sleep -Seconds $Delay
		$content = $null
		$content = (Invoke-WebRequest -UseBasicParsing -Uri $ext).RawContent
		$html = New-Object -Com "HTMLFile"
		$html.write([ref]$content)
		$link = @($html.links | Where ClassName -eq "install-button-container")[0].Pathname
		if ($link) {
			Start-Sleep -Seconds $Delay
			Download -Dir "./vsix" -Url "https://marketplace.visualstudio.com/$link"
		} else {
			"Unable to download $ext"
		}
	} catch [System.Management.Automation.ErrorRecord] {
		"Unable to download $ext"
	}
}}