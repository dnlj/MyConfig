#Requires -RunAsAdministrator
. .\helpers.ps1

try { $null = Stop-Transcript } catch {}
Start-Transcript -Append -Path "$PSScriptRoot/.dnlj.firefox.$(Get-Date -F yyyyMMddTHHmmssffff).log"

function Find-FireFox {
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

if (Find-FireFox) {
	"Existing FireFox installation found."
} else {
	"Installing FireFox..."
	& {
		$found = Get-ChildItem -Path "FireFox Setup*.exe"
		if (!$found) {
			Download -Dir "." -Url "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
		}
		
		$found = Get-ChildItem -Path "FireFox Setup*.exe"
		if ((!$found) -or ($found.Length -le 10mb)) {
			Write-Host -ForegroundColor red "Incorrect version of FireFox downloaded (stub or msi)."
		}
			
		"Running FireFox installer..."
		& "./FireFox Setup*.exe" $InstallOptions | Out-Null # Out-Null to force a wait
	}
}


################################################################################################################################################################
# Configure
################################################################################################################################################################
$FirstLaunch = @(
	#"-setDefaultBrowser", # Just opens windows settings
	#"-foreground", # Causes window to blink
	"about:preferences" # Open to pref page
)

& { # We have to launch FireFox to get it to create its scheduled tasks
	$found = Find-FireFox;
	if (!$found) {
		Write-Host -ForegroundColor yellow "Unable to find FireFox install location."
	} else {
		& $found $FirstLaunch
		
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
}


################################################################################################################################################################
# Extensions
################################################################################################################################################################
"Bulding FireFox extensions page..."

# Extensions can be downloaded directly but there isnt and easy way to install them:
# See: https://stackoverflow.com/questions/37728865/install-webextensions-on-firefox-from-the-command-line
# https://extensionworkshop.com/documentation/develop/extensions-and-the-add-on-id/
#
# Direct download URL:
# Format: https://addons.mozilla.org/firefox/downloads/file/{id}/addon-{id}-latest.xpi
# Example: https://addons.mozilla.org/firefox/downloads/file/4003969/addon-4003969-latest.xpi
#
$Extensions = @(
	@{Name="uBlock Origin"; Id="4003969"; Url="https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/"},
	@{Name="BetterTTV"; Id="4009945"; Url="https://addons.mozilla.org/en-US/firefox/addon/betterttv/"},
	@{Name="Auto Tab Discard"; Id="4004129"; Url="https://addons.mozilla.org/en-US/firefox/addon/auto-tab-discard/"},
	@{Name="ClearURLs"; Id="3980848"; Url="https://addons.mozilla.org/en-US/firefox/addon/clearurls/"},
	@{Name="Decentraleyes"; Id="3902154"; Url="https://addons.mozilla.org/en-US/firefox/addon/decentraleyes/"},
	@{Name="Enhancer for YouTube"; Id="3964540"; Url="https://addons.mozilla.org/en-US/firefox/addon/enhancer-for-youtube/"},
	@{Name="Hacker News Enhancement Suite"; Id="1078088"; Url="https://addons.mozilla.org/en-US/firefox/addon/hnes/"},
	@{Name="Neat URL"; Id="3557562"; Url="https://addons.mozilla.org/en-US/firefox/addon/neat-url/"},
	@{Name="NoScript"; Id="4002416"; Url="https://addons.mozilla.org/en-US/firefox/addon/noscript/"},
	@{Name="PoE Wiki Search"; Id="3840427"; Url="https://addons.mozilla.org/en-US/firefox/addon/poe-wiki-search/"},
	@{Name="Privacy Possum"; Id="3360398"; Url="https://addons.mozilla.org/en-US/firefox/addon/privacy-possum/"},
	@{Name="Recipe Filter"; Id="981509"; Url="https://addons.mozilla.org/en-US/firefox/addon/recipe-filter/"},
	@{Name="Reddit Enhancement Suite"; Id="3902655"; Url="https://addons.mozilla.org/en-US/firefox/addon/reddit-enhancement-suite/"},
	@{Name="Return YouTube Dislike"; Id="4005382"; Url="https://addons.mozilla.org/en-US/firefox/addon/return-youtube-dislikes/"},
	@{Name="SoundFixer"; Id="3840849"; Url="https://addons.mozilla.org/en-US/firefox/addon/soundfixer/"},
	@{Name="SponsorBlock for YouTube"; Id="4011816"; Url="https://addons.mozilla.org/en-US/firefox/addon/sponsorblock/"},
	@{Name="Stylus"; Id="3995806"; Url="https://addons.mozilla.org/en-US/firefox/addon/styl-us/"},
	@{Name="Tab Session Manager"; Id="4002882"; Url="https://addons.mozilla.org/en-US/firefox/addon/tab-session-manager/"},
	@{Name="Twitch Adblock"; Id="3996079"; Url="https://addons.mozilla.org/en-US/firefox/addon/twitch-adblock/"},
	@{Name="Violentmonkey"; Id="4003302"; Url="https://addons.mozilla.org/en-US/firefox/addon/violentmonkey/"},
	@{Name="Absolute Enable Right Click & Copy"; Id="1205179"; Url="https://addons.mozilla.org/en-US/firefox/addon/absolute-enable-right-click/"}
)

$Extensions = $Extensions | %{"<a href='https://addons.mozilla.org/firefox/downloads/file/$($_.Id)/addon-$($_.Id)-latest.xpi'>$($_.Name) ($($_.Id))</a><br>"}
"<!DOCTYPE html>
<head>
	<meta charset='utf-8'>
	<title>FireFox Extensions</title>
	<style>
		* {
			line-height: 1.6;
			color: #61AFEF;
			background: #282C34;
			font-family: Consolas;
			text-decoration: none;
		}
	</style>
</head>
<body>
	$($Extensions -join "`n`t")
</body>
" > "extensions.html"

if ($ff = Find-FireFox) {
	& $ff (Join-Path $PSScriptRoot "extensions.html")
}

Stop-Transcript