#Requires -RunAsAdministrator

param (
	[Parameter(Mandatory)]
	[ValidateSet("Safe", "Normal", "Aggressive")]
	[string] $Mode
)

Set-Variable -Option Constant -Name "ModeAggr" -Value ($Mode -eq "Aggressive")
Set-Variable -Option Constant -Name "ModeNorm" -Value ($ModeAggr -or ($Mode -eq "Normal"))
Set-Variable -Option Constant -Name "ModeSafe" -Value ($ModeNorm -or ($Mode -eq "Safe"))

$WinVer = @()
$WinVer += if ((Get-CimInstance Win32_OperatingSystem).Caption.Contains('Windows 10')) {10} else {0}
$WinVer += if ((Get-CimInstance Win32_OperatingSystem).Caption.Contains('Windows 11')) {11} else {0}
$WinVer = $WinVer | ? {$_ -ne 0}

if ($WinVer.count -eq 0) {
	Write-Host -ForegroundColor red "Unknown Windows version. Aborting."
	return
}

. .\helpers.ps1

try { $null = Stop-Transcript } catch {}
Start-Transcript -Append -Path "C:\.dnlj\logs\.dnlj.settings.$(Get-Date -F yyyyMMddTHHmmssffff).log"
"Running in mode $Mode for Windows $WinVer"
$StartTime = Get-Date

################################################################################################################################################################
# Notes
################################################################################################################################################################
# https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services
# https://www.stigviewer.com/stig/microsoft_windows_10/
# https://gpsearch.azurewebsites.net/


################################################################################################################################################################
# Cloud
################################################################################################################################################################
# A lot of these are suggested apps, not even Microsoft or Windows
$CDMSubNumbers = @(
	"202914",
	"280810",
	"280811",
	"280815",
	"310091",
	"310093", # Windows Welcome Experience - after updates and sign in
	"314559",
	"314563", # My People App Suggestion
	"338387",
	"338388", # Start menu suggestions
	"338389", # Get tips, tricks, and suggestions as you use Windows
	"338393", # Suggested content in Settings
	"353694", # Suggested content in Settings
	"353696", # Suggested content in Settings
	"353698", # Timeline Suggestions
	"338387", # Lock screen tips
	"88000045",
	"88000161",
	"88000163",
	"88000165",
	"88000326",
	""
)

$CDMFields = @(
	"ContentDeliveryAllowed",
	"FeatureManagementEnabled", # Dynamically Inserted Tiles
	"OemPreInstalledAppsEnabled",
	"PreInstalledAppsEnabled",
	"PreInstalledAppsEverEnabled"
	"RotatingLockScreenEnabled",
	"RotatingLockScreenOverlayEnabled",
	"SilentInstalledAppsEnabled",
	"SlideshowEnabled",
	"SoftLandingEnabled", # Tips
	"SystemPaneSuggestionsEnabled"
)

$CloudContent = @(
	"DisableWindowsSpotlightFeatures",
	"DisableConsumerAccountStateContent", # Turn off cloud consumer account state content
	"DisableCloudOptimizedContent", # Turn off cloud optimized content
	"DisableSoftLanding", # Do not show Windows tips
	"DisableWindowsConsumerFeatures" # Turn off Microsoft consumer experiences
);

"Configuring content delivery..."
foreach ($field in $CDMSubNumbers) {
	Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-$($field)Enabled" -Type DWord -Value 0
}

foreach ($field in $CDMFields) {
	Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name $field -Type DWord -Value 0
}

"Configuring cloud content..."
foreach ($field in $CloudContent) {
	Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" -Name $field -Type DWord -Value 1
}

"Removing placeholder apps..."
# Remove placeholder apps
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\*windows.data.placeholdertilecollection*\Current" | Set-ItemProperty -Name "Data" -Value 0


################################################################################################################################################################
# Services
################################################################################################################################################################
"Configuring services..."
# Always include a trailing "*" to account for per-user services
# TODO: should probably add a option to change to manual instead of disable also
$ServicesDisables = @(
	# General / Unsorted
	# ! DONT DISABLE ! ($ModeSafe, "DoSvc*"), # Delivery Optimization # DONT DISABLE: Breaks Windows Update, even if not using delivery optimization.
	# ! DONT DISABLE ! ($ModeSafe, "msiserver*"), # Windows Installer # DONT DISABLE: Breaks Windows Store app installs
	($ModeSafe, "edgeupdate*"), # Edge update services
	($ModeSafe, "MicrosoftEdgeElevationService*"),
	($ModeNorm, "icssvc*"), # Windows Mobile Hotspot Service
	#($ModeAggr, "InstallService*"), # Microsoft Store Install Service
	($ModeAggr, "InventorySvc*"), # Inventory and Compatibility Appraisal service
	#($ModeAggr, "P9RdrService*"), # Plan 9 File Server - Part of WSL
	($ModeSafe, "MapsBroker*"), # Downloaded Maps Manager
	($ModeSafe, "PimIndexMaintenanceSvc*"), # Contact Data indexing
	($ModeSafe, "RetailDemo*"), # Retail Demo Service
	($ModeNorm, "WbioSrvc*"), # Windows Biometric Service
	($ModeSafe, "WMPNetworkSvc*"), # Windows Media Player Network Sharing Service
	($ModeSafe, "workfolderssvc*"), # Work Folders
	($ModeSafe, "OneSyncSvc*"), # Various syncing functionality
	($ModeAggr, "UnistoreSvc*"), # User Data Storage
	($ModeAggr, "UserDataSvc*"), # User Data Access
	# ! DONT DISABLE ! ($ModeAggr, "DevicesFlowUserSvc*"), # DONT DISABLE: Breaks Bluetooth
	# ! DONT DISABLE ! ($ModeAggr, "DevicePickerUserSvc*"), # DONT DISABLE: Breaks Bluetooth
	# ! DONT DISABLE ! ($ModeAggr, "DeviceAssociationBrokerSvc*"), # DONT DISABLE: Breaks Bluetooth
	($ModeSafe, "NPSMSvc*"), # Now playing session manager
	# ! DONT DISABLE ! ($ModeSafe, "AppReadiness"), # App Readiness - Windows Store app install and setup # DONT DISABLE: Breaks Windows Update.
	# ! DONT DISABLE ! ($ModeAggr, "CaptureService*"), # DONT DISABLE: Breaks snipping tool (Win+Shift+S)
	# ! DONT DISABLE ! ($ModeAggr, "cbdhsvc*"), # Clipboard service - for enhanceed clipboard: history, device sharing, etc. - DONT DISABLE: Breaks snipping tool (Win+Shift+S)
	# ! DONT DISABLE ! ($ModeAggr,"TextInputManagementService*"), # DONT DISABLE: breaks keyboard input.
	
	# TODO: UNTESTED - Might be what broke Microsoft Store? not sure i changed a bunch of stuff
	# Breaks xbox sign in - and maybe some Store stuff?
	#($ModeAggr, "TokenBroker*"), # This service is used by Web Account Manager to provide single-sign-on to apps and services.
	
	# Privacy, Tracking, and Telemetry
	($ModeSafe, "SSDPSRV"), # SSDP Discovery - Simple Search and Discovery Protocol
	($ModeSafe, "lfsvc"), # Geolocation Service
	($ModeSafe, "AJRouter*"), # AllJoyn Router Service - IoT stuff - https://en.wikipedia.org/wiki/AllJoyn
	($ModeNorm, "HomeGroup*"), # Multiple homegroup related services
	($ModeNorm, "SharedAccess*"), # Internet Connection Sharing (ICS)
	($ModeSafe, "diagnosticshub.standardcollector.service*"), # Microsoft (R) Diagnostics Hub Standard Collector Service
	($ModeSafe, "diagsvc"), # Diagnostic Execution Service
	($ModeSafe, "DiagTrack"), # Connected User Experiences and Telemetry
	($ModeSafe, "lltdsvc"), # Link-Layer Topology Discovery Mapper
	($ModeSafe, "NetTcpPortSharing"), # Net.Tcp Port Sharing Service

	# Phone and Printers
	($ModeNorm, "PhoneSvc*"), # Phone Service
	($ModeNorm, "TapiSrv*"), # Telephony
	($ModeNorm, "MessagingService*"), # Text messaging and related functionality
	($ModeNorm, "SmsRouter"), # Microsoft Windows SMS Router Service

	# Mixed Reality
	($ModeSafe, "*MixedReality*"), # Windows Mixed Reality OpenXR Service
	($ModeSafe, "SharedRealitySvc*"), # Spatial Data Service

	# Peer to peer
	($ModeSafe, "p2pimsvc*"), # Peer Networking Identity Manager
	($ModeSafe, "p2psvc*"), # Peer Networking Grouping
	($ModeSafe, "PeerDistSvc*"), # BranchCache
	($ModeSafe, "PNRPAutoReg*"), # PNRP Machine Name Publication Service
	($ModeSafe, "PNRPsvc*"), # Peer Name Resolution Protocol

	# Remote Access, Desktop, and Management
	($ModeSafe, "EntAppSvc*"), # Enterprise App Management Service
	($ModeSafe, "PushToInstall*"), # Windows PushToInstall Service - remote app installation
	($ModeSafe, "RasAuto*"), # Remote Access Auto Connection Manager
	($ModeSafe, "RasMan*"), # Remote Access Connection Manager
	($ModeSafe, "RemoteAccess*"), # Routing and Remote Access
	($ModeSafe, "RemoteRegistry*"), # Remote Registry
	($ModeSafe, "SessionEnv*"), # Remote Desktop Configuration
	($ModeSafe, "TermService*"), # Remote Desktop Services
	($ModeSafe, "UmRdpService*"), # Remote Desktop Services UserMode Port Redirector
	# ! DONT DISABLE ! ($ModeAggr, "Winmgmt*"), # Windows Management Instrumentation - DONT DISABLE: Breaks updates, add/remove capabilities, some powershell commands.
	($ModeSafe, "WinRM*"), # Windows Remote Management (WS-Management)
	($ModeSafe, "DmEnrollmentSvc*"), # Device Management Enrollment Service
	($ModeSafe, "dmwappushservice*"), # Device Management Wireless Application Protocol (WAP) Push message Routing Service dmwappushservice
	($ModeNorm, "LanmanWorkstation*"), # Network file sharing, SMB protocol

	# Printers
	($ModeAggr, "PrintNotify*"), # Printer Extensions and Notifications
	($ModeAggr, "PrintWorkflowUserSvc*"),
	#($ModeAggr, "Spooler*"), # Print Spooler

	# Authorization, Payment, and Sharing
	($ModeSafe, "SCardSvr*"), # Smart Card
	($ModeSafe, "ScDeviceEnum*"), # Smart Card Device Enumeration Service
	($ModeSafe, "SCPolicySvc*"), # Smart Card Removal Policy
	($ModeSafe, "SEMgrSvc*"), # Payments and NFC/SE Manager
	($ModeSafe, "WalletService*"), # Wallet Service
	
	# Seem to be related to settings sync between multiple devices (CDP = Connected Devices Platform)
	($ModeSafe, "CDPSvc*"), # Connected Devices Platform Service
	($ModeSafe, "CDPUserSvc*"), # Connected Devices Platform User Service_4b694

	# Gaming
	# Disabling some of these may break XInput and/or Windows.Gaming.Input
	($ModeSafe, "BcastDVR*"),
	($ModeSafe, "GamingService*"), # "GamingServices" and "GamingServicesNet"
	($ModeSafe, "XblAuthManager*"), # Xbox Live Auth Manager
	($ModeSafe, "XblGameSave*"), # Xbox Live Game Save
	($ModeSafe, "XboxGipSvc*"), # Xbox Accessory Management Service
	($ModeSafe, "XboxNetApiSvc"), # Xbox Live Networking Service
	#($ModeSafe, "xboxgip*"), # Will probabl break controller input (Windows.Gaming.Input?)
	#($ModeSafe, "xinputhid*"), # Will probabl break controller input (xinput)

	# Foxit
	($ModeNorm, "Foxit*"),

	# Logitech GHub
	($ModeNorm, "LGHUB*")
)

