<#
.SYNOPSIS
    Configure Windows 11 settings to my likings.
.DESCRIPTION
     My attempt to configure Windows 11 to my liking. Keep in mind that not every setting may be right for you.
     Feel free to use, copy, fork, modify, merge, publish or distribute the script and/or parts of the script.
     Only tested on Windows 11. If you got suggestions, let me know.
.PARAMETER Param1
    No parameters yet.
.EXAMPLE
    Example syntax for running the script or function
    PS C:\> windows.ps1
.LINK
    https://github.com/nopantsfriday/restore_windows_settings
.NOTES
    Filename: restore_windows_settings.ps1
    Author: https://github.com/nopantsfriday
    Modified date: 2023-02-04
    Version 1.0.1 - Initial release
#>
Clear-Host
<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Disable Hibernate
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Disable Hibernate" -ForegroundColor Cyan
powercfg.exe -h off
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
$Name = "HibernateEnabled"
$value = "0"
$registry_type = "DWORD"
verify_registry_key

<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Enable File and Printer Sharing (Echo Request - ICMPv4-In) to allow pinging the host
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
# Define the firewall rule name
$firewallRuleName = "File and Printer Sharing (Echo Request - ICMPv4-In)"

# Check if the firewall rule exists
$existingRule = Get-NetFirewallRule | Where-Object { $_.DisplayName -eq $firewallRuleName }

if ($existingRule -eq $null) {
    Write-Host "Firewall rule not found: $firewallRuleName"
} else {
    # Enable the firewall rule
    Enable-NetFirewallRule -DisplayName $firewallRuleName
    Write-Host "Firewall rule '$firewallRuleName' has been enabled."
}

<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Enable Ultimate Performance Power Plan
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Enable Ultimate Performance Power Plan" -ForegroundColor Cyan
$powercfg = (powercfg.exe -l) |  Out-String
if ($powercfg -like "*Ultimate Performance*") {
  $p = Get-CimInstance -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName = 'Ultimate Performance'"
  powercfg /setactive ([string]$p.InstanceID).Replace("Microsoft:PowerPlan\{", "").Replace("}", "")
  Write-Host "'Ultimate  Performance' power plan selected" -ForegroundColor Green
}
if ($powercfg -notlike "*Ultimate Performance*") {
  #powercfg -restoredefaultschemes
  powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
  $p = Get-CimInstance -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName = 'Ultimate Performance'"
  powercfg /setactive ([string]$p.InstanceID).Replace("Microsoft:PowerPlan\{", "").Replace("}", "")
  Write-Host "'Ultimate  Performance' power plan created and selected" -ForegroundColor Green
}
<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Uninstall OneDrive
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Remove OneDrive" -ForegroundColor Cyan

try {
  if (Test-Path "$env:systemroot\System32\OneDriveSetup.exe") {
    & "$env:systemroot\System32\OneDriveSetup.exe" /uninstall
  }
  if (Test-Path "$env:systemroot\SysWOW64\OneDriveSetup.exe") {
    & "$env:systemroot\SysWOW64\OneDriveSetup.exe" /uninstall
  }
} catch {
  Write-Host "Error: $_" -ForegroundColor Red
}

try {
  if ((Get-ChildItem "$env:userprofile\OneDrive" -Recurse | Measure-Object).Count -eq 0) {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:userprofile\OneDrive"
  }
} catch {
  Write-Host "Error: $_" -ForegroundColor Red
}
<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Uninstall Microsoft Teams
# Source: https://lazyadmin.nl/powershell/microsoft-teams-uninstall-reinstall-and-cleanup-guide-scripts/
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Remove Microsoft Teams Machine-wide Installer" -ForegroundColor Cyan
$Teams_Machine_WideInstaller = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Teams Machine-Wide Installer" }
if ($Teams_Machine_WideInstaller) {
  Write-Host "Removing Teams Machine-wide Installer" -ForegroundColor Yellow
  $MachineWide = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Teams Machine-Wide Installer" }
  $MachineWide.Uninstall()
}
Write-Host "Remove Microsoft Teams" -ForegroundColor Cyan
#Write-Host "Teams Machine-wide Installer not found" -ForegroundColor Yellow
function unInstallTeams($path) {

  $clientInstaller = "$($path)\Update.exe"

  try {
    $process = Start-Process -FilePath "$clientInstaller" -ArgumentList "--uninstall /s" -PassThru -Wait -ErrorAction STOP

    if ($process.ExitCode -ne 0) {
      Write-Error "UnInstallation failed with exit code  $($process.ExitCode)."
    }
  }
  catch {
    Write-Error $_.Exception.Message
  }

}
#Locate installation folder
$localAppData = "$($env:LOCALAPPDATA)\Microsoft\Teams"
$programData = "$($env:ProgramData)\$($env:USERNAME)\Microsoft\Teams"


