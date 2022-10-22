param (
	[Parameter(Mandatory)]
	[ValidateSet("Seq", "Rand")]
	[string] $Order,
	
	[Parameter(Mandatory)]
	[string] $Root
)

Function Set-LockScreenImage {
	param (
		[Parameter(Mandatory)][string] $Path
	)
	
	###############################################################################################
	# BEGIN (https://superuser.com/a/1342416)
	[Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime] | Out-Null
	[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
	Add-Type -AssemblyName System.Runtime.WindowsRuntime
	
	Function Await($WinRtTask, $ResultType) {
		$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
		$asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
		$netTask = $asTask.Invoke($null, @($WinRtTask))
		$netTask.Wait(-1) | Out-Null
		$netTask.Result
	}
	
	Function AwaitAction($WinRtAction) {
		$asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | ? { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and !$_.IsGenericMethod })[0]
		$netTask = $asTask.Invoke($null, @($WinRtAction))
		$netTask.Wait(-1) | Out-Null
	}

	$image = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($Path)) ([Windows.Storage.StorageFile])
	AwaitAction ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($image))
	# END (https://superuser.com/a/1342416)
	###############################################################################################
}

# Couldn't find supported types. Just guessing supported types based on GDI+ bitmap types.
$types = @('.png', '.jpg', '.jpeg', '.bmp', '.gif', '.tiff', '.tif')
$last = (Get-ItemProperty -Path "HKCU:\Software\.dnlj" -ErrorAction SilentlyContinue).LastLockScreenImage
$items = Get-ChildItem -Path $Root -File -Recurse | Where Extension -In $types | %{$_.FullName}

if ($Order -eq "Seq") {
	$img = $items[($items.indexOf($last) + 1) % $items.Length]
} elseif ($Order -eq "Rand") {
	$img = $items[0];
	while ($items.Length -gt 1) {
		$img = $items | Get-Random
		if ($img -eq $last) { continue; }
		break;
	}
}

$null = New-Item -Path "HKCU:\Software\.dnlj" -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\.dnlj" -Name "LastLockScreenImage" -Type String -Value $img
Set-LockScreenImage $img
