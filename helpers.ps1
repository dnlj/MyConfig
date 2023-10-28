# By default powershell only provides HKCU and HKLM
if (!(Get-PSDrive | where Name -eq HKCR)) {
	$null = New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
}

# TODO: Every single action in here should be logging everything it does. Probably add a `Log -Loud ...` option to print in addition to logging to file.

function Log {
	param (
		[Parameter(Mandatory)][string] $Msg,
		[string] $Path='C:\.dnlj\logs',
		[string] $File
	)
	
	if (!$File) {
		$File = "default.$(Get-Date -F yyyyMMddTHH).log"
	}
	
	if ($Path) {
		$File = Join-Path $Path $File
	}
	
	if (!(Test-Path $File)) {
		$null = New-Item -Force -Path $File
	}
	
	$Msg | Out-File -Append -Encoding ascii -FilePath $File
}

function Download {
	param (
		[Parameter(Mandatory)][string] $Url,
		[Parameter(Mandatory)][string] $Dir
	)
	
	# Do the downloading
	try {
		if (!(Test-Path $Dir)) {
			[void](New-Item -ItemType "Directory" -Path $Dir)
		}
		
		$temp = "$Dir/.dnlj." + [System.IO.Path]::GetRandomFileName() + ".temp"
		
		# TODO: Invoke-WebRequest has very bad performance (slow download) compared to other download methods
		# TODO: Invoke-WebRequest Holds the whole file in memory. Bad for large files.
		$oldProgressPreference = $ProgressPreference
		$ProgressPreference = 'SilentlyContinue' # Greatly improves perfomance of Invoke-WebRequest
		"Downloading $Url"
		$dl = Invoke-WebRequest -PassThru -Uri $Url -OutFile $temp
		$ProgressPreference = $oldProgressPreference
	} catch {
		"Unable to download $Url"
		throw $_.Exception # TODO: we want this to catch specific things, not everything. Remove once we figure out what the error we were catching was.
		return;
	}
	
	# Try to use HTTP filename
	$name = $dl.Headers["Content-Disposition"]
	if ($name) {
		$name = [Net.Mime.ContentDisposition]::new($name).Filename
	}
	
	# Try to parse URI if 
	if (!$name) {
		$name = $dl.BaseResponse.ResponseUri -split '/' | Select -Last 1
	}
	
	# Rename temp file
	if ($name) {
		if (!(Test-Path "$Dir/$name")) {
			Rename-Item $temp $name
		} else {
			"Unable to rename `"$temp`" to `"$name`""
		}
	} else {
		"Unable to get file name for `"$temp`" @ `"$Url`""
	}
}