If (Test-Path "$($localAppData)\Current\Teams.exe") {
  unInstallTeams($localAppData)

}
elseif (Test-Path "$($programData)\Current\Teams.exe") {
  unInstallTeams($programData)
}
else {
  Write-Host  "Teams installation not found" -ForegroundColor Yellow
}

<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Uninstall uselsee Windows optional features
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Disable Windows Optional Features" -ForegroundColor Cyan
Disable-WindowsOptionalFeature -Online -NoRestart -FeatureName WindowsMediaPlayer | Out-Null
Disable-WindowsOptionalFeature –Online -NoRestart -FeatureName SearchEngine-Client-Package | Out-Null
<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Remove Windows AppxPackages
# Get-AppxPackage | Where-Object {$_.Name -like "*Skype*"} | Select Name
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Remove Windows Apps" -ForegroundColor Cyan
Function Get-App {
  param (
    [string]$clue
  )
  Get-AppxPackage -Name *$clue*
}

Function Remove-App {
  param (
    [System.Management.Automation.PSObject]$app
  )
  try {
    $name = $app.Name
    Write-Host "Deleting: $name" -ForegroundColor Green
    Remove-AppxPackage -Package $app -AllUsers -ErrorAction Stop
  }
  catch {
    Write-Host "Error deleting: $name $_" -ForegroundColor Red
  }
}

Function Remove-AllApps {
  param (
    [string[]]$appClues
  )
  foreach ($clue in $appClues) {
    $app = Get-App -clue $clue
    if ($app -ne $null) {
      Remove-App -app $app
    }
    else {
      Write-Host "Couldn't find: '$clue'" -ForegroundColor Yellow
    }
  } 
}

$appsToRemove = @("3dbuilder",
"3dviewer",
"bingfinance",
"bingnews",
"bingsports",
"bingweather",
"CandyCrushFriends",
"clipchamp",
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
"Microsoft.Todos",
"Spotify",
"skypeapp",
"solitairecollection",
"soundrecorder",
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
"zunevideo")

Remove-AllApps -appClues $appsToRemove


<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Disable unnecessary services
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Deactivate Windows Services" -ForegroundColor Cyan

# List of Windows services to deactivate
$ServicesToDeactivate = @(
  "RetailDemo",               # Windows Retail Demo
  "icssvc",                   # Windows Mobile Hotspot
  "PhoneSvc",                 # PhoneService
  "WbioSrvc",                 # Biometric Services
  "WSearch",                  # Windows Search (sucks anyway)
  "wisvc",                    # Windows Insider Service
  "WerSvc",                   # Windows Error Reporting
  "RemoteRegistry",           # Remote Registry
  "TabletInputService",       # Touch Keyboard and Handwriting Panel Service
  "Fax",                      # Windows Fax
  "DiagTrack",                # Connected User Experiences and Telemetry
  "MapsBroker"                # Downloaded Maps Manager
)

# Loop through each service and attempt to deactivate it
foreach ($ServiceName in $ServicesToDeactivate) {
  try {
    # Get the service, and if it exists, set its startup type to Disabled and stop it
    $Service = Get-Service -Name $ServiceName -ErrorAction Stop
    Write-Host "Deactivating service $ServiceName" -ForegroundColor Cyan
    $Service | Set-Service -StartupType Disabled -PassThru | Stop-Service -Force
  } catch {
    # Handle the case where the service does not exist
    Write-Host "$ServiceName does not exist" -ForegroundColor Yellow
  }
}

<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Setting my preferred Windows settings via registry
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Change Windows Settings" -ForegroundColor Cyan
function create_registry_key {

  if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Name $name -Path $registrypath -Force -PropertyType $registry_type -Value $value | Out-Null
  }
  else {
    New-ItemProperty -Name $name -Path $registrypath -Force -PropertyType $registry_type -Value $value | Out-Null | Out-Null
  }
}

