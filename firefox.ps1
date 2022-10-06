#Requires -RunAsAdministrator
. .\helpers.ps1

function Find-Firefox {
	if ($install = Get-Item -Path "${Env:ProgramFiles}/*firefox*/firefox.exe") {
	} elseif ($install = Get-Item -Path "${Env:ProgramFiles(x86)}/*firefox*/firefox.exe") {
	} elseif ($install = Get-Item -Path "${Env:ProgramFiles}/*mozilla*/firefox.exe") {
	} elseif ($install = Get-Item -Path "${Env:ProgramFiles(x86)}/*mozilla*/firefox.exe") {
	}
	return $install
}

################################################################################################################################################################
# Install
################################################################################################################################################################
# Install options (non MSI)
# https://firefox-source-docs.mozilla.org/browser/installer/windows/installer/FullConfig.html
$InstallOptions = @(
	"/S", # Silent, don't open GUI
	"/TaskbarShortcut=true",
	"/DesktopShortcut=true",
	"/StartMenuShortcut=true", # This is just your start menu programs folder. Not pinned to the menu itself.
	"/MaintenanceService=false", # Dont install MaintenanceService. You can still get updates without MaintenanceService.
	"/OptionalExtensions=false", # Dont install any packaged extensions.
	"/RegisterDefaultAgent=false", # Just disables scheduled task. Doesnt affect current default browser.
	""
)

if (Find-Firefox) {
	"Existing Firefox installation found."
} else {
	"Installing Firefox..."
	& {
		$found = Get-ChildItem -Path "Firefox Setup*.exe"
		if (!$found) {
			Download -Dir "." -Url "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
		}

		$found = Get-ChildItem -Path "Firefox Setup*.exe"
		if ((!$found) -or ($found.Length -le 10mb)) {
			Write-Host -ForegroundColor red "Incorrect version of Firefox downloaded (stub or msi)."
		}

		"Running Firefox installer..."
		& "./Firefox Setup*.exe" $InstallOptions | Out-Null # Out-Null to force a wait
	}
	$installed = $true;
}


################################################################################################################################################################
# Policy
################################################################################################################################################################
"Configuring Firefox policy..."
# https://github.com/mozilla/policy-templates/blob/master/README.md
# https://wiki.mozilla.org/Security/Tracking_protection
# https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/internals/preferences.html#preferences
# https://www.stigviewer.com/stig/mozilla_firefox/
#
$policyRoot = @{}
$policies = ($policyRoot.policies = @{})
$policies[""]

$policies.DisableFeedbackCommands = $true
$policies.DisableFirefoxAccounts = $true # identity.fxaccounts.enabled
$policies.DisableFirefoxStudies = $true
$policies.DisableFormHistory = $true # browser.formfill.enable

$policies.DisablePocket = $true # extensions.pocket.enabled
$policies.DisableProfileRefresh = $true # browser.disableResetPrompt
$policies.DisableProfileImport = $true
$policies.DisableSetDesktopBackground = $true # removeSetDesktopBackground
$policies.DisplayBookmarksToolbar = $true # Initial state
$policies.DisableTelemetry = $true # datareporting.healthreport.uploadEnabled, datareporting.policy.dataSubmissionEnabled, toolkit.telemetry.archive.enabled
$policies.DisplayMenuBar = "default-off" # Initial state
$policies.DontCheckDefaultBrowser = $true # browser.shell.checkDefaultBrowser
$policies.NoDefaultBookmarks = $true
$policies.OfferToSaveLoginsDefault = $false # signon.rememberSignons
$policies.OverrideFirstRunPage = "" # empty = no extra pages. startup.homepage_welcome_url
$policies.OverridePostUpdatePage = "" # empty = no extra pages. startup.homepage_override_url
$policies.PrimaryPassword = $false
$policies.PromptForDownloadLocation = $true # browser.download.useDownloadDir
$policies.ShowHomeButton = $true
$policies.SanitizeOnShutdown = $false

# Only supported on ESR
#$policies.SearchEngines = @{}
#$policies.SearchEngines.Default = "Google"

