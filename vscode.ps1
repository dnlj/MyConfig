#Requires -RunAsAdministrator
. ./helpers.ps1


################################################################################################################################################################
# User Config
################################################################################################################################################################
$ProfPath = Join-Path $Env:APPDATA "code\User"
$null = New-Item -Force -ItemType "directory" -Path $ProfPath
Copy-Item "vscode/github-markdown.css" -Destination (Join-Path $ProfPath "github-markdown.css")
Copy-Item "vscode/keybindings.json" -Destination (Join-Path $ProfPath "keybindings.json")
Copy-Item "vscode/settings.json" -Destination (Join-Path $ProfPath "settings.json")


################################################################################################################################################################
# Install
################################################################################################################################################################
try {
	 # Surely there is a better way to do this
	 # ErrorAction SilentlyContinue doesnt work for some reason.
	 # Doing `where name -eq code` doesnt work because name != positional (for example code.bat, code.cmd, code.exe, etc.)
	Get-Command code -ErrorAction Stop | Out-Null
	"VSCode already installed."
} catch {
	if (!(Get-ChildItem -ErrorAction SilentlyContinue -Path "./downloads/VSCodeSetup*.exe")) {
		Download -Dir "./downloads" "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
	}
	"Running VSCode installer..."
	
	# For list of tasks see: https://github.com/microsoft/vscode/blob/main/build/win32/code.iss
	# Inno options: https://jrsoftware.org/ishelp/index.php?topic=setupcmdline
	& "./downloads/VSCodeSetup*.exe" "/verysilent" '/tasks="addtopath"' | Out-Null
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}


################################################################################################################################################################
# Extensions
################################################################################################################################################################
"Installing VSCode extensions..."

# Generate with: code --list-extensions
$Extensions = @(
	"bierner.github-markdown-preview",
	"bierner.markdown-checkbox",
	"bierner.markdown-emoji",
	"bierner.markdown-footnotes",
	"bierner.markdown-mermaid",
	"bierner.markdown-preview-github-styles",
	"bierner.markdown-yaml-preamble",
	"editorconfig.editorconfig",
	#"kamikillerto.vscode-colorize", # Adds color backgrounds to #hex colors. Useful for theme dev.
	"mrmlnc.vscode-scss",
	"ms-python.debugpy",
	"ms-python.python",
	"ms-python.vscode-pylance",
	#"platformio.platformio-ide", # PlatformIO (arduino/teensy/microcontroller dev)
	"redhat.vscode-xml",
	"ritwickdey.liveserver",
	"stkb.rewrap",
	"streetsidesoftware.code-spell-checker",
	"vue.volar" # Vue support
	#"zero-plusplus.vscode-autohotkey-debug",
)

foreach ($Ext in $Extensions) {
	# If we dont have --force it opens a new vscode instance for every command
	& "code" "--force" "--install-extension" $Ext
}