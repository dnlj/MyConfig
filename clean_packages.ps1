#Requires -RunAsAdministrator
. .\helpers.ps1

try { $null = Stop-Transcript } catch {}
Start-Transcript -Append -Path "$PSScriptRoot/.dnlj.clean_packages.$(Get-Date -F yyyyMMddTHHmmssffff).log"

"Removing Windows packages."

# Get-WindowsPackage -online | Where PackageState -EQ "Installed" | Select PackageName
$PackageDisables = @(
	"Microsoft-OneCore-ApplicationModel-Sync*",
	#"Microsoft-Windows-Client-LanguagePack*",
	#"Microsoft-Windows-Foundation*",
	"Microsoft-Windows-Hello-Face*",
	"Microsoft-Windows-InternetExplorer*",
	#"Microsoft-Windows-LanguageFeatures-Basic*",
	#"Microsoft-Windows-LanguageFeatures-Handwriting*",
	#"Microsoft-Windows-LanguageFeatures-OCR*",
	#"Microsoft-Windows-LanguageFeatures-Speech*",
	#"Microsoft-Windows-LanguageFeatures-TextToSpeech*",
	#"Microsoft-Windows-MediaPlayer*",
	#"Microsoft-Windows-Notepad-System*",
	#"Microsoft-Windows-PowerShell-ISE*",
	#"Microsoft-Windows-Printing-PMCPPC*",
	"Microsoft-Windows-StepsRecorder*",
	"Microsoft-Windows-TabletPCMath*",
	#"Microsoft-Windows-Wallpaper-Content-Extended*",
	"Microsoft-Windows-WordPad*"
	#"OpenSSH-Client*",
)

$PackageList = Get-WindowsPackage -Online | Where PackageState -EQ "Installed"

"Disabling Windows packages is currently bugged. Skipping."
# Some reason we get invalid package on the Remove-WindowsPackage line
#foreach ($pack in $PackageDisables) {
#	$found = $PackageList | Where PackageName -Like $pack
#	foreach ($f in $found) {
#		"Removing optional feature `"$($f.PackageName)`"."
#		$null = $f | Remove-WindowsPackage -Online -NoRestart
#	}
#}

"Done removing Windows packages. Restart may be required."
Stop-Transcript