function verify_registry_key {
  if ((Get-ItemProperty $registryPath -name $Name | Select-Object -exp $Name) -eq $value ) {
    Write-Host $registryPath\ -ForegroundColor Green -BackgroundColor Black -NoNewline; Write-Host $Name -ForegroundColor Cyan -BackgroundColor Black -NoNewline; Write-Host " was set to value " -ForegroundColor White -BackgroundColor Black -NoNewline; Write-Host $value -ForegroundColor Cyan -BackgroundColor Black  
  }
  else { Write-Host $registryPath\$Name -ForegroundColor Yellow -BackgroundColor Black -NoNewline; Write-Host "was not set to value " -ForegroundColor White -BackgroundColor Black -NoNewline ; Write-Host $value -ForegroundColor Cyan -BackgroundColor Black }
}

function Create-RegistryKey {
  param (
    [string]$registryPath,
    [string]$name,
    [string]$registryType,
    [string]$value
  )

  if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
  }
  
  New-ItemProperty -Name $name -Path $registryPath -Force -PropertyType $registryType -Value $value | Out-Null
}

function Verify-RegistryKey {
  param (
    [string]$registryPath,
    [string]$name,
    [string]$value
  )

  $keyValue = (Get-ItemProperty $registryPath -Name $name | Select-Object -ExpandProperty $name)

  if ($keyValue -eq $value) {
    Write-Host "$registryPath\$name was set to value $value" -ForegroundColor Green
  } else {
    Write-Host "$registryPath\$name was not set to value $value" -ForegroundColor Yellow
  }
}


#Disable Windows 10 fast boot
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$Name = "HiberbootEnabled"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Remove Windows desktop background image
$registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers"
$Name = "BackgroundType"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

$registryPath = "HKCU:\Control Panel\Desktop"
$Name = "WallPaper"
$value = ""
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Small Desktop icons
$registryPath = "HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop"
$Name = "IconSize"
$value = "36"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable Windows Hello login (Enables the option to allow the automatic login without a password to Windows in netplwiz. Useful if you have a Bitlocker password anyway)
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device"
$Name = "DevicePasswordLessBuildVersion"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable Windows login background image
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
$Name = "Nolockscreen"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable Windows spotlight features
$registryPath = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
$Name = "DisableWindowsSpotlightFeatures"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable GameDVR and Game Bar
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
$Name = "GameDVR_Enabled"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Deactivate sound setting communication 'Reduce the volume of other sounds by 80%'
$registryPath = "HKCU:\Software\Microsoft\Multimedia\Audio"
$Name = "UserDuckingPreference"
$value = "3"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable Windows Insider Error Message Reporting
$registryPath = "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility"
$Name = "DiagnosticErrorText"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Explorer launch to "This PC"
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "LaunchTo"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable Windows Web Search
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
$Name = "BingSearchEnabled"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
$Name = "CortanaConsent"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable Windows Logon Background Image
$registryPath = "HKLM:\Software\Policies\Microsoft\Windows\System"
$Name = "DisableLogonBackgroundImage"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Add lockscreen timeout settings to power saving options
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\7516b95f-f776-4464-8c53-06167f40cc99\8EC4B3A5-6868-48c2-BE75-4F3044BE88A7"
$Name = "Attributes"
$value = "2"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable enhanced pointer precision
$registryPath = "HKCU:\Control Panel\Mouse"
$Name = "MouseSpeed"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

$registryPath = "HKCU:\Control Panel\Mouse"
$Name = "MouseThreshold1"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

$registryPath = "HKCU:\Control Panel\Mouse"
$Name = "MouseThreshold2"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Enable dark mode
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$Name = "AppsUseLightTheme"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Explorer tweaks
# Show all taskbar icons
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
$Name = "EnableAutoTray"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Choose "Show hidden files, folders, and drives"
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "Hidden"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Uncheck "Hide extensions for known file types"
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "HideFileExt"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Uncheck "Hide protected operating system files (Recommended)"
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "ShowSuperHidden"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#ShowCortanaButton
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "ShowCortanaButton"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable task view button
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "ShowTaskViewButton"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Small taskbar icons
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "TaskbarSmallIcons"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#disable background apps
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
$Name = "GlobalUserDisabled"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Enable Windows 10 context menu
$registryPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
$Name = "(Default)"
$value = ""
$registry_type = "String"
create_registry_key
verify_registry_key

#Enable verbose status messages during Windows loading screen
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$Name = "verbosestatus"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Taskbar Alignment left
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\"
$Name = "TaskbarAl"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable adverstising id
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
$Name = "Enabled"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable websites getting access to language list
$registryPath = "HKCU:\Control Panel\International\User Profile"
$Name = "HttpAcceptLanguageOptOut"
$value = "1"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Enable GPU hardware scheduling
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
$Name = "HwSchMode"
$value = "2"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Enable GPU variable refresh rate
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
$Name = "DirectXUserGlobalSettings"
$value = "VRROptimizeEnable=1;"
$registry_type = "String"
create_registry_key
verify_registry_key