# We manually iterate the registry instead of using `Get-Service` here because
# get service doesnt include per-user service templates unless you explicitly ask
# for it by exact name
#
# https://learn.microsoft.com/en-us/windows/application-management/per-user-services-in-windows
#
$ServicesDisables = $ServicesDisables | Where {$_[0]} | %{$_[1]}
$ServicesList = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services"
foreach ($rule in $ServicesDisables) {
	$found = $ServicesList | Where PSChildName -Like $rule

	foreach ($f in $found) {
		$item = Get-ItemProperty $f.PSPath
		$serv = Get-Service -Name $item.PSChildName
		if ($serv.StartType -ceq "Disabled") { continue }

		"Disabling service `"$($item.PSChildName)`" (was: $($serv.StartType), $($serv.Status), $($serv.ServiceName))"
		$serv | Stop-Service -Force

		# 0 = Boot, 1 = System, 2 = Automatic, 3 = Manual, 4 = Disabled
		Set-Registry -Path $f.PSPath -Name "Start" -Type DWord -Value 4

		# We have to use registry directly because of permission issues with Set-Service
		#$f | Set-Service -Status Stopped -StartupType Disabled
	}
}


################################################################################################################################################################
# Tasks
################################################################################################################################################################
"Configuring scheduled tasks..."
# Get-ScheduledTask | Format-Table URI, State, Description -AutoSize
$TaskDisables = @(
	($ModeSafe, "*MicrosoftEdge*"),
	($ModeSafe, "*OneDrive*"),
	($ModeNorm, "\Microsoft\Windows\Feedback\Siuf\DmClient*"), # Device management
	#($ModeSafe, "WinSAT"), # Measures a system's performance and capabilities
	($ModeSafe, "\Microsoft\Windows\Management\Provisioning\Cellular"), # SIM integration
	($ModeSafe, "\Microsoft\Windows\Maps\Maps*"),
	($ModeNorm, "\Microsoft*WiFiTask"), # Background task for performing per user and web interactions
	($ModeSafe, "\Microsoft\Windows\Printing\EduPrintProv"),
	($ModeSafe, "\Microsoft\Windows\RemoteAssistance*"), # Checks group policy for changes relevant to Remote Assistance
	($ModeSafe, "\Microsoft\Windows\Work Folders*"),
	($ModeSafe, "\Microsoft*FamilySafety*"), # Initializes Family Safety monitoring and enforcement @ Synchronizes the latest settings with the Microsoft family features service
	($ModeSafe, "\Microsoft\XblGameSave\XblGameSaveTask"),
	($ModeSafe, "\Microsoft\Windows\WwanSvc\NotificationTask"), # Background task for performing per user and web interactions
	($ModeSafe, "\Microsoft\Windows\Application Experience\StartupAppTask"), # Scans startup entries and raises notification to the user if there are too many startup entries.
	($ModeSafe, "\Microsoft\Windows\PushToInstall\Registration"), # Push to install stuff
	
	# Sync tasks
	($ModeNorm, "\Microsoft\Windows\Offline Files\Background Synchronization"), # This task controls periodic background synchronization of Offline Files when the user is working in an offline mode.
	($ModeNorm, "\Microsoft\Windows\Offline Files\Logon Synchronization"), # This task initiates synchronization of Offline Files when a user logs onto the system.
	($ModeNorm, "\Microsoft\Windows\International\Synchronize Language Settings"), # Synchronize User Language Settings from other devices. NOTE: If you do not disable this task and have settings sync enabled it will hang when trying to log off.
	
	# Customer Experience Program
	# Get-ScheduledTask | Where Description -Like "*Customer Experience*"),
	($ModeSafe, "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"), # If the user has consented to participate in the Windows Customer Experience Improvement Program, this job collects and sends usage data to Microsoft.
	($ModeSafe, "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"), # The USB CEIP (Customer Experience Improvement Program) task collects Universal Serial Bus related statistics and information about your machine and sends it to the Windows Device Connectivity engineering...
	($ModeSafe, "*KernelCEIPTask*"),
	($ModeSafe, "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"), # The Windows Disk Diagnostic reports general disk and system information to Microsoft for users participating in the Customer Experience Program.
	($ModeSafe, "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"), # Collects program telemetry information if opted-in to the Microsoft Customer Experience Improvement Program.
	($ModeSafe, "\Microsoft\Windows\Autochk\Proxy"), # This task collects and uploads autochk SQM data if opted-in to the Microsoft Customer Experience Improvement Program.

	# Workplace
	($ModeSafe, "\Microsoft\Windows\Workplace Join\Automatic-Device-Join"), # Register this computer if the computer is already joined to an Active Directory domain.
	($ModeSafe, "\Microsoft\Windows\Workplace Join\Device-Sync"), # Sync device attributes to Azure Active Directory.
	($ModeSafe, "\Microsoft\Windows\Workplace Join\Recovery-Check"), # Performs recovery check.

	# Windows Update
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\Refresh Settings"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\Report Policies"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\Schedule Maintenance Work"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\Schedule Wake To Work"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\Schedule Work"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"), # Forces rebooot after update
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\UUS Failover Task"),
	($ModeSafe, "\Microsoft\Windows\WindowsUpdate\Scheduled Start"), # This task is used to start the Windows Update service when needed to perform scheduled operations such as scans.

	# Out of box experience
	# Get-ScheduledTask | Where URI -like "*oobe*"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\Start Oobe Expedite Work"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScanAfterUpdate"),
	($ModeSafe, "\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_LicenseAccepted"),
	($ModeSafe, "\Microsoft\Windows\WwanSvc\OobeDiscovery")
)

# Fix access issues for UpdateOrchestrator tasks
$null = takeown /F "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator" /A /R
$null = icacls "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator" /grant *S-1-5-32-544:F /T

$TaskDisables = $TaskDisables | Where {$_[0]} | %{$_[1]}
Disable-TasksLike $TaskDisables


################################################################################################################################################################
# Firewall
################################################################################################################################################################
"Configuring firewall..."
# Get-NetFirewallRule | Format-Table DisplayName, Group, DisplayGroup, Description -AutoSize
$FirewallDisables = @(
	# Specific apps
	($ModeNorm, "*Cortana*"),
	($ModeNorm, "*Feedback Hub*"),
	($ModeAggr, "*Get Help*"),
	($ModeNorm, "*Microsoft family features*"),
	($ModeNorm, "*Microsoft Tips*"),
	($ModeNorm, "*Microsoft People*"),
	($ModeNorm, "*Microsoft Photos*"),
	($ModeNorm, "*Microsoft Teams*"),
	($ModeNorm, "*Microsoft To Do*"),
	($ModeNorm, "*Microsoft Content*"),
	($ModeNorm, "*Movies & TV*"),
	($ModeNorm, "*MSN Weather*"),
	($ModeNorm, "*Take a test*"),
	($ModeNorm, "*Windows Calculator*"),
	($ModeNorm, "*Windows Camera*"),
	($ModeNorm, "*Windows Media Player*"),
	($ModeNorm, "*Solitaire*"),
	($ModeNorm, "*Skype*"),
	($ModeNorm, "*OneNote*"),
	($ModeNorm, "*Mixed Reality Portal*"),
	($ModeNorm, "*3D Viewer*"),
	
	# Some apps also have rules for appid instead of just name
	($ModeNorm, "*Microsoft.Getstarted*"),
	($ModeNorm, "*Microsoft.XboxIdentityProvider*"),
	($ModeNorm, "*Microsoft.ZuneMusic*"),
	($ModeNorm, "*microsoft.windowscommunicationsapps*"),
	($ModeNorm, "*Microsoft.Todos*"),
	($ModeNorm, "*Microsoft.ZuneVideo*"),
	($ModeNorm, "*Microsoft.XboxGamingOverlay*"),
	($ModeNorm, "*Microsoft.WindowsTerminal*"),
	($ModeAggr, "*Microsoft.WindowsFeedbackHub*"),
	($ModeAggr, "*Microsoft.StorePurchaseApp*"),
	($ModeNorm, "*Microsoft.People*"),
	($ModeNorm, "*Microsoft.GetHelp*"),

	# Wild cards
	($ModeSafe, "*Delivery Optimization*"),
	($ModeSafe, "*Cast to Device*"),
	($ModeAggr, "*File and Printer Sharing*"),
	($ModeAggr, "*Work or School*"),
	($ModeSafe, "*Xbox*"),

	# Remote Access, Desktop, Discovery, Management
	($ModeSafe, "*AllJoyn*"),
	($ModeSafe, "*Proximity sharing*"),
	($ModeSafe, "*Remote Event*"),
	($ModeSafe, "*Remote Service Management*"),
	($ModeSafe, "*Remote Scheduled*"),
	($ModeSafe, "*Remote Volume Management*"),
	($ModeSafe, "*Remote Access*"),
	($ModeSafe, "*Remote Assist*"),
	($ModeSafe, "*Remote Desktop*"),
	($ModeAggr, "Windows Device Management*"),
	($ModeAggr, "Microsoft Media Foundation Network*"),
	($ModeAggr, "*Network Discovery*"),
	($ModeAggr, "*BranchCache*"),

	# Third party
	($ModeSafe, "*Clipchamp*"),
	($ModeSafe, "*king.com*"),
	($ModeSafe, "*Spotify*"),
	($ModeSafe, "*Disney*"),
	($ModeSafe, "*CandyCrush*"),
	($ModeSafe, "*Twitter*"),
	($ModeSafe, "*Netflix*"),
	($ModeSafe, "*Pandora*"),
	($ModeSafe, "*Facebook*"),
	($ModeSafe, "*Dolby*"),
	($ModeSafe, "*Minecraft*"),
	($ModeSafe, "*Hulu*"),
	($ModeSafe, "*Amazon*"),
	($ModeSafe, "*Tiktok*"),
	($ModeSafe, "*Bytedance*")
)

$FirewallAdds = @(
	($ModeSafe, "TextInputHost", "%SystemRoot%\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\TextInputHost.exe") # Block "Tenor" ad in emoji menu
)

# TODO: untested
#foreach ($rule in $FirewallAdds) {
#	if ($rule[0]) {
#		# TODO: first need to check if rule exists and delete it in case we run this script multiple times
#		$name = $rule[1]
#		$null = New-NetFirewallRule -DisplayName ".dnlj.$name.out" -Direction Outbound -Program $rule[2] -Action Block -Enabled "True"
#		$null = New-NetFirewallRule -DisplayName ".dnlj.$name.in" -Direction Inbound -Program $rule[2] -Action Block -Enabled "True"
#	}
#}

$FirewallDisables = $FirewallDisables | Where {$_[0]} | %{$_[1]}
$FirewallRules = Get-NetFirewallRule | Where Enabled -EQ True # huge speed up
foreach ($rule in $FirewallDisables) {
	$found = $FirewallRules | Where {`
		    ($_.DisplayName -Like $rule)`
		-or ($_.Group -Like $rule)`
		-or ($_.DisplayGroup -Like $rule)`
	}

	foreach ($f in $found) {
		"Disabling firewall rule `"$($f.DisplayName)`" in group `"$($f.DisplayGroup)`""
		$f | Disable-NetFirewallRule
	}
}


