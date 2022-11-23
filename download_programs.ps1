. .\helpers.ps1

try { $null = Stop-Transcript } catch {}
Start-Transcript -Append -Path "C:\.dnlj\logs\.dnlj.download_programs.$(Get-Date -F yyyyMMddTHHmmssffff).log"

"Downloading programs."

$programs = @(
################################################################################
# General
################################################################################
	# See firefox.ps1
	#@{ # FireFox
	#	Type="Install";
	#	Page="https://www.mozilla.org/en-US/firefox/all/#product-desktop-release";
	#	Down="https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
	#},
	@{ # Steam Desktop Client
		Type="Install";
		Page="https://store.steampowered.com/about/";
		Down="https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
	},
	@{ # Epic Games
		Type="Install";
		Page="https://store.epicgames.com/en-US/download";
		Down="https://launcher-public-service-prod.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi"
	},
	@{ # Origin
		Type="Install";
		Page="https://www.origin.com/usa/en-us/store/download";
		Down="https://download.dm.origin.com/origin/live/OriginSetup.exe"
	},
	@{ # Battle.net
		Type="Install";
		Page="https://www.blizzard.com/en-us/download/";
		Down="https://www.battle.net/download/getInstallerForGame?os=win&gameProgram=BATTLENET_APP"
	},
	@{ # Discord
		Type="Install";
		Page="https://discord.com/download";
		Down="https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x86"
	},
	@{ # Path of Building
		Type="Install";
		Page="https://github.com/PathOfBuildingCommunity/PathOfBuilding/releases/latest";
		Down=""
	},
	@{ # Cura
		Type="Install";
		Page="https://ultimaker.com/software/ultimaker-cura";
		Down=""
	},
	@{ # Blender
		Type="Install";
		Page="https://www.blender.org/download/";
		Down=""
	},
################################################################################
# Drives & Support
################################################################################
	@{ # Logitech G Hub
		Type="Driver";
		Page="https://support.logi.com/hc/en-us/articles/360025298133";
		Down="https://download01.logi.com/web/ftp/pub/techsupport/gaming/lghub_installer.exe"
	},
	#@{ # NVIDIA Drivers
	#	Type="Driver";
	#	Page="https://www.nvidia.com/download/index.aspx";
	#	Down=""
	#},
	#@{ # AMD Drivers / Ryzen Master
	#	Type="Driver";
	#	Page="https://www.amd.com/en/support";
	#	Down=""
	#},
	@{ # Focusrite Scarlett 2i2
		Type="Driver";
		Page="https://downloads.focusrite.com/focusrite/scarlett-2nd-gen/scarlett-2i2-2nd-gen";
		Down=""
	},
################################################################################
# Utility / Productivity
################################################################################
	@{ # Audacity (pre telemetry = 3.0.2)
		Type="Install";
		Page="https://github.com/audacity/audacity/releases/tag/Audacity-3.0.2";
		Down="https://github.com/audacity/audacity/releases/download/Audacity-3.0.2/audacity-win-3.0.2.exe"
	},
	@{ # VLC
		Type="Install";
		Page="https://www.videolan.org/vlc/download-windows.html";
		Down=""
	},
	@{ # WinDirStat
		Type="Install";
		Page="https://windirstat.net/download.html";
		Down="https://windirstat.net/wds_current_setup.exe"
	},
	@{ # FileZilla
		Type="Install";
		Page="https://filezilla-project.org/download.php?show_all=1&type=client";
		Down=""
	},
	@{ # WinRAR
		Type="Install";
		Page="https://www.win-rar.com/download.html?&L=0";
		Down=""
	},
	#@{ # 7-Zip
	#	Type="Install";
	#	Page="https://www.7-zip.org/download.html";
	#	Down=""
	#},
	@{ # Foxit PDF Reader
		Type="Install";
		Page="https://www.foxit.com/downloads#Foxit-Reader";
		Down="https://www.foxit.com/downloads/latest.html?product=Foxit-Reader&platform=Windows&version=&package_type=&language=English"
	},
	@{ # Mouse without Borders 
		Type="Install";
		Page="https://www.microsoft.com/en-us/download/details.aspx?id=35460";
		Down="https://download.microsoft.com/download/6/5/8/658AFC4C-DC02-4CB8-839D-10253E89FFF7/MouseWithoutBordersSetup.msi"
	},
	@{ # JDownloader 2
		Type="Install";
		Page="https://jdownloader.org/jdownloader2";
		Down=""
	},
	@{ # Twitch Downloader CLI
		Type="Tools";
		Page="https://github.com/lay295/TwitchDownloader/releases";
		Down="https://github.com/lay295/TwitchDownloader/releases/latest/download/TwitchDownloaderCLI-Linux-x64.zip"
	},
	@{ # YouTube DL
		Type="Tools";
		Page="https://github.com/ytdl-org/youtube-dl/releases";
		Down="https://github.com/ytdl-org/youtube-dl/releases/latest/download/youtube-dl.exe"
	},
	@{ # Open Broadcaster Software
		Type="Install";
		Page="https://obsproject.com/download";
		Down=""
	},
	@{ # qBittorrent
		Type="Install";
		Page="https://www.qbittorrent.org/download.php";
		Down=""
	},
	@{ # Voicemeeter
		Type="Install";
		Page="https://vb-audio.com/Voicemeeter/potato.htm";
		Down=""
	},
	@{ # Virtual Audio Cable
		Type="Install";
		Page="https://vb-audio.com/Cable/index.htm";
		Down=""
	},
	@{ # DesktopOK
		Type="Install";
		Page="https://www.softwareok.com/?Download=DesktopOK";
		Down="https://www.softwareok.com/Download/DesktopOK_Installer_x64.zip"
	},
################################################################################
# Performance / Benchmarking / Monitoring
################################################################################
	@{ # HWInfo
		Type="Tools";
		Page="https://www.hwinfo.com/download/";
		Down=""
	},
	@{ # CPU-Z
		Type="Tools";
		Page="https://www.cpuid.com/softwares/cpu-z.html";
		Down=""
	},
	@{ # GPU-Z
		Type="Tools";
		Page="https://www.techpowerup.com/download/techpowerup-gpu-z/";
		Down=""
	},
	@{ # Crystal Disk Info
		Type="Tools";
		Page="https://crystalmark.info/en/download/";
		Down="" # Redirects to latest, but its an html page with a redirect in it. So we cant follow: https://crystalmark.info/redirect.php?product=CrystalDiskInfo
	},
################################################################################
# Dev Tools 
################################################################################
	@{ # Visual Studio
		Type="Install";
		Page="https://visualstudio.microsoft.com/";
		Down="https://c2rsetup.officeapps.live.com/c2r/downloadVS.aspx?sku=community&channel=Release"
	},
	#@{ # Visual Studio Code
	#	Type="Install";
	#	Page="https://code.visualstudio.com/download";
	#	Down="https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
	#},
	@{ # Notepad++
		Type="Install";
		Page="https://notepad-plus-plus.org/downloads/";
		Down=""
	},
	@{ # Autoruns
		Type="Tools";
		Page="https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns";
		Down="https://download.sysinternals.com/files/Autoruns.zip"
	},
	@{ # Process Explorer
		Type="Tools";
		Page="https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer";
		Down="https://download.sysinternals.com/files/ProcessExplorer.zip"
	},
	@{ # Process Monitor
		Type="Tools";
		Page="https://learn.microsoft.com/en-us/sysinternals/downloads/procmon";
		Down="https://download.sysinternals.com/files/ProcessMonitor.zip"
	},
	@{ # Wireshark
		Type="Install";
		Page="https://www.wireshark.org/download.html";
		Down="https://www.wireshark.org/download/win64/Wireshark-win64-latest.exe"
	},
	@{ # SQLite Browser
		Type="Tools";
		Page="https://sqlitebrowser.org/dl/";
		Down="https://nightlies.sqlitebrowser.org/latest/DB.Browser.for.SQLite-win64.zip"
	},
	@{ # Python
		Type="Install";
		Page="https://www.python.org/downloads/";
		Down=""
	},
	@{ # Conan (install w/ pip, standalone bundles a copy of python)
		Type="Install";
		Page="https://conan.io/downloads.html";
		Down=""
	},
	@{ # CMake
		Type="Install";
		Page="https://cmake.org/download/";
		Down=""
	}
)

# Test case
#$programs = @(
#	@{ # Audacity (pre telemetry = 3.0.2)
#		Type="Install";
#		Page="https://github.com/audacity/audacity/releases/tag/Audacity-3.0.2";
#		Down="https://github.com/audacity/audacity/releases/download/Audacity-3.0.2/audacity-win-3.0.2.exe"
#	}
#)

foreach ($prog in $programs) {
	if ($prog.Down) {
		# Handled below
	} elseif ($prog.Page) {
		Start $prog.Page
	} else {
		"Invalid (empty) program entry"
	}
}

foreach ($prog in $programs) {
	if ($prog.Down) {
		Download -Dir "./downloads/${prog.Type}" -Url $prog.Down
	}
}

"Done downloading programs."
Stop-Transcript