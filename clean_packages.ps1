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
	"Microsoft-Windows-MediaPlayer*",
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
foreach ($pack in $PackageDisables) {
	$found = $PackageList | Where PackageName -Like $pack
	foreach ($f in $found) {
		try {
			$null = $f | Remove-WindowsPackage -Online -NoRestart
			"Removed package `"$($f.PackageName)`"."
		} catch [System.Runtime.InteropServices.COMException] {
			# Expected error.
			# Some packages have multiple version and can only be removed through the "base" version.
			# Useing try/catch since i can't find any info on this or package name formats.
			#
			# I think if i really wanted to i couldl parse the package name to filter these out
			# but that seems somewhat fragile since i cant find any info on name formats.
			#
			# Names look something like (note the en-US diff):
			#   Error: Some-Package-Name-Here~1a23b4cf34g234~amd64~en-US~10.0.22621.1
			#   Good:  Some-Package-Name-Here~1a23b4cf34g234~amd64~~10.0.22621.1
		}
	}
}

"Done removing Windows packages. Restart may be required."
Stop-Transcript