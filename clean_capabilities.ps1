#Requires -RunAsAdministrator
. .\helpers.ps1

try { $null = Stop-Transcript } catch {}
Start-Transcript -Append -Path "$PSScriptRoot/.dnlj.clean_capabilities.$(Get-Date -F yyyyMMddTHHmmssffff).log"

"Removing Windows capabilities."

# Get-WindowsCapability -Online | Where State -EQ "Installed" | Select Name
$CapabilityDisables = @(
	"App.StepsRecorder*",
	"*InternetExplorer*",
	"*Hello.Face*",
	#"Language.Basic~~~en-US~0.0.1.0"
	#"Language.Handwriting~~~en-US~0.0.1.0"
	#"Language.OCR~~~en-US~0.0.1.0"
	#"Language.Speech~~~en-US~0.0.1.0"
	#"Language.TextToSpeech~~~en-US~0.0.1.0"
	"MathRecognizer*",
	#"Media.WindowsMediaPlayer",
	#"Microsoft.Wallpapers.Extended",
	#"Microsoft.Windows.Notepad.System",
	#"Microsoft.Windows.PowerShell.ISE",
	#"Microsoft.Windows.WordPad",
	"*OneSync*"
	#"OpenSSH.Client",
	#"Print.Management.Console",
)

$CapabilityList = Get-WindowsCapability -Online | Where State -EQ "Installed"
foreach ($cap in $CapabilityDisables) {
	$found = $CapabilityList | Where Name -Like $cap
	foreach ($f in $found) {
		"Removing capability `"$($f.Name)`"."
		$null = $f | Remove-WindowsCapability -Online
	}
}

"Done removing Windows capabilities."
Stop-Transcript