function Disable-TasksLike {
	param ([Parameter(Mandatory)] $Tasks)
	
	$TaskList = Get-ScheduledTask | Where State -NE "Disabled"
	foreach ($task in $Tasks) {
		$found = $TaskList | Where URI -Like $task
		
		foreach ($f in $found) {
			"Disabling task `"$($f.TaskName)`" ($($f.State))"
			$f | Stop-ScheduledTask
			$null = $f | Disable-ScheduledTask
		}
	}
}

function Set-RegistryOwner {
	param ([Parameter(Mandatory)] $Path)
	
	# Escalate current process's privilege
	# https://stackoverflow.com/a/35843420
	# https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants
    # get SeTakeOwnership, SeBackup and SeRestore privileges before executes next lines, script needs Admin privilege
    $import = '[DllImport("ntdll.dll")] public static extern int RtlAdjustPrivilege(ulong a, bool b, bool c, ref bool d);'
    $ntdll = Add-Type -Member $import -Name NtDll -PassThru
    $privileges = @{ SeTakeOwnership = 9; SeBackup =  17; SeRestore = 18 }
    foreach ($i in $privileges.Values) {
        $null = $ntdll::RtlAdjustPrivilege($i, 1, 0, [ref]0)
    }
	
	# Really we should probably give ownership to system then add a rule for admins (thats how most of the registry is)
	# https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
	# $system = [Security.Principal.SecurityIdentifier]("S-1-5-18")
	$admins = [Security.Principal.SecurityIdentifier]("S-1-5-32-544")
	$items = Get-ChildItem -Recurse -Path $Path
	foreach ($item in $items) {
		# Reopen key with the "TakeOwnership" flag.
		$item = $item.OpenSubKey("", "ReadWriteSubTree", "TakeOwnership")
		
		# Take ownership.
		$acl = New-Object Security.AccessControl.RegistrySecurity
		$acl.SetOwner($admins)
		$item.SetAccessControl($acl)
		
		# Now that we own the key we can change premissions.
		$acl.SetAccessRuleProtection($false, $false)
		$item.SetAccessControl($acl)
	}
}

function Set-Registry {
	param (
		[Parameter(Mandatory, ParameterSetName='Path')][string] $Path,
		[Parameter(Mandatory, ParameterSetName='LiteralPath')][string] $LiteralPath,
		[Parameter(Mandatory)][string] $Name,
		[Parameter(Mandatory)] $Type,
		[Parameter(Mandatory)] $Value
	)
	
	
	if ($Path) {
		$full = Join-Path $Path $Name
		if (!($found = Get-Item -Path $Path -ErrorAction SilentlyContinue)) {
			$found = New-Item -Force -Path $Path
		}
	} else {
		$full = Join-Path $LiteralPath $Name
		if (!($found = Get-Item -LiteralPath $LiteralPath -ErrorAction SilentlyContinue)) {
			$found = New-Item -Force -Path $LiteralPath
		}
	}
	
	$oldValue = $found.GetValue($Name)
	if ($oldValue -ne $null) {
		$oldType = $found.GetValueKind($Name)
		if ($oldValue -cne $Value) {
			Log "Setting registry `"$full`" = ${Type}:`"$Value`" (was: ${oldType}:`"$oldValue`")."
		}
	} else {
		Log "Adding new registry entry `"$full`" = ($Type):`"$Value`"."
	}
	
	if ($Path) {
		Set-ItemProperty -Force -Path $Path -Name $Name -Type $Type -Value $Value
	} else {
		Set-ItemProperty -Force -LiteralPath $LiteralPath -Name $Name -Type $Type -Value $Value
	}
}

function Remove-Registry {
	param (
		[Parameter(Mandatory)][string] $Path,
		[Parameter(Mandatory)][string] $Name
	)
	
	if (!($found = Get-Item $Path -ErrorAction SilentlyContinue)) {
		return
	}
	
	$Value = $found.GetValue($Name)
	if ($Value -eq $null) { return }
	
	$Type = $found.GetValueKind($Name)
	$Full = Join-Path $Path $Name
	Log "Removing registry entry `"$Full`" = ($Type):`"$Value`"."
	
	Remove-ItemProperty -Force -Path $Path -Name $Name
}

function Remove-RegistryKey {
	param (
		[Parameter(Mandatory)][string] $Path
	)
	
	if (!($found = Get-Item -Path $Path -ErrorAction SilentlyContinue)) {
		return
	}
	
	Log "Removing registry key `"$Path`""
	Remove-Item -Recurse -Force $Path
}

function New-Shortcut {
	param (
		[Parameter(Mandatory)][string] $Path,
		[Parameter(Mandatory)][string] $Target,
		[Parameter()][string] $Args
	)
	
	$null = New-Item -ItemType Directory -Force -Path (Split-Path $Path)
	
	# For more arguments: https://learn.microsoft.com/en-us/troubleshoot/windows-client/admin-development/create-desktop-shortcut-with-wsh
	$WshShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($Path)
	$Shortcut.TargetPath = $Target
	$Shortcut.Arguments = $Args
	$Shortcut.Save()
}

function Remove-AppxPackageThorough {
	param (
		[Parameter(Mandatory)][string] $Name
	)
	# Deprovision provisioned apps
	# This must be done before the uninstall step below
	$found = Get-AppxProvisionedPackage -Online | Where DisplayName -Like $Name
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
	$found = Get-AppxPackage -AllUsers $Name
	foreach ($pack in $found) {
		try {
			$pack | Remove-AppxPackage -AllUsers
			"Removed app package $($pack.Name) ($($pack.Version))."
		} catch [System.Runtime.InteropServices.COMException], [System.UnauthorizedAccessException] {
			"Unable to remove app package $($pack.Name) ($($pack.Version))."
		}
	}
}