$policies.Permissions = @{}
$policies.Permissions.Autoplay = @{}
$policies.Permissions.Autoplay.Default = "block-audio-video" # media.autoplay.default

$policies.DNSOverHTTPS = @{}
$policies.DNSOverHTTPS.Enabled = $true # network.trr.mode
$policies.DNSOverHTTPS.Locked = $false

$policies.EnableTrackingProtection = @{}
$policies.EnableTrackingProtection.Value = $true # privacy.trackingprotection.enabled, privacy.trackingprotection.pbmode.enabled
$policies.EnableTrackingProtection.Locked = $false
$policies.EnableTrackingProtection.Cryptomining = $true # privacy.trackingprotection.cryptomining.enabled
$policies.EnableTrackingProtection.Fingerprinting = $true # privacy.trackingprotection.fingerprinting.enabled

$policies.FirefoxHome = @{}
$policies.FirefoxHome.Search = $true # browser.newtabpage.activity-stream.showSearch
$policies.FirefoxHome.TopSites = $false # browser.newtabpage.activity-stream.feeds.topsites
$policies.FirefoxHome.SponsoredTopSites = $false # browser.newtabpage.activity-stream.showSponsoredTopSites
$policies.FirefoxHome.Highlights = $false # browser.newtabpage.activity-stream.feeds.section.highlights
$policies.FirefoxHome.Pocket = $false # browser.newtabpage.activity-stream.feeds.section.topstories
$policies.FirefoxHome.SponsoredPocket = $false # browser.newtabpage.activity-stream.showSponsored
$policies.FirefoxHome.Snippets = $false # browser.newtabpage.activity-stream.feeds.snippets
$policies.FirefoxHome.Locked = $false

$policies.UserMessaging = @{}
$policies.UserMessaging.WhatsNew = $false # browser.messaging-system.whatsNewPanel.enabled, browser.aboutwelcome.enabled
$policies.UserMessaging.ExtensionRecommendations = $false # browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons
$policies.UserMessaging.FeatureRecommendations = $false # browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features
$policies.UserMessaging.UrlbarInterventions = $false
$policies.UserMessaging.SkipOnboarding = $true
$policies.UserMessaging.MoreFromMozilla = $false # browser.preferences.moreFromMozilla


################################################################################################################################################################
# Extensions
################################################################################################################################################################
# Extensions can be downloaded directly but there isnt and easy way to install them:
# See: https://stackoverflow.com/questions/37728865/install-webextensions-on-firefox-from-the-command-line
# https://extensionworkshop.com/documentation/develop/extensions-and-the-add-on-id/
# Installed extension ids can also be seen on `about:support`
# Also https://github.com/mkaply/queryamoid
#
# Direct download URL:
# Format: https://addons.mozilla.org/firefox/downloads/file/{id}/addon-{id}-latest.xpi
# Example: https://addons.mozilla.org/firefox/downloads/file/4003969/addon-4003969-latest.xpi
#
# Can also download using the mozilla addon name (from the addon page):
# Format: https://addons.mozilla.org/firefox/downloads/latest/{name}/latest.xpi
# Example: https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi

$Extensions = @(
	@{Name="Absolute Enable Right Click & Copy"; Id="1205179"; Url="https://addons.mozilla.org/en-US/firefox/addon/absolute-enable-right-click/"; UID="{9350bc42-47fb-4598-ae0f-825e3dd9ceba}"},
	@{Name="Auto Tab Discard"; Id="4004129"; Url="https://addons.mozilla.org/en-US/firefox/addon/auto-tab-discard/"; UID="{c2c003ee-bd69-42a2-b0e9-6f34222cb046}"},
	@{Name="BetterTTV"; Id="4009945"; Url="https://addons.mozilla.org/en-US/firefox/addon/betterttv/"; UID="firefox@betterttv.net"},
	@{Name="ClearURLs"; Id="3980848"; Url="https://addons.mozilla.org/en-US/firefox/addon/clearurls/"; UID="{74145f27-f039-47ce-a470-a662b129930a}"},
	@{Name="Decentraleyes"; Id="3902154"; Url="https://addons.mozilla.org/en-US/firefox/addon/decentraleyes/"; UID="jid1-BoFifL9Vbdl2zQ@jetpack"},
	@{Name="Enhancer for YouTube"; Id="3964540"; Url="https://addons.mozilla.org/en-US/firefox/addon/enhancer-for-youtube/"; UID="enhancerforyoutube@maximerf.addons.mozilla.org"},
	@{Name="Hacker News Enhancement Suite"; Id="1078088"; Url="https://addons.mozilla.org/en-US/firefox/addon/hnes/"; UID="{0f0b7a9f-3e3b-4188-8ede-11bc2141272a}"},
	@{Name="Neat URL"; Id="3557562"; Url="https://addons.mozilla.org/en-US/firefox/addon/neat-url/"; UID="neaturl@hugsmile.eu"},
	@{Name="NoScript"; Id="4002416"; Url="https://addons.mozilla.org/en-US/firefox/addon/noscript/"; UID="{73a6fe31-595d-460b-a920-fcc0f8843232}"},
	@{Name="PoE Wiki Search"; Id="3840427"; Url="https://addons.mozilla.org/en-US/firefox/addon/poe-wiki-search/"; UID="{6b5a2fdc-482d-458c-95f3-9ac220b0b028}"},
	# Abandoned, we also have `privacy.resistFingerprinting` now. @{Name="Privacy Possum"; Id="3360398"; Url="https://addons.mozilla.org/en-US/firefox/addon/privacy-possum/"; UID="woop-NoopscooPsnSXQ@jetpack"},
	@{Name="Recipe Filter"; Id="981509"; Url="https://addons.mozilla.org/en-US/firefox/addon/recipe-filter/"; UID="{8b2164f4-fdb6-47eb-b692-312cc6d04f6b}"},
	@{Name="Reddit Enhancement Suite"; Id="3902655"; Url="https://addons.mozilla.org/en-US/firefox/addon/reddit-enhancement-suite/"; UID="jid1-xUfzOsOFlzSOXg@jetpack"},
	@{Name="Return YouTube Dislike"; Id="4005382"; Url="https://addons.mozilla.org/en-US/firefox/addon/return-youtube-dislikes/"; UID="{762f9885-5a13-4abd-9c77-433dcd38b8fd}"},
	@{Name="SoundFixer"; Id="3840849"; Url="https://addons.mozilla.org/en-US/firefox/addon/soundfixer/"; UID="soundfixer@unrelenting.technology"},
	@{Name="SponsorBlock for YouTube"; Id="4011816"; Url="https://addons.mozilla.org/en-US/firefox/addon/sponsorblock/"; UID="sponsorBlocker@ajay.app"},
	@{Name="Stylus"; Id="3995806"; Url="https://addons.mozilla.org/en-US/firefox/addon/styl-us/"; UID="{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}"},
	@{Name="Tab Session Manager"; Id="4002882"; Url="https://addons.mozilla.org/en-US/firefox/addon/tab-session-manager/"; UID="Tab-Session-Manager@sienori"},
	# Supposedly redundant with BTTV. @{Name="Twitch Adblock"; Id="3996079"; Url="https://addons.mozilla.org/en-US/firefox/addon/twitch-adblock/"; UID="{c961a5ba-dc89-44e9-9e52-93318dd95378}"},
	@{Name="uBlock Origin"; Id="4003969"; Url="https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/"; UID="uBlock0@raymondhill.net"},
	@{Name="Violentmonkey"; Id="4003302"; Url="https://addons.mozilla.org/en-US/firefox/addon/violentmonkey/"; UID="{aecec67f-0d10-4fa7-b7c7-609a2db280cf}"}
)

$policyRoot.policies.ExtensionSettings = @{}
foreach ($Ext in $Extensions) {
	$policies.ExtensionSettings[$Ext.UID] = @{}
	$policies.ExtensionSettings[$Ext.UID].installation_mode = "normal_installed"
	$policies.ExtensionSettings[$Ext.UID].install_url = "https://addons.mozilla.org/firefox/downloads/file/$($Ext.Id)/addon-$($Ext.Id)-latest.xpi"
}

