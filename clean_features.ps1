#Requires -RunAsAdministrator
. .\helpers.ps1

try { $null = Stop-Transcript } catch {}
Start-Transcript -Append -Path "C:\.dnlj\logs\.dnlj.clean_optional_features.$(Get-Date -F yyyyMMddTHHmmssffff).log"

"Removing Windows optional features."

# Get-WindowsOptionalFeature -Online | Where State -EQ "Enabled" | select FeatureName
$OptionalFeatureDisables = @(
	#"Printing-PrintToPDFServices-Features",
	#"MSRDC-Infrastructure",
	"MicrosoftWindowsPowerShellV2Root",
	"MicrosoftWindowsPowerShellV2",
	#"NetFx4-AdvSrvs",
	#"WCF-Services45",
	#"WCF-TCP-PortSharing45",
	#"MediaPlayback", # https://support.microsoft.com/en-us/topic/media-feature-pack-for-windows-10-n-may-2020-ebbdf559-b84c-0fc2-bd51-e23c9f6a4439
	"WindowsMediaPlayer",
	#"SearchEngine-Client-Package",
	"WorkFolders-Client",
	#"Printing-Foundation-Features",
	#"Printing-Foundation-InternetPrinting-Client",
	"SmbDirect"
)

$OptionalFeatureList = Get-WindowsOptionalFeature -Online | Where State -EQ "Enabled"
foreach ($feat in $OptionalFeatureDisables) {
	$found = $OptionalFeatureList | Where FeatureName -Like $feat
	foreach ($f in $found) {
		"Removing optional feature `"$($f.FeatureName)`"."
		$null = $f | Disable-WindowsOptionalFeature -Online -NoRestart
	}
}

"Done removing Windows optional features. Restart may be required."
Stop-Transcript