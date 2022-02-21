#Disable Hibernate
powercfg.exe -h off

# Disable automatic pagefile management
$cs = gwmi Win32_ComputerSystem
if ($cs.AutomaticManagedPagefile) {
    $cs.AutomaticManagedPagefile = $False
    $cs.Put()
}
# Disable a *single* pagefile if any
$pg = gwmi win32_pagefilesetting
if ($pg) {
    $pg.Delete()
}

# Uninstall OneDrive
Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process
C:\Windows\SysWOW64\OneDriveSetup.exe /uninstall

#Uninstall uselsee Windows optional features
#Disable-WindowsOptionalFeature -Online -NoRestart -FeatureName WindowsMediaPlayer
#Disable-WindowsOptionalFeature –Online -NoRestart -FeatureName Internet-Explorer-Optional-amd64
#Disable-WindowsOptionalFeature –Online -NoRestart -FeatureName Containers
#Disable-WindowsOptionalFeature –Online -NoRestart -FeatureName SearchEngine-Client-Package

<# Remove Windows AppxPackages
Get-AppxPackage | Where-Object {$_.Name -like "*Skype*"} | Select Name
#>

$crap_app_clues = "3dbuilder",
  "3dviewer",
  "bingfinance",
  "bingnews",
  "bingsports",
  "bingweather",
  "CandyCrushFriends",
  "cortana",
  "dtsheadphonex",
  "FarmHeroesSaga",
  "getHelp",
  "getstarted",
  "messaging",
  "microsoft.people",
  "officehub",
  "oneconnect",
  "onenote",
  "Paint",
  "photos",
  "print3d",
  "MicrosoftTeams",
  "Spotify",
  "skypeapp",
  "solitairecollection",
  "soundrecorder",
  "officehub",
  "windowsalarms",
  "windowscalculator",
  "windowscamera",
  "windowscommunicationapps",
  "WindowsFeedbackHub",
  "windowsmaps",
  "windowsphone",
  "yourphone",
  "XING",
  "zunemusic",
  "zunevideo"

Function RemoveApp($crap_app) {
  $name = $crap_app.Name
  Write-Host "Deleting $name" -ForegroundColor Green
  Remove-AppxPackage -Package $crap_app -AllUsers
}

Function GetApp($clue) {
  Get-AppxPackage -AllUsers -Name *$clue*
}


Function RemoveAllApps {
  foreach($crap_clue in $crap_app_clues) {
    $crap_app = GetApp($crap_clue)
    if ($crap_app -ne $null) {
        RemoveApp($crap_app)
      }
      else {
      Write-Host "Couldn't find '$crap_clue'" -ForegroundColor Yellow
    }
    } 
  }

RemoveAllApps

<#
Disable unnecessary services
#>

$ServiceName = @(
#Biometric Services
"WbioSrvc",
#Windows Search (sucks anyway)
"WSearch",
#Windows Insider Service
"wisvc",
#Windows Error Reporting
"WerSvc"
#RemoteRegistry
"RemoteRegistry",
#Touch Keyboard and Handwriting Panel Service
"TabletInputService",
#Windows Fax
"Fax",
#Connected User Experiences and Telemetry
"DiagTrack",
#Downloaded Maps Manager
"MapsBroker"
)
foreach($Service in $ServiceName ) {Set-Service $Service -StartupType Disable; Stop-Service $Service}

<#
Configure preferable Windows settings
#>

function create_registry_key {

IF(!(Test-Path $registryPath))
  {
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Name $name -Path $registrypath -Force -PropertyType DWORD -Value $value | Out-Null}
 ELSE {
    New-ItemProperty -Name $name -Path $registrypath -Force -PropertyType DWORD -Value $value | Out-Null | Out-Null}
}

function verify_registry_key {
if ((Get-ItemProperty $registryPath -name $Name | select -exp $Name) -eq $value ) {
    Write-Host $registryPath\ -ForegroundColor Green -BackgroundColor Black -NoNewline; Write-Host $Name -ForegroundColor Cyan -BackgroundColor Black -NoNewline; Write-Host " was set to value " -ForegroundColor White -BackgroundColor Black -NoNewline; Write-Host $value -ForegroundColor Cyan -BackgroundColor Black  }
    else {Write-Host $registryPath\$Name -ForegroundColor Magenta -BackgroundColor Black -NoNewline; Write-Host "was not set to value " -ForegroundColor White -BackgroundColor Black -NoNewline ;Write-Host $value -ForegroundColor Cyan -BackgroundColor Black}
 }

#Disable Windows 10 fast boot
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$Name = "HiberbootEnabled"
$value = "0"
create_registry_key
verify_registry_key

#Remove Windows desktop background image
$registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers"
$Name = "BackgroundType"
$value = "1"
create_registry_key
verify_registry_key

