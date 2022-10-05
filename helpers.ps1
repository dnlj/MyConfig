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