#Show accent color on title bars and windows
$registryPath = "HKCU:\Software\Microsoft\Windows\DWM"
$Name = "ColorPrevalence"
$value = "0"
$registry_type = "String"
create_registry_key
verify_registry_key

#Disable ShowRecent file in Explorer
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
$Name = "ShowRecent"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable ShowFrequent file in Explorer
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
$Name = "ShowFrequent"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Enable Nvidia Sharpening
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS"
$Name = "EnableGR535"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable animations in Windows
$registryPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
$Name = "MinAnimate"
$value = "1"
$registry_type = "String"
create_registry_key
verify_registry_key

#Disable transparancey
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$Name = "EnableTransparency"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key

#Disable sticky keys
$registryPath = "HKCU:\Control Panel\Accessibility\StickyKeys"
$Name = "Flags"
$value = "506"
$registry_type = "DWORD"
create_registry_key
verify_registry_key



<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Explorer default to details view
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Explorer default to details view" -ForegroundColor Cyan
Remove-Item -LiteralPath "HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags" -Recurse -force -ErrorAction SilentlyContinue;
Remove-Item -LiteralPath "HKCU:\Software\Microsoft\Windows\ShellNoRoam\BagMRU" -Recurse -force -ErrorAction SilentlyContinue;
Remove-Item -LiteralPath "HKCU:\Software\Microsoft\Windows\Shell\Bags" -Recurse -force -ErrorAction SilentlyContinue;
Remove-Item -LiteralPath "HKCU:\Software\Microsoft\Windows\Shell\BagMRU" -Recurse -force -ErrorAction SilentlyContinue;
if ((Test-Path -LiteralPath "HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell") -ne $true) { New-Item "HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell" -force -ea SilentlyContinue | Out-Null };
if ((Test-Path -LiteralPath "HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell") -ne $true) { New-Item "HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" -force -ea SilentlyContinue | Out-Null };
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell' -Name 'WFlags' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell' -Name 'Status' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell' -Name 'Mode' -Value 4 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\ShellNoRoam\Bags\AllFolders\Shell' -Name 'vid' -Value '{137E7700-3573-11CF-AE69-08002B2E1262}' -PropertyType String -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' -Name 'WFlags' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' -Name 'Status' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' -Name 'Mode' -Value 4 -PropertyType DWord -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell' -Name 'vid' -Value '{137E7700-3573-11CF-AE69-08002B2E1262}' -PropertyType String -Force -ea SilentlyContinue | Out-Null;

<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Enable old Windows Photoviewer
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Enable old Windows Photoviewer" -ForegroundColor Cyan
if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll") -ne $true) { New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll" -force -ea SilentlyContinue | Out-Null };
if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell") -ne $true) { New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell" -force -ea SilentlyContinue | Out-Null };
if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open") -ne $true) { New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open" -force -ea SilentlyContinue | Out-Null };
if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\command") -ne $true) { New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\command" -force -ea SilentlyContinue | Out-Null };
if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\DropTarget") -ne $true) { New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\DropTarget" -force -ea SilentlyContinue | Out-Null };
if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print") -ne $true) { New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print" -force -ea SilentlyContinue | Out-Null };
if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\command") -ne $true) { New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\command" -force -ea SilentlyContinue | Out-Null };
if ((Test-Path -LiteralPath "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\DropTarget") -ne $true) { New-Item "HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\DropTarget" -force -ea SilentlyContinue | Out-Null };
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open' -Name 'MuiVerb' -Value '@photoviewer.dll,-3043' -PropertyType String -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\command' -Name '(default)' -Value '%SystemRoot%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1' -PropertyType ExpandString -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\open\DropTarget' -Name 'Clsid' -Value '{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}' -PropertyType String -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print' -Name 'NeverDefault' -Value '' -PropertyType String -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\command' -Name '(default)' -Value '%SystemRoot%\System32\rundll32.exe "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1' -PropertyType ExpandString -Force -ea SilentlyContinue | Out-Null;
New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Classes\Applications\photoviewer.dll\shell\print\DropTarget' -Name 'Clsid' -Value '{60fd46de-f830-4894-a628-6fa81bc0190d}' -PropertyType String -Force -ea SilentlyContinue | Out-Null;

<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Disable unnecessary log files and writes to SSD
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Disable unnecessary log files and writes to SSD" -ForegroundColor Cyan