if ($ff = Find-Firefox) {
	$Path = Join-Path (Convert-Path $ff.PSParentPath) "distribution"
	$null = New-Item -Force -Path $Path -ItemType "directory"
	# TODO: we really want `-Encoding utf8NoBOM` here but Windows ships with powershell5, which doesnt support that.
	ConvertTo-Json -Compress -Depth 100 $policyRoot | Out-File -Encoding ascii -NoNewline -FilePath (Join-Path $Path "policies.json")
} else {
	Write-Host -ForegroundColor yellow "Unable to find FireFox install location."
}

################################################################################################################################################################
# User.js
################################################################################################################################################################
"Setting up user profile..."

# Setup profile
& {
	$Name = "dnlj"
	$Path = Join-Path $Env:APPDATA "Mozilla\Firefox"
	$ProfPath = (Join-Path $Path "Profiles\$Name")
	$null = New-Item -Force -ItemType "directory" -Path (Join-Path $ProfPath "chrome")
	
	# http://kb.mozillazine.org/Profiles.ini_file
	#$profString = "[General]`nStartWithLastProfile=1`nVersion=2`n`n[Profile0]`nName=$Name`nIsRelative=1`nPath=Profiles/$Name`nDefault=1`nLocked=1`n"
	$profString = "[Install308046B0AF4A39CB]`nDefault=Profiles/$Name`nLocked=1`n`n[Profile0]`nName=$Name`nIsRelative=1`nPath=Profiles/$Name`nDefault=1`n`n[General]`nStartWithLastProfile=1`nVersion=2`n`n"
	$profString | Out-File -Encoding ascii -NoNewline -FilePath (Join-Path $Path "profiles.ini")
	'{"firstUse": 0,"created": 0}' | Out-File -Encoding ascii -NoNewline -FilePath (Join-Path $ProfPath "times.json")
	
	Copy-Item "firefox_user.js" -Destination (Join-Path $ProfPath "user.js")
	Copy-Item "firefox_userChrome.css" -Destination (Join-Path $ProfPath "chrome/userChrome.css")
}


################################################################################################################################################################
# Task Cleanup
################################################################################################################################################################
# We have to launch FireFox to get it to create its scheduled tasks
if ($installed -and $ff) {
	& $ff "about:preferences" "https://drive.google.com/drive/my-drive" "https://github.com/dnlj/UserTweaks"

	Start-Sleep -Seconds 3
	for ($i = 1; $i -le 10; $i++) {
		$found = Get-ScheduledTask | Where URI -Like "\Mozilla\*"
		if ($found) { break }
		Start-Sleep -Seconds 3
		"Waiting on FireFox scheduled tasks ($i/10)..."
	}

	if ($i -eq 11) {
		Write-Host -ForegroundColor red "Unable to find FireFox scheduled tasks. Did FireFox launch? Check Task Scheduler."
	} else {
		Disable-TasksLike "\Mozilla\*"
	}
}

# https://www.stigviewer.com/stig/mozilla_firefox/


################################################################################################################################################################
# Cleanup
################################################################################################################################################################
# Old extension code. We now use policies.
#$Extensions = $Extensions | %{"<a href='https://addons.mozilla.org/firefox/downloads/file/$($_.Id)/addon-$($_.Id)-latest.xpi'>$($_.Name) ($($_.Id))</a><br>"}
#"<!DOCTYPE html>
#<head>
#	<meta charset='utf-8'>
#	<title>FireFox Extensions</title>
#	<style>
#		* {
#			line-height: 1.6;
#			color: #61AFEF;
#			background: #282C34;
#			font-family: Consolas;
#			text-decoration: none;
#		}
#	</style>
#</head>
#<body>
#	$($Extensions -join "`n`t")
#</body>
#" > "extensions.html"
#
#if ($ff = Find-Firefox) {
#	& $ff (Join-Path $PSScriptRoot "extensions.html")
#}
