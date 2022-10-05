#Requires -RunAsAdministrator
. .\helpers.ps1

# If you use a shortcut to a console then the `.lnk` file itself may have color information embedded in it.
# You can control by specific file path and by window title
# https://web.archive.org/web/20221003084823/https://devblogs.microsoft.com/commandline/understanding-windows-console-host-settings/
# From the article:
#################################################################################################################################################
# Where a Console’s settings are loaded-from and/or persisted-to is decided upon based upon the following hierarchy:
# * Hardcoded settings in conhostv2.dll
# * User’s configured Console defaults, stored as values in ‘HKCU\Console’
# * Per-Console-application registry settings, stored as sub-keys of ‘HKCU\Console\‘ using one of two sub-key names:
#   - Console application path (replacing ‘\’ with ‘_’)
#   - Console title
# * Windows shortcut (.lnk) files
#################################################################################################################################################

# Mintty (Git for Windows bash)
&{
	Copy -Path "./colors/dnlj.onedark.minttyrc" -Destination (New-Item -Force -ItemType Directory -Path "$env:USERPROFILE\.mintty\themes")
	
	$rcpath = "$env:USERPROFILE\.minttyrc"
	if ($content = Get-Content -Raw -Path $rcpath -ErrorAction SilentlyContinue) {
		$reg = "(\s*ThemeFile\s*=)(.*)"
		$new = ($content -replace $reg, "`$1dnlj.onedark.minttyrc")
		
		if ($new -notmatch $reg) {
			$new = "ThemeFile=dnlj.onedark.minttyrc`n" + $new
		}
		
		$new | Set-Content -NoNewline $rcpath
	} else {
		"ThemeFile=dnlj.onedark.minttyrc`n" >> $rcpath
	}
	
}

# CMD, Powershell, WSL
regedit /s "./colors/dnlj.onedark.reg"

# Disable any overrides
Get-ChildItem -Path "HKCU:\Console" `
	| Where {!$_.PSChildName.StartsWith(".dnlj.disabled.")} `
	| Rename-Item -NewName {".dnlj.disabled.$($_.PSChildName)"}