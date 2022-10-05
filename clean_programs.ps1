#Requires -RunAsAdministrator
. .\helpers.ps1

try { $null = Stop-Transcript } catch {}
Start-Transcript -Append -Path "$PSScriptRoot/.dnlj.clean_programs.$(Get-Date -F yyyyMMddTHHmmssffff).log"

# Default apps: `Get-AppxPackage -AllUsers | Format-Table Name, PublishedId -AutoSize`
# Provisioned Apps: `Get-AppxProvisionedPackage -Online | Format-Table DisplayName, PackageName -AutoSize`
$apps = @(
	#"1527c705-839a-4832-9118-54d4Bd6a0c89",
	#"c5e2524a-ea46-4f67-841f-6a9465d9d515",
	#"E2A4F912-2574-4A75-9BB0-0D023378592B",
	#"F46D4000-FD22-4DB4-AC8E-4E1DDDE828FE",
	#"Microsoft.AAD.BrokerPlugin",
	#"Microsoft.AccountsControl",
	#"Microsoft.AsyncTextService",
	"Microsoft.BioEnrollment",
	#"Microsoft.CredDialogHost",
	#"Microsoft.ECApp",
	#"Microsoft.LockApp",
	#"Microsoft.MicrosoftEdgeDevToolsClient",
	"Microsoft.Services.Store.Engagement", # App store engagement
	#"Microsoft.UI.Xaml.CBS",
	#"Microsoft.Win32WebViewHost",
	#"Microsoft.Windows.Apprep.ChxApp",
	#"Microsoft.Windows.AssignedAccessLockApp",
	"Microsoft.Windows.CallingShellApp", # The "Call" app, phone calls over Bluetooth
	#"Microsoft.Windows.CapturePicker",
	#"Microsoft.Windows.CloudExperienceHost",
	#"Microsoft.Windows.ContentDeliveryManager",
	#"Microsoft.Windows.NarratorQuickStart",
	"Microsoft.Windows.OOBENetworkCaptivePortal", # "Out of box experience"
	"Microsoft.Windows.OOBENetworkConnectionFlow", # "Out of box experience"
	#"Microsoft.Windows.ParentalControls",
	"Microsoft.Windows.PeopleExperienceHost",
	#"Microsoft.Windows.PinningConfirmationDialog",
	#"Microsoft.Windows.PrintQueueActionCenter",
	#"Microsoft.Windows.SecureAssessmentBrowser",
	#"Microsoft.Windows.StartMenuExperienceHost",
	#"Microsoft.Windows.XGpuEjectDialog",
	"Microsoft.XboxGameCallableUI",
	#"MicrosoftWindows.Client.Core",
	#"MicrosoftWindows.UndockedDevKit",
	#"NcsiUwpApp",
	#"Windows.CBSPreview",
	#"windows.immersivecontrolpanel",
	#"Windows.PrintDialog",
	#"Microsoft.UI.Xaml.2.4",
	#"Microsoft.VCLibs.140.00.UWPDesktop",
	#"Microsoft.NET.Native.Runtime.2.2",
	#"Microsoft.NET.Native.Framework.2.2",
	#"Microsoft.UI.Xaml.2.7",
	"Microsoft.MicrosoftEdge", # Legacy Edge
	#"Microsoft.Windows.ShellExperienceHost",
	#"MicrosoftWindows.Client.CBS",
	"Disney.37853FC22B2CE",
	"SpotifyAB.SpotifyMusic",
################################################################################
# Sponsored
################################################################################
	"*Clipchamp*",
	"*king.com*",
	"*Spotify*",
	"*Disney*",
	"*CandyCrush*",
	"*Twitter*",
	"*Netflix*",
	"*Pandora*",
	"*Facebook*",
	"*Dolby*",
	"*Minecraft*",
	"*Hulu*",
	"*Amazon*",
	"*Bytedance*",
################################################################################
# Provisioned
################################################################################
	"Clipchamp.Clipchamp",
	"Microsoft.549981C3F5F10", # Cortana
	"Microsoft.BingNews",
	"Microsoft.BingWeather",
	"Microsoft.Bing*",
	"Microsoft.DesktopAppInstaller",
	"Microsoft.GamingApp",
	"Microsoft.GetHelp",
	"Microsoft.Getstarted",
	#"Microsoft.HEIFImageExtension",
	#"Microsoft.HEVCVideoExtension",
	#"Microsoft.MicrosoftEdge.Stable", # Chromium Edge
	"Microsoft.MicrosoftOfficeHub",
	"Microsoft.MicrosoftSolitaireCollection",
	"Microsoft.MicrosoftStickyNotes",
	#"Microsoft.Paint",
	"Microsoft.People",
	"Microsoft.PowerAutomateDesktop",
	#"Microsoft.RawImageExtension",
	"Microsoft.ScreenSketch",
	#"Microsoft.SecHealthUI",
	"Microsoft.StorePurchaseApp", # This is sponsored apps - not to be confused with "Microsoft.WindowsStore"
	"Microsoft.Todos",
	#"Microsoft.VCLibs.140.00",
	#"Microsoft.VP9VideoExtensions",
	#"Microsoft.WebMediaExtensions",
	#"Microsoft.WebpImageExtension",
	#"Microsoft.Windows.Photos",
	"Microsoft.WindowsAlarms",
	#"Microsoft.WindowsCalculator",
	#"Microsoft.WindowsCamera",
	"microsoft.windowscommunicationsapps",
	"Microsoft.WindowsFeedbackHub",
	"Microsoft.WindowsMaps",
	#"Microsoft.WindowsNotepad",
	"Microsoft.WindowsSoundRecorder",
	#"Microsoft.WindowsStore",
	"Microsoft.WindowsTerminal",
	"Microsoft.Xbox.TCUI",
	"Microsoft.XboxGameOverlay",
	"Microsoft.XboxGamingOverlay",
	"Microsoft.XboxIdentityProvider",
	"Microsoft.XboxSpeechToTextOverlay",
	"Microsoft.YourPhone",
	"Microsoft.ZuneMusic",
	"Microsoft.ZuneVideo",
	"MicrosoftCorporationII.QuickAssist",
	"MicrosoftTeams",
	"MicrosoftWindows.Client.WebExperience"
)

"Removing preinstalled programs."

foreach ($app in $apps) {
	# Deprovision provisioned apps
	# This must be done before the uninstall step below
	$found = Get-AppxProvisionedPackage -Online | Where DisplayName -Like $app
	foreach ($pack in $found) {
		try {
			$null = $pack | Remove-AppxProvisionedPackage -Online -AllUsers
			"Deprovisioned $($pack.DisplayName) ($($pack.Version))."
		} catch [System.Runtime.InteropServices.COMException] {
			"Unable to deprovision $($pack.DisplayName) ($($pack.Version))."
		}
		
		# Prevent reinstall during update https://learn.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update
		Set-Registry  -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$($pack.DisplayName)_$($pack.PublisherId)" -Name "(Default)" -Type String -Value ""
	}
	
	# Uninstall the apps
	$found = Get-AppxPackage -AllUsers $app
	foreach ($pack in $found) {
		try {
			$pack | Remove-AppxPackage -AllUsers
			"Removed app package $($pack.Name) ($($pack.Version))."
		} catch [System.Runtime.InteropServices.COMException], [System.UnauthorizedAccessException] {
			"Unable to remove app package $($pack.Name) ($($pack.Version))."
		}
	}
}

"Done removing preinstalled programs."
Stop-Transcript