################################################################################################################################################################
# Startup / Autorun
################################################################################################################################################################
"Configuring startup and autorun..."
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "OneDrive" -Type Binary -Value 0
Remove-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive"
Remove-Registry -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive"


################################################################################################################################################################
# App Perms
################################################################################################################################################################
"Configuring app permisions..."

# Set as though changed through Windows settings UI
# These shouldn't need any mode filters because they are pretty easy to enable/disable from Windows settings.
$AppPerm_UserChoice = @(
	"activity",
	"appDiagnostics",
	"appointments",
	"bluetooth",
	"bluetoothSync",
	"broadFileSystemAccess",
	"cellularData",
	"chat",
	"contacts",
	"documentsLibrary",
	"downloadsFolder",
	"email",
	"gazeInput",
	"graphicsCaptureProgrammatic",
	"graphicsCaptureWithoutBorder",
	"humanInterfaceDevice",
	"location",
	"microphone",
	"musicLibrary",
	"phoneCall",
	"phoneCallHistory",
	"picturesLibrary",
	"radios",
	"userAccountInformation",
	"userDataTasks",
	"userNotificationListener",
	"videosLibrary",
	"webcam",
	"wifiData",
	"wifiDirect"
)

foreach ($perm in $AppPerm_UserChoice) {
	# HKLM here is for the global enable/disable. Users CAN still specify own prefs.
	Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$perm" -Name "Value" -Type String -Value "Deny"
	Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$perm" -Name "Value" -Type String -Value "Deny"
}

# Set through group policy (cant be changed in through settings UI)
#$AppPerms_GroupPolicy = @(
#	"LetAppsAccessAccountInfo",
#	"LetAppsAccessGazeInput",
#	"LetAppsAccessCallHistory",
#	"LetAppsAccessContacts",
#	"LetAppsGetDiagnosticInfo",
#	"LetAppsAccessEmail",
#	"LetAppsAccessLocation",
#	"LetAppsAccessMessaging",
#	"LetAppsAccessMotion",
#	"LetAppsAccessNotifications",
#	"LetAppsAccessTasks",
#	"LetAppsAccessCalendar",
#	"LetAppsAccessCamera",
#	"LetAppsAccessMicrophone",
#	"LetAppsAccessTrustedDevices",
#	"LetAppsAccessBackgroundSpatialPerception",
#	"LetAppsActivateWithVoice",
#	"LetAppsActivateWithVoiceAboveLock",
#	"LetAppsSyncWithDevices",
#	"LetAppsAccessRadios",
#	"LetAppsAccessPhone",
#	"LetAppsRunInBackground"
#)
#
#foreach ($perm in $AppPerms_GroupPolicy) {
#	# 0 = User Control, 1 = Allow, 2 = Deny
#	Set-Registry -Path "HKLM:Software\Policies\Microsoft\Windows\AppPrivacy" -Name $perm -Type DWord -Value 2
#}

Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\graphicsCaptureProgrammatic\NonPackaged" -Name "Value" -Type String -Value "Deny"
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\graphicsCaptureWithoutBorder\NonPackaged" -Name "Value" -Type String -Value "Deny"