function create_dummyfolder_file {
  param($CheckPath)
  if ((Test-Path -LiteralPath $CheckPath) -ne $true) { 
    New-Item -Path $CheckPath -ItemType File -force -ea SilentlyContinue | Out-Null; 
    Write-Host "$CheckPath" -BackgroundColor Black -ForegroundColor Green -NoNewline; 
    Write-Host " was created." -ForegroundColor White -BackgroundColor Black 
  } 
  else { 
    Write-Host "$CheckPath" -BackgroundColor Black -ForegroundColor Yellow -NoNewline; 
    Write-Host " already exists." -ForegroundColor White -BackgroundColor Black 
  }
}

$CheckPath = '~\AppData\LocalLow\Deo VR'
create_dummyfolder_file -CheckPath $CheckPath

$CheckPath = '~\AppData\LocalLow\DeoVR'
create_dummyfolder_file -CheckPath $CheckPath



<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Install winget and software
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>
Write-Host "Install winget and software" -ForegroundColor Cyan
$winget_installed = ($null -eq (Get-AppxPackage | Where-Object { $_.Name -eq "*Winget*" }))
if (-Not $winget_installed) {
  Write-Host "Installing Winget." -ForegroundColor Yellow
  # Source of winget download file
  $urisource = 'https://aka.ms/getwinget'
  # Destination to save the file
  $uridestination = '~/Downloads/winget.msixbundle'
  # Download the file
  Invoke-WebRequest -Uri $urisource -OutFile $uridestination
  # Import Appx module and add package
  Import-Module Appx #-usewindowspowershell #only needed on Windows 10
  Add-AppPackage -path '~/Downloads/winget.msixbundle'
}
else {
  Write-Host "Winget is installed." -ForegroundColor Green
}

#Install Software
$confirmation = $(Write-Host "Do you want to install additional software packages?" -ForegroundColor White -BackgroundColor Black -NoNewLine) + $(Write-Host " (y/n): " -ForegroundColor Cyan -BackgroundColor Black -NoNewLine; Read-Host)
if ($confirmation -eq 'y') {
  winget.exe install -e --id 7zip.7zip
  winget.exe install -e --id Argotronic.ArgusMonitor
  winget.exe install -e --id Discord.Discord
  winget.exe install -e --id Elgato.StreamDeck
  winget.exe install -e --id Git.Git
  winget.exe install -e --id Google.Chrome
  winget.exe install -e --id Intel.IntelDriverAndSupportAssistant
  winget.exe install -e --id Logitech.GHUB
  winget.exe install -e --id Microsoft.Edge
  winget.exe install -e --id Microsoft.PowerShell
  #winget.exe install -e --id Microsoft.PowerToys
  winget.exe install -e --id Microsoft.VisualStudioCode
  winget.exe install -e --id Microsoft.WindowsTerminal
  winget.exe install -e --id Mozilla.Firefox
  winget.exe install -e --id EclipseFoundation.Mosquitto
  winget.exe install -e --id Mumble.Mumble
  winget.exe install -e --id Nevcairiel.LAVFilters
  winget.exe install -e --id Nvidia.GeForceExperience
  #winget.exe install -e --id OBSProject.OBSStudio
  winget.exe install -e --id OpenWhisperSystems.Signal
  winget.exe install -e --id ProtonTechnologies.ProtonVPN
  winget.exe install -e --id Spotify.Spotify
  winget.exe install -e --id Twilio.Authy
  winget.exe install -e --id VideoLAN.VLC
}

#Disable integrated GPU
try {
  $igpu = Get-PnpDevice -Class Display | Where-Object Friendlyname -like "*AMD Radeon*"
  if ($igpu.Count -eq 1) {
    $igpu | Disable-PnpDevice -Confirm:$false
    Write-Host "iGPU disabled." -ForegroundColor Green
  }
  else {
    Write-Host "iGPU not found." -ForegroundColor Red
  }
}
catch {
  Write-Host "Error disabling iGPU: $_" -ForegroundColor Red
}

<#
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Stuff that might be interesting
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#>

# # Disable automatic pagefile management
# $cs = gwmi Win32_ComputerSystem
# if ($cs.AutomaticManagedPagefile) {
#   $cs.AutomaticManagedPagefile = $False
#   $cs.Put()
# }
# # Disable a *single* pagefile if any
# $pg = gwmi win32_pagefilesetting
# if ($pg) {
#   $pg.Delete()
# }

<#Hide OneDrive from file explorer
$registryPath = "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
$Name = "System.IsPinnedToNameSpaceTree"
$value = "0"
$registry_type = "DWORD"
create_registry_key
verify_registry_key
#>