$registryPath = "HKCU:\Control Panel\Desktop"
$Name = "WallPaper"
$value = ""
create_registry_key
verify_registry_key

#Small Desktop icons
$registryPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
$Name = "IconSize"
$value = "36"
create_registry_key
verify_registry_key

#Disable Windows Hello login (Enables the option to allow the automatic login without a password to Windows in netplwiz. Useful if you have a Bitlocker password anyway)
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device"
$Name = "DevicePasswordLessBuildVersion"
$value = "0"
create_registry_key
verify_registry_key

#Disable GameDVR and Game Bar
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
$Name = "GameDVR_Enabled"
$value = "0"
create_registry_key
verify_registry_key

#Deactivate sound setting communication 'Reduce the volume of other sounds by 80%'
$registryPath = "HKCU:\Software\Microsoft\Multimedia\Audio"
$Name = "UserDuckingPreference"
$value = "3"
create_registry_key
verify_registry_key

#Disable Windows Insider Error Message Reporting
$registryPath = "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility"
$Name = "DiagnosticErrorText"
$value = "0"
create_registry_key
verify_registry_key

#Disable Windows Insider Error Message Reporting
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "LaunchTo"
$value = "1"
create_registry_key
verify_registry_key

#Disable Windows Web Search
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
$Name = "BingSearchEnabled"
$value = "0"
create_registry_key
verify_registry_key

$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
$Name = "CortanaConsent"
$value = "0"
create_registry_key
verify_registry_key

#Disable Windows Logon Background Image
$registryPath = "HKLM:\Software\Policies\Microsoft\Windows\System"
$Name = "DisableLogonBackgroundImage"
$value = "1"
create_registry_key
verify_registry_key

<#Hide OneDrive from file explorer
$registryPath = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
$Name = "System.IsPinnedToNameSpaceTree"
$value = "0"
create_registry_key
verify_registry_key

$registryPath = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
$Name = "System.IsPinnedToNameSpaceTree"
$value = "0"
create_registry_key
verify_registry_key
#>

#Add lockscreen timeout settings to power saving options
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\7516b95f-f776-4464-8c53-06167f40cc99\8EC4B3A5-6868-48c2-BE75-4F3044BE88A7"
$Name = "Attributes"
$value = "2"
create_registry_key
verify_registry_key

#Disable enhanced pointer precision
$registryPath = "HKCU:\Control Panel\Mouse"
$Name = "MouseSpeed"
$value = "0"
create_registry_key
verify_registry_key

$registryPath = "HKCU:\Control Panel\Mouse"
$Name = "MouseThreshold1"
$value = "0"
create_registry_key
verify_registry_key

$registryPath = "HKCU:\Control Panel\Mouse"
$Name = "MouseThreshold2"
$value = "0"
create_registry_key
verify_registry_key

#Enable dark mode
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$Name = "AppsUseLightTheme"
$value = "0"
create_registry_key
verify_registry_key

#Explorer tweaks
# Show all taskbar icons
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
$Name = "EnableAutoTray"
$value = "0"
create_registry_key
verify_registry_key

#Choose "Show hidden files, folders, and drives"
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "Hidden"
$value = "1"
create_registry_key
verify_registry_key

#Uncheck "Hide extensions for known file types"
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "HideFileExt"
$value = "0"
create_registry_key
verify_registry_key

#Uncheck "Hide protected operating system files (Recommended)"
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "ShowSuperHidden"
$value = "0"
create_registry_key
verify_registry_key

#ShowCortanaButton
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "ShowCortanaButton"
$value = "0"
create_registry_key
verify_registry_key

#Disable task view button
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "ShowTaskViewButton"
$value = "0"
create_registry_key
verify_registry_key

#Small taskbar icons
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "TaskbarSmallIcons"
$value = "1"
create_registry_key
verify_registry_key

#disable background apps
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
$Name = "GlobalUserDisabled"
$value = "1"
create_registry_key
verify_registry_key

# Explorer default to details view
Remove-Item -LiteralPath "HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags" -Recurse -force -ErrorAction SilentlyContinue;
Remove-Item -LiteralPath "HKCU:\Software\Microsoft\Windows\ShellNoRoam\BagMRU" -Recurse -force -ErrorAction SilentlyContinue;
Remove-Item -LiteralPath "HKCU:\Software\Microsoft\Windows\Shell\Bags" -Recurse -force -ErrorAction SilentlyContinue;
Remove-Item -LiteralPath "HKCU:\Software\Microsoft\Windows\Shell\BagMRU" -Recurse -force -ErrorAction SilentlyContinue;
if((Test-Path -LiteralPath "HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell") -ne $true) {  New-Item "HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell" -force -ea SilentlyContinue | Out-Null };
if((Test-Path -LiteralPath "HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell") -ne $true) {  New-Item "HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" -force -ea SilentlyContinue | Out-Null };
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell' -Name 'WFlags' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell' -Name 'Status' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell' -Name 'Mode' -Value 4 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell' -Name 'vid' -Value '{137E7700-3573-11CF-AE69-08002B2E1262}' -PropertyType String -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' -Name 'WFlags' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' -Name 'Status' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' -Name 'Mode' -Value 4 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' -Name 'vid' -Value '{137E7700-3573-11CF-AE69-08002B2E1262}' -PropertyType String -Force -ea SilentlyContinue | Out-Null;