# Background Apps
# Seems to break SOME games that are installed through Windows Store (Xbox App) when alt tabbing (Astroneers, Sea of Thieves)
#Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Type DWord -Value 0 # 0 = User Control, 1 = Allow, 2 = Deny
#Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type DWord -Value 1 # 1 = Off
#Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "BackgroundAppGlobalToggle" -Type DWord -Value 0 # 0 = Off


################################################################################################################################################################
# Security
# See also: $FirewallDisables
################################################################################################################################################################
"Configuring security settings..."

# Disable local account security questions
# 0 or missing = Recovery questions enabled (default, missing)
# 1 = Recovery questions disabled
if ($ModeAggr) {
	Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "NoLocalPasswordResetQuestions" -Type DWord -Value 1
}

# Disable reveal button in password fields
# 0 or missing = Reveal button is shown (default)
# 1 = Reveal button not shown
if ($ModeAggr) {
	Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredUI" -Name "DisablePasswordReveal" -Type DWord -Value 1
}

# Disable administrative shares
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareServer" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -Type DWord -Value 0

# User Account Control
if ($ModeAggr) {
	Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 0
	Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Type DWord -Value 0
}

# Smart App Control
if ($ModeAggr) {
	Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -Name "VerifiedAndReputablePolicyState" -Type DWord -Value 0
}

# SmartScreen
if ($ModeAggr) {
	#Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Type DWord -Value 0
}

# Mapped Drives
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLinkedConnections" -Type DWord -Value 0

# Remote Assistance and Desktop
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowFullControl" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fPromptForPassword" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Type DWord -Value 1

# Autorun
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Type DWord -Value 255
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoAutorun" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoAutoplayfornonVolume" -Type DWord -Value 1

# Disable network indicator on lock screen
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DontDisplayNetworkSelectionUI" -Type DWord -Value 1

# Disable camera on lock screen
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreenCamera" -Type DWord -Value 1

# Disable wifi sense
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowInternetSharing" -Name "Value" -Type DWord -Value 0

# Disable Peernet
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Peernet" -Name "Disabled" -Type DWord -Value 1


################################################################################################################################################################
# Updates
################################################################################################################################################################
"Configuring update settings..."

# Windows Updates
#
# WARNING: Windows Defender uses Windows Update. Disabling this will prevent Window Defender from receiving updates.
# See update task below.
#
# NoAutoUpdate:
#   0=updates enabled
#   1=updates disabled
# AUOptions:
# 	2=notify dl
# 	3=auto dl, notify install
# 	4=auto dl + auto install
# 	5=use local settings
# 	7=notify install + notify restart
# wuauserv: windows update service, 3 = manual start
if ($ModeAggr) {
	Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 0
	Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 2
	Set-Registry -Path "HKLM:\System\CurrentControlSet\Services\wuauserv" -Name "Start" -Type DWord -Value 3
}

