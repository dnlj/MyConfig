. .\helpers.ps1

$Extensions = @(
	"idex.colorthemedesigner2022",
	"KirAntipov.LineSorterByKir",
	"MadsKristensen.AddNewFile",
	"MadsKristensen.AddNewFile64",
	"MadsKristensen.CopyNice",
	#"MadsKristensen.LearntheShortcut",
	"MadsKristensen.Shifter",
	"MadsKristensen.ShowSelectionLength",
	"MikeWard-AnnArbor.VSColorOutput",
	"MikeWard-AnnArbor.VSColorOutput64",
	"stkb.Rewrap-18980",
	"thomaswelen.SelectNextOccurrence"
)

# TODO: BeeDarkTheme
# TODO: DocHelper

& { $ProgressPreference = 'SilentlyContinue'
foreach ($ext in $Extensions) {
	try {
		$content = (Invoke-WebRequest -UseBasicParsing -Uri "https://marketplace.visualstudio.com/items?itemName=$ext").RawContent
		
		$null = $content -match '"AssetUri":"([^"]+)"'
		$uri = $Matches[1]
		
		$null = $content -match '"Microsoft\.VisualStudio\.Services\.Payload\.FileName":"([^"]+)"'
		$file = $Matches[1]
		
		if ($uri -and $file) {
			Download -Dir "./downloads/vsix" -Url "$uri/$file"
		} else {
			"Unable to find download url for $ext"
		}
	} catch [System.Management.Automation.ErrorRecord] { # Probably invalid/dead url
		"Unable to download $ext (dead link?)"
	}
}}

