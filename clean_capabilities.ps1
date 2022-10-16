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
	#"Language.Basic*"
	#"Language.Handwriting*"
	#"Language.OCR*"
	#"Language.Speech*"
	#"Language.TextToSpeech*"
	"MathRecognizer*",
	"Media.WindowsMediaPlayer*",
	#"Microsoft.Wallpapers.Extended*",
	#"Microsoft.Windows.Notepad.System*",
	#"Microsoft.Windows.PowerShell.ISE*",
	#"Microsoft.Windows.WordPad*",
	"*OneSync*"
	#"OpenSSH.Client*",
	#"Print.Management.Console*",
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