# Create a task to update Windows Defender even if updates are turned off
# https://www.microsoft.com/en-us/wdsi/defenderupdates
# Times use ISO 8601 durations: https://en.wikipedia.org/wiki/ISO_8601#Durations
#
# Some reason Windows Update still thinks there are updates some times.
# If you check all the version numbers with `MpCmdRun -SignatureUpdate` you will
# see that we are actually up to date.
if ($ModeAggr) {&{
	try {
		$ErrorActionPreference = "Stop"
		$user = "NT AUTHORITY\SYSTEM"
		$name = "Windows Defender Update"
		$path = "\.dnlj\"
		$full = Join-Path $path $name

		$action = New-ScheduledTaskAction -Execute "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Argument "-SignatureUpdate"
		$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -StartWhenAvailable -MultipleInstances IgnoreNew -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
		$trigger = New-ScheduledTaskTrigger -AtLogOn
		$trigger.Delay = 'PT90S'
		$trigger.Repetition = New-CimInstance -ClientOnly -ClassName "MSFT_TaskRepetitionPattern" -Namespace "Root/Microsoft/Windows/TaskScheduler"`
			-Property @{Duration="";Interval="PT2H";StopAtDurationEnd=$true}

		if (!($task = Get-ScheduledTask | Where URI -EQ $full)) {
			$task = Register-ScheduledTask -TaskName $name -TaskPath $path -User $user -Trigger $trigger -Action $action -Settings $settings
			Write-Host -ForegroundColor green "Windows Defender Update task created ($($task.URI))."
		} else {
			Write-Host -ForegroundColor green "Windows Defender Update task already exists ($($task.URI))."
		}
	} catch {
		Write-Host -ForegroundColor red "Unable to create Windows Defender update task. Your system may be at risk."
	}
}}

# Driver Updates
# You can also allow/deny specific devices with Group Policy.
# `Local Computer Policy > Computer Configuration > Administrative Templates > System > Device Installation > Device Installation Restrictions`
if ($ModeAggr) {
	Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1
	Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1
}

# Stability
# See https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-update
# https://learn.microsoft.com/en-us/windows/client-management/device-update-management#windows10version1607forupdatemanagement
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "BranchReadinessLevel" -Type DWord -Value 16 # 16 = Semi Annual
if ($ModeAggr) {
	Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferUpgrade" -Type DWord -Value 1
	Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferUpgradePeriod" -Type DWord -Value 8 # Months, max 8
	Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferUpdatePeriod" -Type DWord -Value 4 # Weeks, max 4
}

# Quality Updates
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferQualityUpdates" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 30 # Days, max 30
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "PauseQualityUpdatesStartTime" -Type String -Value ""

# Feature Updates
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdates" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365 # Days, max 365
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "PauseFeatureUpdatesStartTime" -Type String -Value ""

# Windows auto restart (1=disable, 0=enable)
# Maybe? i cant find any info on this setting, we already disasbled in in tasks section
#Set-Register -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Type DWord -Value 1

# Peer to peer downloads (Delivery Optimization)
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization" -Name "SystemSettingsDownloadMode" -Type DWord -Value 0

# Disable automatic updates for non-windows things
if ($ModeAggr) {
	Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" -Name "AutoDownload" -Type DWord -Value 2 # 2 = Disabled, 4 = Enabled
	Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Type DWord -Value 2 # 2 = Disabled, 4 = Enabled
	Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\7971f918-a847-4430-9279-4a52d1efe18d" -Name "RegisteredWithAU" -Type DWord -Value 0
}

# Wake for updates
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" -Name "WakeUp" -Type DWord -Value 0

# Automatic sign on after restart
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableAutomaticRestartSignOn" -Type DWord -Value 1

# Visaul Studio Background Updates
# If left enabled it will randomly start using 100% cpu while you are actively doing things.
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\VisualStudio\Setup" -Name "BackgroundDownloadDisabled" -Type DWord -Value 1



################################################################################################################################################################
# Edge
################################################################################################################################################################
"Configuring Microsoft Edge..."

# Chromium
# Can also be configured under HKCU if you want.
# See: `edge://policy/` > "Show policies with no value"
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderEnabled" -Type DWord -Value 1
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderName" -Type String -Value "Google"
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderSearchURL" -Type String -Value "{google:baseURL}search?q=%s&{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchboxStats}{google:searchFieldtrialParameter}{google:iOSSearchLanguage}{google:prefetchSource}{google:searchClient}{google:sourceId}{google:contextualSearchVersion}ie={inputEncoding}"
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderSuggestURL" -Type String -Value "{google:baseURL}complete/search?output=chrome&q={searchTerms}"
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "HomepageLocation" -Type String -Value "https://www.google.com/" # Can also use `about:blank`
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageLocation" -Type String -Value "https://www.google.com/" # Can also use `about:blank`
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AddressBarMicrosoftSearchInBingProviderEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AlternateErrorPagesEnabled" -Type DWord -Value 0 # Suggest similar sites
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ApplicationGuardTrafficIdentificationEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AutofillAddressEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AutofillAddressEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AutofillCreditCardEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AutofillCreditCardEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "AutofillCreditCardEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BrowserSignin" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ConfigureDoNotTrack" -Type DWord -Value 1
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ConfigureOnlineTextToSpeech" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ConfigureShare" -Type DWord -Value 1
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "DefaultBrowserSettingEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "DiagnosticData" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeDiscoverEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeEDropEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeEnhanceImagesEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EdgeFollowEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "EdgeShoppingAssistantEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "EnableMediaRouter" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "FamilySafetySettingsEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "GuidedSwitchEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "HideInternetExplorerRedirectUXForIncompatibleSitesEnabled" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideRestoreDialogEnabled" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HubsSidebarEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImplicitSignInEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportAutofillFormData" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportBrowserSettings" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportCookies" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportExtensions" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportFavorites" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportHistory" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportHomepage" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportOnEachLaunch" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportOpenTabs" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportPaymentInfo" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportSavedPasswords" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportSearchEngine" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportShortcuts" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ImportStartupPageSettings" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "InAppSupportEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "InternetExplorerIntegrationLevel" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "LinkedAccountEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "LiveCaptionsAllowed" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "LocalProvidersEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MAMEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MathSolverEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "MediaRouterCastAllowAllIPs" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MicrosoftEdgeInsiderPromotionEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MicrosoftOfficeMenuEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "NetworkPredictionOptions" -Type DWord -Value 2
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "OutlookHubMenuEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "PasswordManagerEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "PaymentMethodQueryEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "PersonalizationReportingEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "PromotionalTabsEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "PromptForDownloadLocation" -Type DWord -Value 1
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "RedirectSitesFromInternetExplorerRedirectMode" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "RelatedMatchesCloudServiceEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ResolveNavigationErrorsUseWebService" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "RoamingProfileSupportEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "SearchSuggestEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SendIntranetToInternetExplorer" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SharedLinksEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowCastIconInToolbar" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowHomeButton" -Type DWord -Value 1
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ShowMicrosoftRewards" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowOfficeShortcutInFavoritesBar" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowPDFDefaultRecommendationsEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ShowRecommendationsEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SignInCtaOnNtpEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SiteSafetyServicesEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "SpeechRecognitionEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "SyncDisabled" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SyncTypesListDisabled" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "TyposquattingCheckerEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "WebWidgetAllowed" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "WebWidgetIsEnabledOnStartup" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "WindowsHelloForHTTPAuthEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "DisableEdgeDesktopShortcutCreation" -Type DWord -Value 1
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "ExtensionSettings" -Type String -Value '{"*":{},"odfafepnkmbhccpbejgmiehpchacaeak":{"toolbar_state":"default_shown","installation_mode":"normal_installed","update_url":"https://edge.microsoft.com/extensionwebstorebase/v1/crx"},"lmijmgnfconjockjeepmlmkkibfgjmla":{"toolbar_state":"default_shown","installation_mode":"normal_installed","update_url":"https://edge.microsoft.com/extensionwebstorebase/v1/crx"},"mdkdmaickkfdekbjdoojfalpbkgaddei":{"toolbar_state":"default_shown","installation_mode":"normal_installed","update_url":"https://edge.microsoft.com/extensionwebstorebase/v1/crx"}}'

# SmartScreen (Chromium)
if ($ModeAggr) {
	Set-Registry -Path "HKCU:\Software\Policies\Microsoft\Edge" -Name "SmartScreenEnabled" -Type DWord -Value 0
}

# Legacy Edge
Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main" -Name "DoNotTrack" -Type DWord -Value 1
Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\FlipAhead" -Name "FPEnabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main" -Name "ShowSearchSuggestionsGlobal" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\ServiceUI" -Name "EnableCortana" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\ServiceUI\ShowSearchHistory" -Name "(Default)" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main" -Name "Use FormSuggest" -Type String -Value "no"
Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Privacy" -Name "EnableEncryptedMediaExtensions" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main" -Name "OptimizeWindowsSearchResultsForScreenReaders" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Browser" -Name "AllowAddressBarDropdown" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader" -Name "AllowTabPreloading" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Name "AllowPrelaunch" -Type DWord -Value 0

# SmartScreen (legacy)
if ($ModeAggr) {
	Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" -Name "EnabledV9" -Type DWord -Value 0
}


################################################################################################################################################################
# Privacy
################################################################################################################################################################
"Configuring privacy settings..."

# Narrator QuickStart
Set-Registry -Path "HKCU:\Software\Microsoft\Narrator\QuickStart" -Name "SkipQuickStart" -Type DWord -Value 1

# Search filtering
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "SafeSearchMode" -Type DWord -Value 0

# .NET Telemetry
[System.Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', [System.EnvironmentVariableTarget]::Machine)

# Disable additional data being sent to Microsoft automatically
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -Name "DontSendAdditionalData" -Type DWord -Value 1

# Disable UserAssist (program tracking)
Set-Registry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Type DWord -Value 0
Set-Registry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackEnabled" -Type DWord -Value 0

# Disable News and Interests
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests" -Name "AllowNewsAndInterests" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Type DWord -Value 0

# Windows Media Player library sharing
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -Name "PreventLibrarySharing" -Type DWord -Value 1

# Windows Media Player online content
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -Name "PreventCDDVDMetadataRetrieval" -Type DWord -Value 1
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -Name "PreventMusicFileMetadataRetrieval" -Type DWord -Value 1
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" -Name "PreventRadioPresetsRetrieval" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\WMDRM" -Name "DisableOnline" -Type DWord -Value 1

# Disable online tips
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings" -Name "AllowOnlineTips" -Type DWord -Value 0

# Disable "Find My Device"
# Group Policy version of LocationSyncEnabled
if ($ModeNorm) {
	Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name "AllowFindMyDevice" -Type DWord -Value 0
}

# Remote install of apps from another device
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\PushToInstall" -Name "DisablePushToInstall" -Type DWord -Value 1

# Shared Experience
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CDP" -Name "RomeSdkChannelUserAuthzPolicy" -Type DWord -Value 0

# Tailored Experience
Set-Registry -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Experience" -Name "AllowTailoredExperiencesWithDiagnosticData" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\CPSS\Store" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type DWord -Value 0

# Ink Workspace Suggested Apps
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -Name "AllowSuggestedAppsInWindowsInkWorkspace" -Type DWord -Value 0

# App Speech Activation
Set-Registry -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" -Name "AgentActivationEnabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" -Name "AgentActivationOnLockScreenEnabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" -Name "AgentActivationLastUsed" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Preferences" -Name "ModelDownloadAllowed" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name "HasAccepted" -Type DWord -Value 0

# Recent Items in Start Menu
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Type DWord -Value 0

# Explorer Ads
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Type DWord -Value 0

# OneDrive
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\OneDrive" -Name "PreventNetworkTrafficPreUserSignIn" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSync" -Type DWord -Value 1 # 1 = Disabled. Legacy setting from Windows 8.1 - See DisableFileSyncNGSC
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1 # 1 = Disabled. I think this is the one that actually matters. The others should depend on this.
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableLibrariesDefaultSaveToOneDrive" -Type DWord -Value 0 # 0 = Save locally
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableMeteredNetworkFileSync" -Type DWord -Value 0 # 0 = Block on all metered networks, 1 = Roaming

# Handwriting Data
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC" -Name "PreventHandwritingDataSharing" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" -Name "PreventHandwritingErrorReports" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput" -Name "AllowLinguisticDataCollection" -Type DWord -Value 0

# "Inventory Collector"
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableInventory" -Type DWord -Value 1

# Advertising
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Bluetooth" -Name "AllowAdvertising" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type DWord -Value 1

# Typing info
Set-Registry -Path "HKCU:\Software\Microsoft\input\TIPC" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Input\Settings" -Name "InsightsEnabled" -Type DWord -Value 0

# Customer Experience Improvement Program
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\AppV\CEIP" -Name "CEIPEnable" -Type DWord -Value 0

# Text Message Sync
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Messaging" -Name "AllowMessageSync" -Type DWord -Value 0

# Suggest ways to get the most out of Windows and finish setting up this device
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Type DWord -Value 0

# Windows Error Reporting
# Same as Disable-WindowsErrorReporting
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 1

# Biometrics
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Biometrics" -Name "Enabled" -Type DWord -Value 0

# Browser language fingerprint
# "Let websites show me locally relevant content by accessing my langauge list"
Set-Registry -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Type DWord -Value 1

# Activity History
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 0

# Clipboard
if ($ModeNorm) {
	Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -Type DWord -Value 0
	Set-Registry -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Type DWord -Value 0
	Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowCrossDeviceClipboard" -Type DWord -Value 0
}

# Disable "Steps Recorder" - Used for diagnostics and such
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableUAR" -Type DWord -Value 1

# Speech recognision automatic updates
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Speech" -Name "AllowSpeechModelUpdate" -Type DWord -Value 0

# Disable Experiments
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\System" -Name "AllowExperimentation" -Type DWord -Value 0

# Telemetry
Set-Registry -Path "HKLM:\System\CurrentControlSet\Services\DiagTrack" -Name "Start" -Type DWord -Value 4
Set-Registry -Path "HKLM:\System\CurrentControlSet\Services\dmwappushservice" -Name "Start" -Type DWord -Value 4
Set-Registry -Path "HKLM:\System\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener" -Name "Start" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" -Name "ShowedToastAtLevel" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\CPSS\Store" -Name "AllowTelemetry" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "LimitDiagnosticLogCollection" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DisableOneSettingsDownloads" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" -Name "NoGenTicket" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\MSDeploy\1" -Name "EnableTelemetry" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\MSDeploy\2" -Name "EnableTelemetry" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\MSDeploy\3" -Name "EnableTelemetry" -Type DWord -Value 0

# Windows Settings Sync
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" -Name "SyncPolicy" -Type DWord -Value 5
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\AppSync" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\StartLayout" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\PackageState" -Name "Enabled" -Type DWord -Value 0

# Feedback Reminders
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1
Set-Registry -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -Type DWord -Value 0

# Automatic map downloads
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name "AutoDownloadAndUpdateMapData" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name "AllowUntriggeredNetworkTrafficOnSettingsPage" -Type DWord -Value 0

# Location services and sensors
# Controlled with app permissions (see section "App Perms")
#Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Type DWord -Value 1
#Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableWindowsLocationProvider" -Type DWord -Value 1
#Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocationScripting" -Type DWord -Value 1
#Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableSensors" -Type DWord -Value 1
#Set-Registry -Path "HKLM:\System\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0
#Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0

# Input personalization
Set-Registry -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Type DWord -Value 1
Set-Registry -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Type DWord -Value 1
Set-Registry -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "AllowInputPersonalization" -Type DWord -Value 0

# Cortana
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Windows Search" -Name "CortanaConsent" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type DWord -Value 0
Set-Registry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCortanaButton" -Type DWord -Value 0

# Search Location
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowSearchToUseLocation" -Type DWord -Value 0

# Web and Cloud Search
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCloudSearch" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsMSACloudSearchEnabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsAADCloudSearchEnabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Type DWord -Value 1

# Taskbar feed
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 2

# Notifications
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND" -Type DWord -Value 0
#Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "EnableExpandedToastNotifications" -Type DWord -Value 0
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "DisallowNotificationMirroring" -Type DWord -Value 1
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "NoToastApplicationNotificationOnLockScreen" -Type DWord -Value 1
#Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "NoToastApplicationNotification" -Type DWord -Value 1
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "NoTileApplicationNotification" -Type DWord -Value 1
Set-Registry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "NoCloudApplicationNotification" -Type DWord -Value 1

# Windows Hello for Business
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "PassportForWork" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork" -Name "Enabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork" -Name "DisablePostLogonProvisioning" -Type DWord -Value 1


################################################################################################################################################################
# App Aliases
################################################################################################################################################################
"Configuring app aliases"

# Paint
Remove-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\mspaint.exe"
Remove-Item -Force -ErrorAction SilentlyContinue -Path "${env:LOCALAPPDATA}\Microsoft\WindowsApps\mspaint.exe"
Remove-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\pbrush.exe"
Remove-Item -Force -ErrorAction SilentlyContinue -Path "${env:LOCALAPPDATA}\Microsoft\WindowsApps\pbrush.exe"

# New notepad (10-seconds-to-launch version of notepad. still have system32/notepad)
Remove-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\notepad.exe"
Remove-Item -Force -ErrorAction SilentlyContinue -Path "${env:LOCALAPPDATA}\Microsoft\WindowsApps\notepad.exe"

# Restore fast notepad (system32/notepad.exe)
if ($WinVer -ge 11) {
	$null = Get-WindowsCapability -Online | ? Name -Like '*Notepad*' | Add-WindowsCapability -Online
	Remove-AppxPackageThorough -Name "Microsoft.WindowsNotepad" # Remove UWP version of notepad
	Set-Registry -Path "HKCU:\Software\Microsoft\Notepad" -Name "ShowStoreBanner" -Type DWord -Value 0 # Disable the "Notepad has an update, click here to launch"
	Remove-Registry -Path "HKCR:\Applications\notepad.exe" -Name "NoOpenWith" # Allow in "Open With" dialog.
	Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" # Remove some overrides
	Set-Registry -Path "HKCR:\txtfilelegacy\DefaultIcon" -Name "(Default)" -Type String -Value "imageres.dll,-102"
	Set-Registry -Path "HKCR:\txtfilelegacy\shell\open\command" -Name "(Default)" -Type String -Value 'C:\Windows\System32\notepad.exe "%1"'
	New-Shortcut -Path "$env:USERPROFILE\Favorites\Notepad.lnk" -Target "C:\Windows\System32\notepad.exe" -Args "" # Add a link in an indexable location (or else it wont show up in Windows Search)

	# Add text document back to new menu
	Set-Registry -Path "HKCR:\.txt\ShellNew" -Name "NullFile" -Type String -Value ""
	Set-Registry -Path "HKCR:\txtfilelegacy" -Name "(Default)" -Type String -Value "Text Document"
}

# Fake python (opens ms-store)
Remove-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\python.exe"
Remove-Item -Force -ErrorAction SilentlyContinue -Path "${env:LOCALAPPDATA}\Microsoft\WindowsApps\python.exe"
Remove-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\python3.exe"
Remove-Item -Force -ErrorAction SilentlyContinue -Path "${env:LOCALAPPDATA}\Microsoft\WindowsApps\python3.exe"


################################################################################################################################################################
# Performance / Game
################################################################################################################################################################
"Configuring performance / game settings"
# Disable fullscreen optimization to allow for true fullscreen.
# Known to cause perf issues with some games when enabled (all values 0 = enabled)
Set-Registry -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type DWord -Value 1
Set-Registry -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Type DWord -Value 2
Set-Registry -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Type DWord -Value 2
Set-Registry -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Type DWord -Value 1

# Disable auto GameMode
# TODO: need to do testing
#Set-Registry -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Type DWord -Value 0

# Disable Game Bar when pressing Xbox Nexus (home) button on controller
Set-Registry -Path "HKCU:\Software\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -Type DWord -Value 0

# Disable Archive Apps
# Can also do `$_.SID.ToString().Split("-")[-1]` to get RID.
# If RID >= 1000 then it is not a builtin account.
# I don't think there is any harm in just doing all of them though.
Get-LocalUser | %{$_.SID.ToString()} | %{Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\InstallService\Stubification\$_" -Name "EnableAppOffloading" -Type DWord -Value 0}

# GameDVR
Set-Registry -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Type DWord -Value 0


################################################################################################################################################################
# Power Settings
################################################################################################################################################################
"Configuring power settings"

# Disable hibernate
Set-Registry -Path "HKLM:\System\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\System\CurrentControlSet\Control\Power" -Name "HibernateEnabledDefault" -Type DWord -Value 0

# Fast Boot / Fast Startup
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Type DWord -Value 0

# TODO: configure power settings
#
# Set active scheme
# HKLM:\System\CurrentControlSet\Control\Power\User\PowerSchemes\ActivePowerScheme
#
# Some info under powercfg: https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options
# See: powercfg /query
#
# We can just create our own scheme instead of modifying existing one
#
# Configure a setting in a scheme (i assume AC = on wall, DC = on battery)
# HKLM:\System\CurrentControlSet\Control\Power\User\PowerSchemes\{scheme}\{setting}\ACSettingIndex
# HKLM:\System\CurrentControlSet\Control\Power\User\PowerSchemes\{scheme}\{setting}\DCSettingIndex

# Respect power mode settings while indexing
Set-RegistryOwner -Path "HKLM:\SOFTWARE\Microsoft\Windows Search"
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex" -Name "RespectPowerModes" -Type DWord -Value 1


################################################################################################################################################################
# Preferences
################################################################################################################################################################
"Configuring preferences..."
$ExplorerSettings = @(
	@{Name="HideIcons";               Val=0},
	@{Name="ShowCompColor";           Val=1},
	@{Name="ShowInfoTip";             Val=1},
	@{Name="ShowTypeOverlay";         Val=1},
	@{Name="StartMigratedBrowserPin"; Val=1},
	@{Name="StartShownOnUpgrade";     Val=1},
	@{Name="WinXMigrationLevel";      Val=1},
	#@{Name="WebView";                Val=1}, # Not sure what does
	@{Name="DisablePreviewDesktop";   Val=1}, # Disable desktop peeking
	@{Name="ListviewAlphaSelect";     Val=1}, # Desktop select blue square
	@{Name="ListviewShadow";          Val=1}, # Icon shadows
	@{Name="MapNetDrvBtn";            Val=0}, # Network drive button
	@{Name="ShowTaskViewButton";      Val=0}, # The "task view" icon, multiple desktops button
	@{Name="Start_SearchFiles";       Val=2}, # Search files from start menu
	@{Name="Start_TrackDocs";         Val=0}, # Recent Items in start menu
	@{Name="StartMenuInit";           Val=0xffffffff}, # Used to determine if windows should advertise new taskbar features
	@{Name="TaskbarSizeMove";         Val=0}, # Lock taskbar
	@{Name="TaskbarGlomLevel";        Val=0}, # Taskbar grouping (0=always, 1=when full, 2=never)
	@{Name="MMTaskbarGlomLevel";      Val=0}, # Taskbar grouping (0=always, 1=when full, 2=never)
	@{Name="DisallowShaking";         Val=1}, # Aero Shake

	# Taskbar
	@{Name="ShowCortanaButton"; Val=0}, # Cortana icon
	@{Name="TaskbarMn";         Val=0}, # Chat icon
	@{Name="TaskbarDa";         Val=0}, # Widgets icon
	@{Name="TaskbarSi";         Val=1}, # Taskbar icon size (0,1,2)
	@{Name="TaskbarSmallIcons"; Val=0}, # Taskbar icon size (old?)
	@{Name="TaskbarAl";         Val=1}, # Alignment 0=left, 1=center
	@{Name="TaskbarSh";         Val=0}, # Recent Searches
	@{Name="TaskbarSd";         Val=1}, # Show Desktop button
	@{Name="ExtendedUIHoverTime"; Val=1}, # Disable taskbar hover thumbnail preview delay
	@{Name="TaskbarAnimations";   Val=0}, # Disable taskbar hover thumbnail preview fade in/out

	# Explorer
	@{Name="DontPrettyPath";        Val=1}, # Show true file case
	@{Name="Hidden";                Val=+$ModeAggr}, # Hidden files and foldrs
	@{Name="ShowSuperHidden";       Val=0}, # Protected Operating System files - leave this of or you get desktop.ini all over the place
	@{Name="HideFileExt";           Val=0}, # File extensions
	@{Name="HideDrivesWithNoMedia"; Val=0}, # Show/Hide empty drives
	@{Name="HideMergeConflicts";    Val=0}, # Show/Hide merge conflicts
	@{Name="UseCompactMode";        Val=1}, # Use compact mode in explorer
	@{Name="ShowStatusBar";         Val=1}, # Show status bar in explorer
	@{Name="PersistBrowsers";       Val=0}, # Remember folder between restarts
	@{Name="SharingWizardOn";       Val=0}, # Sharing Wizard
	@{Name="LaunchTo";              Val=1}  # Open to "This PC" instead of "Home"
	@{Name="NavPaneExpandToCurrentFolder"; Val=0}  # Expanding folders
)

foreach ($set in $ExplorerSettings) {
	Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name $set.Name -Type DWord -Value $set.Val
}

# Hide explorer "Home"
Set-Registry -Path "HKCU:\Software\Classes\CLSID\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Name "System.IsPinnedToNameSpaceTree" -Type DWord -Value 0

# Disable Language Switching Hotkeys
# Yes, these are strings not dword.
Set-Registry -Path "HKCU:\Keyboard Layout\Toggle" -Name "Language Hotkey" -Type String -Value "3" # 3=Disabled
Set-Registry -Path "HKCU:\Keyboard Layout\Toggle" -Name "Layout Hotkey" -Type String -Value "3" # 3=Disabled
Set-Registry -Path "HKCU:\Keyboard Layout\Toggle" -Name "Hotkey" -Type String -Value "3" # 3=Disabled

# Language Bar
Set-Registry -Path "HKCU:\Software\Microsoft\CTF\LangBar" -Name "ShowStatus" -Type DWord -Value 3 # 0=floating, 3=hidden, 4=docked
Set-Registry -Path "HKCU:\Software\Microsoft\CTF\LangBar" -Name "Transparency" -Type DWord -Value 255
Set-Registry -Path "HKCU:\Software\Microsoft\CTF\LangBar" -Name "Label" -Type DWord -Value 1
Set-Registry -Path "HKCU:\Software\Microsoft\CTF\LangBar" -Name "ExtraIconsOnMinimized" -Type DWord -Value 0

# Snap Settings
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableSnapAssistFlyout" -Type DWord -Value 0 # When hovering min/max button
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableSnapBar" -Type DWord -Value 0 # At top center of screen
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableTaskGroups" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DITest" -Type DWord -Value 0 # Snap border size

# Don't show individual Edge tabs in alt+tab menu
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "MultiTaskingAltTabFilter" -Type DWord -Value 3 # (0=all, 1=5, 2=3, 3=disabled)

# Disable search filtering
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "SafeSearchMode" -Type DWord -Value 0

# Start menu
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecommendedSection" -Type DWord -Value 1 # Only works on Windows SE
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoStartMenuMFUprogramsList" -Type DWord -Value 1 # Recently Used Programs
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "ShowOrHideMostUsedApps" -Type DWord -Value 2 # 2 = hide

# Hide extra files
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowCloudFilesInQuickAccess" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Type DWord -Value 0

# Taskbar people icon
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 0

# Taskbar search icon
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0

# Taskbar "Meet now"
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Type DWord -Value 1
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Type DWord -Value 1

# Caret
Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "CaretTimeout" -Type DWord -Value 0x00001388
Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "CaretWidth" -Type DWord -Value 0x00000001
Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "CursorBlinkRate" -Type String -Value "600"

# Scroll wheel
Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "WheelScrollChars" -Type String -Value "3"
Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "WheelScrollLines" -Type String -Value "6"

# Lock screen timeout
Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "LockScreenAutoLockActive" -Type String -Value "0"

# Some animation settings
# Adjust under: run > SystemPropertiesAdvanced.exe > Advanced > Performance > Visual Effects
Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](0x90,0x1E,0x07,0x80,0x10,0x00,0x00,0x00))
Set-Registry -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "0"

# Disable Transparency
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Type DWord -Value 0

# Animate when min/max
Set-Registry -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value "1"

# Restore right click menu
Set-Registry -Path "HKCU:\Software\Classes\CLSID\{86CA1AA0-34AA-4E8B-A509-50C905BAE2A2}\InprocServer32" -Name "(Default)" -Type String -Value ""

# Detailed file operations
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Type DWord -Value 1

# Enable delete confim dialog
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ConfirmFileDelete" -Type DWord -Value 1

# Show all tray icons
# Enabled: EnableAutoTray = 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Type DWord -Value 0
# For older windows i think? idk. Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoAutoTrayNotify" -Type DWord -Value 1

# Verbose startup/shutdown
Set-Registry -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Type DWord -Value 1

# Disable lock screen - Goes directly to login screen
# There is also HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\SessionData\AllowLockScreen 0
# But as far as i can tell it doesn't do anything
#Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Type DWord -Value 1

# Show full path in explorer
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Name "FullPath" -Type DWord -Value 1

# Always show scrollbars
Set-Registry -Path "HKCU:\Control Panel\Accessibility" -Name "DynamicScrollbars" -Type DWord -Value 0

# Aero Peek
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 0


################################################################################################################################################################
# Context Menu
################################################################################################################################################################
"Configuring context menu shortcuts..."
Set-RegistryOwner -Path "HKCR:\Directory\Background\shell"

# Command Prompt (Admin)
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a1_cmd" -Name "(Default)" -Type String -Value "Open cmd window here as admin"
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a1_cmd" -Name "Icon" -Type String -Value "cmd.exe"
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a1_cmd" -Name "Extended" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a1_cmd" -Name "HasLUAShield" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a1_cmd" -Name "SeparatorBefore" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a1_cmd\command" -Name "(Default)" -Type String -Value "powershell -NoLogo -Sta -NonInteractive -NoProfile -WindowStyle hidden -Command `"Start cmd.exe -Verb RunAs -ArgumentList '/s /k pushd %v'`""

# PowerShell (Admin)
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a2_powershell" -Name "(Default)" -Type String -Value "Open PowerShell here as admin"
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a2_powershell" -Name "Icon" -Type String -Value "powershell.exe"
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a2_powershell" -Name "Extended" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a2_powershell" -Name "HasLUAShield" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_a2_powershell\command" -Name "(Default)" -Type String -Value "powershell -NoLogo -Sta -NonInteractive -NoProfile -Command `"Start powershell.exe -Verb RunAs -ArgumentList `"`"`"-NoExit -Command Set-Location -LiteralPath '%v'`"`"`"`""

# Command Prompt
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b1_cmd" -Name "(Default)" -Type String -Value "Open cmd window here"
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b1_cmd" -Name "Icon" -Type String -Value "cmd.exe"
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b1_cmd" -Name "SeparatorBefore" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b1_cmd\command" -Name "(Default)" -Type String -Value "cmd.exe /s /k pushd `"%V`""

# PowerShell
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b2_powershell" -Name "(Default)" -Type String -Value "Open PowerShell here"
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b2_powershell" -Name "Icon" -Type String -Value "powershell.exe"
Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b2_powershell\command" -Name "(Default)" -Type String -Value "powershell.exe -NoExit -Command Set-Location -LiteralPath '%V'"

# WSL
if ($ModeNorm) {
	Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b3_wsl" -Name "(Default)" -Type String -Value "Open WSL terminal here"
	Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b3_wsl" -Name "Icon" -Type String -Value "wsl.exe"
	# This should just be: "wsl.exe --cd `"%v`""
	# But as of 22h2? that doesnt work.
	# I THINK this is an issue with Windows selecting the one in: C:\Program Files\WindowsApps\MicrosoftCorporationII.WindowsSubsystemForLinux_1.0.3.0_x64__8wekyb3d8bbwe
	# and then having some permission error? Not sure. Event viewer shows error 0x23F.
	#
	# Trying to launch that file manually we get:
	#
	# {Application Error} The application was unable to start correctly (0x%lx). Click OK to close the application.
	# Error code: Wsl/Service/CreateInstance/CreateVm/0x8007023f
	#
	# https://github.com/microsoft/WSL/issues/5092
	# https://github.com/microsoft/WSL/issues/5401
	Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b3_wsl\command" -Name "(Default)" -Type String -Value "`"C:\Windows\System32\wsl.exe`" --cd `"%v`""
}

# Git Bash
#Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b4_git_shell" -Name "(Default)" -Type String -Value "Open git bash here"
#Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b4_git_shell" -Name "Icon" -Type String -Value "`"C:\\Program Files\\Git\\mingw64\\share\\git\\git-for-windows.ico`""
#Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b4_git_shell" -Name "SeparatorAfter" -Type String -Value ""
#Set-Registry -Path "HKCR:\Directory\Background\shell\dnlj_b4_git_shell\command" -Name "(Default)" -Type String -Value "`"C:\\Program Files\\Git\\git-bash.exe`" `"--cd=%v.`""

# Remove unwanted items
# TODO: look into ProgrammaticAccessOnly vs LegacyDisable
Set-Registry -Path "HKCR:\Directory\Background\shell\cmd" -Name "LegacyDisable" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\Powershell" -Name "LegacyDisable" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\WSL" -Name "LegacyDisable" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\git_shell" -Name "LegacyDisable" -Type String -Value ""
Set-Registry -Path "HKCR:\Directory\Background\shell\AnyCode" -Name "LegacyDisable" -Type String -Value ""
Set-Registry -Path "HKCR:\Python.File\shell\Edit with IDLE" -Name "LegacyDisable" -Type String -Value ""
Set-Registry -Path "HKCR:\Python.File\shell\editwithidle" -Name "LegacyDisable" -Type String -Value ""

# Unwanted shell extensions
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' -Name '{E2BF9676-5F8F-435C-97EB-11607A5BEDF7}' -Type String -Value 'dnlj: win10 "Share"'
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' -Name '{F81E9010-6EA4-11CE-A7FF-00AA003CA9F6}' -Type String -Value 'dnlj: win11 "Give access to"'
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' -Name '{9F156763-7844-4DC4-B2B1-901F640F5155}' -Type String -Value 'dnlj: win11 "Open in Terminal"'
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' -Name '{7AD84985-87B4-4a16-BE58-8B72A5B390F7}' -Type String -Value 'dnlj: "Cast to Device"'
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' -Name '{B8CDCB65-B1BF-4B42-9428-1DFDB7EE92AF}' -Type String -Value 'dnlj: "Extract All..."'

# Hide '3D Objects' in explorer
Remove-RegistryKey -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}'

# Attempt to fix 'Group By' in Downloads folder
# https://superuser.com/questions/1677995/what-registry-key-do-i-need-to-change-to-remove-group-by-downloads-folder-sear
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\Shell\{885A186E-A440-4ADA-812B-DB871B942259}' -Name 'GroupView' -Type DWord -Value 0
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\Shell\{885A186E-A440-4ADA-812B-DB871B942259}' -Name '(Default)' -Type String -Value 'Downloads'
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\ComDlg\{885a186e-a440-4ada-812b-db871b942259}' -Name 'GroupView' -Type DWord -Value 0
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\ComDlg\{885a186e-a440-4ada-812b-db871b942259}' -Name '(Default)' -Type String -Value 'Downloads'
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\ComDlgLegacy\{885a186e-a440-4ada-812b-db871b942259}' -Name 'GroupView' -Type DWord -Value 0
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\ComDlgLegacy\{885a186e-a440-4ada-812b-db871b942259}' -Name '(Default)' -Type String -Value 'Downloads'
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\Shell\{885a186e-a440-4ada-812b-db871b942259}' -Name 'GroupView' -Type DWord -Value 0
Set-Registry -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\Shell\{885a186e-a440-4ada-812b-db871b942259}' -Name '(Default)' -Type String -Value 'Downloads'

# "Add to Favorites"
Set-Registry -LiteralPath "HKCR:\*\shell\pintohomefile" -Name "ProgrammaticAccessOnly" -Type DWord -Value 1
Set-Registry -Path "HKCR:\Directory\shell\AddToPlaylistVLC" -Name "ProgrammaticAccessOnly" -Type DWord -Value 1
Set-Registry -Path "HKCR:\Directory\shell\AnyCode" -Name "ProgrammaticAccessOnly" -Type DWord -Value 1


################################################################################################################################################################
# Keyboard Setting
################################################################################################################################################################
"Configuring keyboard..."
Set-Registry -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "BounceTime" -Type String -Value "0"
Set-Registry -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Last BounceKey Setting" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Last Valid Delay" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Last Valid Repeat" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Last Valid Wait" -Type DWord -Value 0x000003e8
Set-Registry -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "DelayBeforeAcceptance" -Type String -Value "0"
Set-Registry -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatDelay" -Type String -Value "200"
Set-Registry -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "AutoRepeatRate" -Type String -Value "1"
Set-Registry -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Type String -Value "27"

Set-Registry -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "442"
Set-Registry -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Type String -Value "58"

# Remap Capslock > Ctrl
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" -Name "Scancode Map" -Type Binary -Value ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x1d,0x00,0x3a,0x00,0x00,0x00,0x00,0x00))


################################################################################################################################################################
# Mouse Setting
################################################################################################################################################################
"Configuring mouse..."
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "ActiveWindowTracking" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "MouseHoverTime" -Type String -Value "400"
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Type String -Value "10"
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "SnapToDefaultButton" -Type String -Value "0"
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "SwapMouseButtons" -Type String -Value "0"
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type String -Value "0"
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type String -Value "0"
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type String -Value "0"
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "MouseTrails" -Type String -Value "0"
Set-Registry -Path "HKCU:\Control Panel\Mouse" -Name "DoubleClickSpeed" -Type String -Value "800"

# Dont jump when using multiple monitors w/ different resolutions
Set-Registry -Path "HKCU:\Control Panel\Cursors" -Name "CursorDeadzoneJumpingSetting" -Type DWord -Value "0"


################################################################################################################################################################
# Cleanup
################################################################################################################################################################
"Cleaning up..."

Stop-Process -Force -Name "ShellExperienceHost" -ErrorAction SilentlyContinue
Stop-Process -Force -Name "explorer" -ErrorAction SilentlyContinue

$EndTime = Get-Date

# I think if we really wanted to we could load a DLL and send a WM_SETTINGCHANGE to avoid a restart.
# Sounds like pain.
Write-Host -ForegroundColor yellow "Some settings may require a restart to take effect."
Write-Host -ForegroundColor green "Complete in $($EndTime - $StartTime)."
Stop-Transcript
