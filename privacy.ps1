#Requires -RunAsAdministrator
. .\helpers.ps1

try { $null = Stop-Transcript } catch {}
Start-Transcript -Append -Path "$PSScriptRoot/.dnlj.settings.$(Get-Date -F yyyyMMddTHHmmssffff).log"

$StartTime = Get-Date

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
	#"RotatingLockScreenEnabled",
	"RotatingLockScreenOverlayEnabled",
	"SilentInstalledAppsEnabled",
	"SlideshowEnabled",
	"SoftLandingEnabled", # Tips
	"SystemPaneSuggestionsEnabled"
)

$CloudContent = @(
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
$ServicesDisables_Microsoft = @(
	# General / Unsorted
	"DoSvc*", # Delivery Optimization
	"edgeupdate*", # Edge update services
	"MicrosoftEdgeElevationService*",
	"icssvc*", # Windows Mobile Hotspot Service
	"InstallService*", # Microsoft Store Install Service
	"InventorySvc*", # Inventory and Compatibility Appraisal service
	#"P9RdrService*" # Plan 9 File Server - Part of WSL
	"MapsBroker*", # Downloaded Maps Manager
	"PimIndexMaintenanceSvc*", # Contact Data indexing
	"RetailDemo*", # Retail Demo Service
	"WbioSrvc*", # Windows Biometric Service
	"WMPNetworkSvc*", # Windows Media Player Network Sharing Service
	"workfolderssvc*", # Work Folders
	"OneSyncSvc*", # Various syncing functionality
	"UnistoreSvc*", # User Data Storage
	"UserDataSvc*", # User Data Access
	"DevicesFlowUserSvc*",
	"DevicePickerUserSvc*",
	"DeviceAssociationBrokerSvc*",
	"NPSMSvc*", # Now playing session manager
	"AppReadiness", # App Readiness - Windows Store app install and setup
	"cbdhsvc*", # Clipboard service - for enhanceed clipboard: history, device sharing, etc.
	# ! DONT DISABLE ! "TextInputManagementService*", # DONT DISABLE: breaks keyboard input.
	
	# Privacy, Tracking, and Telemetry
	"SSDPSRV", # SSDP Discovery - Simple Search and Discovery Protocol
	"lfsvc", # Geolocation Service
	"AJRouter*", # AllJoyn Router Service - IoT stuff - https://en.wikipedia.org/wiki/AllJoyn
	"HomeGroup*", # Multiple homegroup related services
	"SharedAccess*", # Internet Connection Sharing (ICS)
	"diagnosticshub.standardcollector.service*", # Microsoft (R) Diagnostics Hub Standard Collector Service
	"diagsvc", # Diagnostic Execution Service
	"DiagTrack", # Connected User Experiences and Telemetry 
	"lltdsvc", # Link-Layer Topology Discovery Mapper   
	"NetTcpPortSharing", # Net.Tcp Port Sharing Service

	# Phone and Printers
	"PhoneSvc*", # Phone Service
	"TapiSrv*", # Telephony
	"MessagingService*", # Text messaging and related functionality
	"SmsRouter", # Microsoft Windows SMS Router Service

	# Mixed Reality
	"*MixedReality*", # Windows Mixed Reality OpenXR Service
	"SharedRealitySvc*", # Spatial Data Service

	# Peer to peer
	"p2pimsvc*", # Peer Networking Identity Manager
	"p2psvc*", # Peer Networking Grouping
	"PeerDistSvc*", # BranchCache
	"PNRPAutoReg*", # PNRP Machine Name Publication Service
	"PNRPsvc*", # Peer Name Resolution Protocol

	# Remote Access, Desktop, and Management
	"EntAppSvc*", # Enterprise App Management Service
	"PushToInstall*", # Windows PushToInstall Service - remote app installation
	"RasAuto*", # Remote Access Auto Connection Manager
	"RasMan*", # Remote Access Connection Manager
	"RemoteAccess*", # Routing and Remote Access
	"RemoteRegistry*", # Remote Registry
	"SessionEnv*", # Remote Desktop Configuration
	"TermService*", # Remote Desktop Services
	"UmRdpService*", # Remote Desktop Services UserMode Port Redirector
	# ! DONT DISABLE ! "Winmgmt*", # Windows Management Instrumentation - DONT DISABLE: Breaks updates, add/remove capabilities, some powershell commands.
	"WinRM*", # Windows Remote Management (WS-Management)
	"DmEnrollmentSvc*", # Device Management Enrollment Service
	"dmwappushservice*", # Device Management Wireless Application Protocol (WAP) Push message Routing Service dmwappushservice
	"LanmanWorkstation*", # Network file sharing, SMB protocol

	# Printers
	"PrintNotify*", # Printer Extensions and Notifications
	"PrintWorkflowUserSvc*",
	# "Spooler*", # Print Spooler

	# Authorization, Payment, and Sharing
	"SCardSvr*", # Smart Card
	"ScDeviceEnum*", # Smart Card Device Enumeration Service
	"SCPolicySvc*", # Smart Card Removal Policy
	"SEMgrSvc*", # Payments and NFC/SE Manager
	"WalletService*", # Wallet Service
	"CDPSvc*", # Connected Devices Platform Service
	"CDPUserSvc*", # Connected Devices Platform User Service_4b694

	# Gaming
	# Disabling some of these may break XInput and/or Windows.Gaming.Input
	"BcastDVR*",
	"CaptureService*",
	"XblAuthManager*", # Xbox Live Auth Manager
	"XblGameSave*", # Xbox Live Game Save
	"XboxGipSvc*", # Xbox Accessory Management Service
	"XboxNetApiSvc" # Xbox Live Networking Service
	#"xboxgip*",
	#"xinputhid*",
)

# We manually iterate the registry instead of using `Get-Service` here because
# get service doesnt include per-user service templates unless you explicitly ask
# for it by exact name
#
# https://learn.microsoft.com/en-us/windows/application-management/per-user-services-in-windows
#
$ServicesList = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services"
foreach ($rule in $ServicesDisables_Microsoft) {
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
	"*MicrosoftEdge*",
	"*OneDrive*",
	"\Microsoft\Windows\Feedback\Siuf\DmClient*" # Device management
	#"WinSAT", # Measures a system's performance and capabilities
	"\Microsoft\Windows\Management\Provisioning\Cellular", # SIM integration
	"\Microsoft\Windows\Maps\Maps*",
	"\Microsoft*WiFiTask", # Background task for performing per user and web interactions
	"\Microsoft\Windows\Offline Files\Background Synchronization", # This task controls periodic background synchronization of Offline Files when the user is working in an offline mode.
	"\Microsoft\Windows\Offline Files\Logon Synchronization", # This task initiates synchronization of Offline Files when a user logs onto the system.
	"\Microsoft\Windows\Printing\EduPrintProv",
	"\Microsoft\Windows\RemoteAssistance*", # Checks group policy for changes relevant to Remote Assistance
	"\Microsoft\Windows\Work Folders*",
	"\Microsoft*FamilySafety*", # Initializes Family Safety monitoring and enforcement @ Synchronizes the latest settings with the Microsoft family features service
	"\Microsoft\XblGameSave\XblGameSaveTask",
	"\Microsoft\Windows\WwanSvc\NotificationTask", # Background task for performing per user and web interactions
	"\Microsoft\Windows\Application Experience\StartupAppTask", # Scans startup entries and raises notification to the user if there are too many startup entries.
	"\Microsoft\Windows\WindowsUpdate\Scheduled Start" # This task is used to start the Windows Update service when needed to perform scheduled operations such as scans.
	"\Microsoft\Windows\PushToInstall\Registration", # Push to install stuff
	
	# Customer Experience Program
	# Get-ScheduledTask | Where Description -Like "*Customer Experience*"
	"\Microsoft\Windows\Customer Experience Improvement Program\Consolidator", # If the user has consented to participate in the Windows Customer Experience Improvement Program, this job collects and sends usage data to Microsoft.
	"\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip", # The USB CEIP (Customer Experience Improvement Program) task collects Universal Serial Bus related statistics and information about your machine and sends it to the Windows Device Connectivity engineering...
	"*KernelCEIPTask*",
	"\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector", # The Windows Disk Diagnostic reports general disk and system information to Microsoft for users participating in the Customer Experience Program.
	"\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser", # Collects program telemetry information if opted-in to the Microsoft Customer Experience Improvement Program.
	"\Microsoft\Windows\Autochk\Proxy", # This task collects and uploads autochk SQM data if opted-in to the Microsoft Customer Experience Improvement Program.
	
	# Workplace
	"\Microsoft\Windows\Workplace Join\Automatic-Device-Join", # Register this computer if the computer is already joined to an Active Directory domain.
	"\Microsoft\Windows\Workplace Join\Device-Sync", # Sync device attributes to Azure Active Directory.
	"\Microsoft\Windows\Workplace Join\Recovery-Check", # Performs recovery check.
	
	# Windows Update
	"\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker", # Forces rebooot after update
	"\Microsoft\Windows\UpdateOrchestrator\Refresh Settings",
	#"\Microsoft\Windows\UpdateOrchestrator\Report policies",
	#"\Microsoft\Windows\UpdateOrchestrator\Schedule scan",
	#"\Microsoft\Windows\UpdateOrchestrator\Schedule scan static task",
	#"\Microsoft\Windows\UpdateOrchestrator\Schedule work",
	#"\Microsoft\Windows\UpdateOrchestrator\UUS Failover Task",
	
	# Out of box experience
	# Get-ScheduledTask | Where URI -like "*oobe*"
	"\Microsoft\Windows\UpdateOrchestrator\Start Oobe Expedite Work",
	"\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScanAfterUpdate",
	"\Microsoft\Windows\UpdateOrchestrator\StartOobeAppsScan_LicenseAccepted",
	"\Microsoft\Windows\WwanSvc\OobeDiscovery"
)

# Fix access issues for UpdateOrchestrator tasks
$null = takeown /F "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator" /A /R
$null = icacls "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator" /grant *S-1-5-32-544:F /T

Disable-TasksLike $TaskDisables

################################################################################################################################################################
# Firewall
################################################################################################################################################################
"Configuring firewall..."
# Get-NetFirewallRule | Format-Table DisplayName, Group, DisplayGroup, Description -AutoSize
$FirewallDisables = @(
	# Specific apps
	"Cortana",
	"Feedback Hub",
	"Get Help",
	"Microsoft family features",
	"Microsoft Tips",
	"Microsoft People",
	"Microsoft Photos",
	"Microsoft Teams",
	"Microsoft To Do",
	"Microsoft Content",
	"Movies & TV",
	"MSN Weather",
	"Take a test",
	"Windows Calculator",
	"Windows Camera",
	"Windows Media Player",
	"*Solitaire*",

	# Wild cards
	"*Delivery Optimization*",
	"*Cast to Device*",
	"*File and Printer Sharing*",
	"*Work or School*",
	"*Xbox*",
	
	# Remote Access, Desktop, Discovery, Management
	"*AllJoyn*",
	"*Proximity sharing*",
	"*Remote Event*",
	"*Remote Service Management*",
	"*Remote Scheduled*",
	"*Remote Volume Management*",
	"*Remote Access*",
	"*Remote Assist*",
	"*Remote Desktop*",
	"Windows Device Management*",
	"Microsoft Media Foundation Network*"
	"*Network Discovery*",
	"*BranchCache*",
	
	# Third party
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
	"*Tiktok*",
	"*Bytedance*"
)

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
# App Perm
################################################################################################################################################################
"Configuring app permisions..."

# Set as though changed through Windows settings UI
$AppPerm_UserChoice = @(
	"userAccountInformation",
	"appDiagnostics",
	"location",
	"webcam",
	"microphone",
	"activity",
	"contacts",
	"appointments",
	"phoneCall",
	"phoneCallHistory",
	"email",
	"userDataTasks",
	"chat",
	"radios",
	"bluetoothSync",
	"videosLibrary",
	"picturesLibrary",
	"documentsLibrary",
	"broadFileSystemAccess",
	"cellularData",
	"gazeInput",
	"graphicsCaptureProgrammatic",
	"graphicsCaptureWithoutBorder",
	"musicLibrary",
	"downloadsFolder"
)

foreach ($perm in $AppPerm_UserChoice) {
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
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Type DWord -Value 2 # 0 = User Control, 1 = Allow, 2 = Deny
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplication" -Name "GlobalUserDisabled" -Type DWord -Value 1 # 1 = Off
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplication" -Name "BackgroundAppGlobalToggle" -Type DWord -Value 0 # 0 = Off

################################################################################################################################################################
# Security
# See also: $FirewallDisables
################################################################################################################################################################
"Configuring security settings..."
# Disable administrative shares
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareServer" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "AutoShareWks" -Type DWord -Value 0

# User Account Control
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Type DWord -Value 0

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

# Lock Screen notifications
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Type DWord -Value 0

# Disable wifi sense
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowInternetSharing" -Name "Value" -Type DWord -Value 0

# Disable Peernet
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Peernet" -Name "Disabled" -Type DWord -Value 1

# SmartScreen
# TODO: https://www.stigviewer.com/stig/microsoft_windows_10/2022-04-08/finding/V-220836
#Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Type DWord -Value 0

################################################################################################################################################################
# Updates
################################################################################################################################################################
"Configuring update settings..."

# Windows Updates
#
# WARNING: Windows Defender uses Windows Update. Disabling this will prevent Window Defender for receiving updates.
#
# NoAutoUpdate: 0=enabled, 1=disabled
# AUOptions:
# 	2=notify dl
# 	3=auto dl, notify install
# 	4=auto dl + auto install
# 	5=use local settings
# 	7=notify install + notify restart
# wuauserv: windows update service, 3 = manual start
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 2
Set-Registry -Path "HKLM:\System\CurrentControlSet\Services\wuauserv" -Name "Start" -Type DWord -Value 3

# Create a task to update Windows Defender even if updates are turned off
# https://www.microsoft.com/en-us/wdsi/defenderupdates
# Times use ISO 8601 durations: https://en.wikipedia.org/wiki/ISO_8601#Durations
&{
	try {
		$ErrorActionPreference = "Stop"
		$user = "NT AUTHORITY\SYSTEM"
		$name = "Windows Defender Update"
		$path = "\dnlj\"
		$full = Join-Path $path $name
		
		$action = New-ScheduledTaskAction -Execute "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Argument "-SignatureUpdate"
		$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -StartWhenAvailable -MultipleInstances IgnoreNew -DontStopIfGoingOnBatteries
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
}

# Driver Updates
# You can also allow/deny specific devies with Group Policy.
# `Local Computer Policy → Computer Configuration → Administrative Templates → System → Device Installation → Device Installation Restrictions`
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1

# Stability (these do not affect security updates)
# See https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-update
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "BranchReadinessLevel" -Type DWord -Value 16 # 16 = Semi Annual
# DOES affect security updates: Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferUpgrade" -Type DWord -Value 1
# DOES affect security updates: Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferUpgradePeriod" -Type DWord -Value 6 # Months
# DOES affect security updates: Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferUpdatePeriod" -Type DWord -Value 4 # Weeks

# Quality Updates
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferQualityUpdates" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 30 # Days, max 30
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "PauseQualityUpdatesStartTime" -Type String -Value ""

# Feature Updates
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdates" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 180 # Days, max 365
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "PauseFeatureUpdatesStartTime" -Type String -Value ""

# Windows auto restart (1=disable, 0=enable)
# Maybe? i cant find any info on this setting, we already disasbled in in tasks section
#Set-Register -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Type DWord -Value 1

# Peer to peer downloads
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization" -Name "SystemSettingsDownloadMode" -Type DWord -Value 0

# Disable automatic updates for non-windows things
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" -Name "AutoDownload" -Type DWord -Value 2
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "AutoDownload" -Type DWord -Value 2
#Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\7971f918-a847-4430-9279-4a52d1efe18d" -Name "RegisteredWithAU" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1

# Wake for updates
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" -Name "WakeUp" -Type DWord -Value 0

# Automatic sign on after restart
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableAutomaticRestartSignOn" -Type DWord -Value 1


################################################################################################################################################################
# Edge
################################################################################################################################################################
"Configuring Microsoft Edge..."

# Chromium
# Can also be configured under HKCU if you want.
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ConfigureDoNotTrack" -Type DWord -Value 1
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "PaymentMethodQueryEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "PersonalizationReportingEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AddressBarMicrosoftSearchInBingProviderEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AutofillCreditCardEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AutofillAddressEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "LocalProvidersEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "SearchSuggestEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "EdgeShoppingAssistantEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "WebWidgetAllowed" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ResolveNavigationErrorsUseWebService" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AlternateErrorPagesEnabled" -Type DWord -Value 0 # Suggest similar sites
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "NetworkPredictionOptions" -Type DWord -Value 2
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "WebWidgetIsEnabledOnStartup" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "SyncDisabled" -Type DWord -Value 1
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ShowMicrosoftRewards" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "MediaRouterCastAllowAllIPs" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ConfigureOnlineTextToSpeech" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "SpeechRecognitionEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ConfigureShare" -Type DWord -Value 1
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AutofillAddressEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "AutofillCreditCardEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "HideInternetExplorerRedirectUXForIncompatibleSitesEnabled" -Type DWord -Value 1
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "RedirectSitesFromInternetExplorerRedirectMode" -Type DWord -Value 0
Set-Registry -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "DefaultBrowserSettingEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "AutofillCreditCardEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "DisableEdgeDesktopShortcutCreation" -Type DWord -Value 1

# SmartScreen (Chromium)
Set-Registry -Path "HKCU:\Software\Policies\Microsoft\Edge" -Name "SmartScreenEnabled" -Type DWord -Value 0

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
Set-Registry -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" -Name "EnabledV9" -Type DWord -Value 0


################################################################################################################################################################
# Privacy
################################################################################################################################################################
"Configuring privacy settings..."

# Disable UserAssist (program tracking)
Set-Registry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Type DWord -Value 0
Set-Registry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackEnabled" -Type DWord -Value 0

# Disable News and Interests
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests" -Name "AllowNewsAndInterests" -Type DWord -Value 0

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
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice" -Name "AllowFindMyDevice" -Type DWord -Value 0

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
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSync" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1

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
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowCrossDeviceClipboard" -Type DWord -Value 0

# Password Reveal
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredUI" -Name "DisablePasswordReveal" -Type DWord -Value 1

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

# Feedback Reminders
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1
Set-Registry -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
Set-Registry -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -Type DWord -Value 0

# Automatic map downloads
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name "AutoDownloadAndUpdateMapData" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name "AllowUntriggeredNetworkTrafficOnSettingsPage" -Type DWord -Value 0

# Location services and sensors
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableWindowsLocationProvider" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocationScripting" -Type DWord -Value 1
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableSensors" -Type DWord -Value 1
Set-Registry -Path "HKLM:\System\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0

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

# GameDVR
Set-Registry -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Type DWord -Value 0

# Suggestion notifications
Set-Registry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested" -Name "Enabled" -Type DWord -Value 0


################################################################################################################################################################
# Performance
################################################################################################################################################################
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
	@{Name="Hidden";                Val=1}, # Hidden files and foldrs
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
# Power Settings
################################################################################################################################################################
# Disable hibernate
Set-Registry -Path "HKLM:\System\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Type DWord -Value 0
Set-Registry -Path "HKLM:\System\CurrentControlSet\Control\Power" -Name "HibernateEnabledDefault" -Type DWord -Value 0

# Fast Boot
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
# Cant be set through powershell for some reason. Get a System.Security.SecurityException
# 
# If we really care we can mess up access rules with something like:
#   @{
#       $Path = "HKLM:\SOFTWARE\Microsoft\Windows Search\Gather"
#       $Rule = New-Object -TypeName System.Security.AccessControl.RegistryAccessRule -ArgumentList ("BUILTIN\Administrators", "FullControl", 1, 2, "Allow")
#       $Acl = Get-Acl -Path $Path
#       # Not sure what all we have to change to get this working
#       # I think we need to take ownership and nuke inheritance (Like right click > perm > adv > take ownership > both checkboxes)
#       # At least thats what we have to do through regedit to get it to work
#       #
#       # https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registryaccessrule
#       # https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.registrysecurity
#       # https://www.ipswitch.com/blog/how-to-change-registry-permissions-with-powershell
#       # .SetOwner? .SetAccessRuleProtection? Audit rules? See: `$Acl | Get-Member`
#       $Acl.AddAccessRule($Rule)
#       $Acl | Set-Acl -Path $Path
#   }
#
# But i cant be bothered to get this working right now.
#
#Set-Registry -Path "HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Windows\SystemIndex" -Name "RespectPowerModes" -Type DWord -Value 1

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