#Enable old Windows Photoviewer
if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll") -ne $true) {  New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll" -force -ea SilentlyContinue | Out-Null };
if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell") -ne $true) {  New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell" -force -ea SilentlyContinue | Out-Null };
if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open") -ne $true) {  New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open" -force -ea SilentlyContinue | Out-Null };
if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\command") -ne $true) {  New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\command" -force -ea SilentlyContinue | Out-Null };
if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\DropTarget") -ne $true) {  New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\DropTarget" -force -ea SilentlyContinue | Out-Null };
if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print") -ne $true) {  New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print" -force -ea SilentlyContinue | Out-Null };
if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\command") -ne $true) {  New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\command" -force -ea SilentlyContinue | Out-Null };
if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\DropTarget") -ne $true) {  New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\DropTarget" -force -ea SilentlyContinue | Out-Null };
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open' -Name 'MuiVerb' -Value '@photoviewer.dll,-3043' -PropertyType String -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\command' -Name '(default)' -Value '%SystemRoot%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1' -PropertyType ExpandString -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\DropTarget' -Name 'Clsid' -Value '{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}' -PropertyType String -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print' -Name 'NeverDefault' -Value '' -PropertyType String -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\command' -Name '(default)' -Value '%SystemRoot%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1' -PropertyType ExpandString -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\DropTarget' -Name 'Clsid' -Value '{60fd46de-f830-4894-a628-6fa81bc0190d}' -PropertyType String -Force -ea SilentlyContinue | Out-Null;


#Disable unnecessary log files and writes to SSD
$CheckPath = 'C:\Users\shuriken\AppData\LocalLow\Deo VR'
if((Test-Path -LiteralPath $CheckPath) -ne $true) {  New-Item -Path $CheckPath -ItemType File -force -ea SilentlyContinue | Out-Null; Write-Host "$CheckPath" -BackgroundColor Black -ForegroundColor Green -NoNewline; Write-Host " was created." -ForegroundColor White -BackgroundColor Black -NoNewline } 
else {Write-Host "$CheckPath" -BackgroundColor Black -ForegroundColor Magenta -NoNewline;Write-Host " already exists." -ForegroundColor White -BackgroundColor Black -NoNewline }
$CheckPath = 'C:\Users\shuriken\AppData\LocalLow\DeoVR'
if((Test-Path -LiteralPath $CheckPath) -ne $true) {  New-Item -Path $CheckPath -ItemType File -force -ea SilentlyContinue | Out-Null; Write-Host "$CheckPath" -BackgroundColor Black -ForegroundColor Green -NoNewline; Write-Host " was created." -ForegroundColor White -BackgroundColor Black -NoNewline } 
else {Write-Host "$CheckPath" -BackgroundColor Black -ForegroundColor Magenta -NoNewline;Write-Host " already exists." -ForegroundColor White -BackgroundColor Black -NoNewline }

#Install winget
Start-Process "https://www.microsoft.com/en-us/p/app-installer/9nblggh4nns1"
#[void][System.Console]::ReadKey($true)

#Install Software
 $confirmation = $(Write-Host "Do you want to install additional software packages?" -ForegroundColor White -BackgroundColor Black -NoNewLine) + $(Write-Host " (y/n): " -ForegroundColor Cyan -BackgroundColor Black -NoNewLine; Read-Host)
if ($confirmation -eq 'y') {
#winget.exe install Nvidia.GeForceExperience
winget.exe install Notepad++
winget.exe install Signal
winget.exe install Firefox
winget.exe install Google.Chrome
winget.exe install 7-Zip
#winget.exe install Everything
#winget.exe install git
winget.exe install Logitech.LGH
winget.exe install Mumble
winget.exe install OBSProject.OBSStudio
winget.exe install protonvpn
winget.exe install Teamspeak
#winget.exe install Intel.IntelDriverAndSupportAssistant
winget.exe install VideoLAN.VLC
winget.exe install Twilio.Authy
#winget.exe install CPUID.CPU-Z
winget.exe install Discord.Discord
#winget.exe install Microsoft.PowerToys
}
