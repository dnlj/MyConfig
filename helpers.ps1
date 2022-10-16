# By default powershell only provides HKCU and HKLM
if (!(Get-PSDrive | where Name -eq HKCR)) {
	$null = New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
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
		[Parameter(Mandatory)][string] $Path,
		[Parameter(Mandatory)][string] $Name,
		[Parameter(Mandatory)] $Type,
		[Parameter(Mandatory)] $Value
	)
	
	$full = Join-Path $Path $Name
	if (!($found = Get-Item $Path -ErrorAction SilentlyContinue)) {
		$found = New-Item -Force -Path $Path
	}
	
	if ($VerbosePreference -ne "SilentlyContinue") {
		$oldValue = $found.GetValue($Name)
		if ($oldValue -ne $null) {
			$oldType = $found.GetValueKind($Name)
			if ($oldValue -cne $Value) {
				"Setting registry `"$full`" = ${Type}:`"$Value`" (was: ${oldType}:`"$oldValue`")."
			}
		} else {
			"Adding new registry entry `"$full`" = ($Type):`"$Value`"."
		}
	}
	
	Set-ItemProperty -Force -Path $Path -Name $Name -Type $Type -Value $Value
}

function Remove-Registry {
	param (
		[Parameter(Mandatory)][string] $Path,
		[Parameter(Mandatory)][string] $Name
	)
	
	if (!($found = Get-ItemProperty $Path $Name -ErrorAction SilentlyContinue)) {
		return
	}
	
	if ($VerbosePreference -ne "SilentlyContinue") {
		$Value = $found.GetValue($Name)
		if ($Value -eq $null) { return }
		
		$Type = $found.GetValueKind($Name)
		"Removing registry entry `"$full`" = ($Type):`"$Value`"."
	}
	Remove-ItemProperty -Force -Path $Path -Name $Name
}