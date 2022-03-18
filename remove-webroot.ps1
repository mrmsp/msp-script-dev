# Removes Webroot SecureAnywhere by force
# Run the script once, reboot, then run again
# Source https://gist.github.com/mark05e/708123de4c095ffb4f735c131d8cc783

#The definitive guide to removing Webroot
#Safe Mode run WRSA --uninstall  #"C:\Program File (x86)\Webroot\wrsa.exe -uninstall"
#
#Reboot in Safe mode unless on WIFI
#Run the script
#Run the removal tool
#Use WBEMTEST to remove the security center entries https://support.cloudradial.com/hc/en-us/articles/360049084271-Removing-Old-Antivirus-Listings-from-Security-Center
#Open a command window as an administrator
#Run the command: 
#WMIC /Node:localhost /Namespace:\\root\SecurityCenter2 Path AntiVirusProduct get * /value
#Run the Windows Management Instrumentation Tester command: 
#WBEMTEST 
#Click the "Connect..." button
#Enter:
#root/securitycenter2
#Click the "Connect" button
#Click the "Query..." button
#Enter: 
#SELECT * from Antivirusproduct
#Select the antivirus to delete
#Click the "Delete" button
#Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Where-Object {$_.displayName -like "Webroot*"}
#Reapply policy
#Wait 4 min
#Refresh the Syncro webpage Bitdefender should be installed
#Delete the alert
## Webroot native tools:
#Invoke-WebRequest -URI 'http://download.webroot.com/WRUpgradeTool.exe' -UseBasicParsing -OutFile .\WRUpgradeTool.exe
#Invoke-WebRequest -URI 'http://download.webroot.com/CleanWDF.exe' -UseBasicParsing -OutFile .\CleanWDF.exe
#https://yagmoth555.wordpress.com/2016/10/20/remove-any-trace-of-an-antivirus-was-installed-wmi/


# Webroot SecureAnywhere registry keys
$RegKeys = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\WRUNINST",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\WRUNINST",
    "HKLM:\SOFTWARE\WOW6432Node\WRData",
    "HKLM:\SOFTWARE\WOW6432Node\WRCore",
    "HKLM:\SOFTWARE\WOW6432Node\WRMIDData",
    "HKLM:\SOFTWARE\WOW6432Node\webroot",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WRUNINST",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WRUNINST",
    "HKLM:\SOFTWARE\WRData",
    "HKLM:\SOFTWARE\WRMIDData",
    "HKLM:\SOFTWARE\WRCore",
    "HKLM:\SOFTWARE\webroot",
    "HKLM:\SYSTEM\ControlSet001\services\WRSVC",
    "HKLM:\SYSTEM\ControlSet001\services\WRkrn",
    "HKLM:\SYSTEM\ControlSet001\services\WRBoot",
    "HKLM:\SYSTEM\ControlSet001\services\WRCore",
    "HKLM:\SYSTEM\ControlSet001\services\WRCoreService",
    "HKLM:\SYSTEM\ControlSet001\services\wrUrlFlt",
    "HKLM:\SYSTEM\ControlSet002\services\WRSVC",
    "HKLM:\SYSTEM\ControlSet002\services\WRkrn",
    "HKLM:\SYSTEM\ControlSet002\services\WRBoot",
    "HKLM:\SYSTEM\ControlSet002\services\WRCore",
    "HKLM:\SYSTEM\ControlSet002\services\WRCoreService",
    "HKLM:\SYSTEM\ControlSet002\services\wrUrlFlt",
    "HKLM:\SYSTEM\CurrentControlSet\services\WRSVC",
    "HKLM:\SYSTEM\CurrentControlSet\services\WRkrn",
    "HKLM:\SYSTEM\CurrentControlSet\services\WRBoot",
    "HKLM:\SYSTEM\CurrentControlSet\services\WRCore",
    "HKLM:\SYSTEM\CurrentControlSet\services\WRCoreService",
    "HKLM:\SYSTEM\CurrentControlSet\services\wrUrlFlt",
    "HKLM:\SOFTWARE\Classes\Installer\Products\FCEB3C89F5DD2D44E83F849A34256374",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\FCEB3C89F5DD2D44E83F849A34256374",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{98C3BECF-DD5F-44D2-8EF3-48A943523647}",
    "HKLM:\SOFTWARE\Classes\CLSID\{C9C42510-9B41-42c1-9DCD-7282A2D07C61}",
    "HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{C9C42510-9B41-42c1-9DCD-7282A2D07C61}"
)

# Webroot SecureAnywhere startup registry item paths
$RegStartupPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)

# Webroot SecureAnywhere folders
$Folders = @(
    "$Env:ProgramData\WRData",
    "$Env:ProgramData\WRCore",
    "$Env:Programfiles\Webroot",
    "$Env:Programfiles(x86)\Webroot",
    "$Env:ProgramData\Microsoft\Windows\Start Menu\Programs\Webroot SecureAnywhere"
)

# Webroot SecureAnywhere services
$Services = @(
    "WRSVC",
    "WRCoreService",
    "WRSkyClient"
)

Write-Host "Webroot SecureAnywhere removal script running"
$verbose = $true

# Check for SAFE MODE with NETWORKING as most of this script will require SAFE MODE
$BootState = gwmi win32_computersystem | select BootupState | Select-Object { $_.BootupState }
Write-Host $BootState.BootupState
if ($BootState.BootupState -eq "Normal boot") { 
    Write "WARNING - Normal boot mode detected. This script requires SAFE MODE with Networking to remove Webroot Services." 
    # Try to Uninstall via msi
    cd c:\windows\temp
    Invoke-WebRequest -URI 'https://anywhere.webrootcloudav.com/zerol/wsasme.msi' -UseBasicParsing -OutFile .\wsasme.msi
    msiexec /i wsasme.msi GUILIC=***REMOVED*** CMDLINE=SME, quiet /qn /l*v wsasme-install.log
    Start-Sleep 60
    msiexec /x wsasme.msi /qn /L*v wsasme-uninstall.log
    
}
if ($BootState.BootupState -eq "Fail-safe boot" -or $BootState.BootupState -eq "Fail-safe with network boot") { 
    Write "SAFE MODE detected. This script requires SAFE MODE with Networking to remove Webroot Services." 
}

# Do a cursory check to see if webroot is installed and running. Be verbose if it looks like it's running. Also recommend -uninstall first

# Try to Uninstall - https://community.webroot.com/webroot-secureanywhere-antivirus-12/pc-uninstallation-option-missing-from-control-panel-34688
#Start-Process -FilePath "${Env:ProgramFiles(x86)}\Webroot\WRSA.exe" -ArgumentList "-uninstall" -Wait -ErrorAction SilentlyContinue
#Start-Process -FilePath "${Env:ProgramFiles}\Webroot\WRSA.exe" -ArgumentList "-uninstall" -Wait -ErrorAction SilentlyContinue

Write-Host "List Packages"
Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Webroot SecureAnywhere" }
Get-Package -Provider Programs -IncludeWindowsInstaller -Name "Webroot SecureAnywhere"
Write-Host "Attempt Uninstall"
Uninstall-Package -Name 'Webroot SecureAnywhere' -Force

# Disable, Stop & Delete Webroot SecureAnywhere service
Write-Host " Looking for Services..."
ForEach ($Service in $Services) {
    $WebrootService = Get-Service -Name $Service -ErrorAction SilentlyContinue
    if ($WebrootService.Count -gt 0) {
        Write-Host "  Removing Service: $Service"
        Set-Service -Name $service -StartupType Disabled -Verbose -ErrorAction SilentlyContinue
        sc config $Service start=disabled
        Stop-Service -Name $service -Force -Verbose -ErrorAction SilentlyContinue
        sc.exe stop $Service
        Remove-Service -Name $service -Verbose -ErrorAction SilentlyContinue
        sc.exe delete $Service
        $WebrootServiceVerify = Get-Service -Name $Service -ErrorAction SilentlyContinue
        if ($WebrootServiceVerify.Count -gt 0) {
            Write-Host "  Failure. Service: $($Service) still exists."
        }
        else {
            Write-Host "  Success. Service: $($Service) removed."
        }
    }
}
# Stop Webroot SecureAnywhere process
Stop-Process -Name "WRSA" -Force -Verbose -ErrorAction SilentlyContinue

# Remove Webroot SecureAnywhere registry keys
Write-Host " Looking for registry keys..."
ForEach ($RegKey in $RegKeys) {
    if ($verbose) { Write-Host "  Looking for Registry key $RegKey" }
    $RegItemCheck = Get-ItemProperty -Path $RegKey -ErrorAction SilentlyContinue
    if ($RegItemCheck.Count -gt 0) {
        Write-Host "  Removing $RegKey"
        Remove-Item -Path $RegKey -Force -Recurse -Verbose -ErrorAction SilentlyContinue
        # Verify removal
        $RegItemVerify = Get-ItemProperty -Path $RegKey -ErrorAction SilentlyContinue
        if ($RegItemVerify.Count -gt 0) {
            Write-Host "  Failure. Reg Key Item $($RegKey) still exists."
        }
        else {
            Write-Host "  Success. Reg Key Item $($RegKey) removed."
        }
    }
}

# Remove Webroot SecureAnywhere registry startup items
Write-Host " Looking for Registry Startup Items..."
ForEach ($RegStartupPath in $RegStartupPaths) {
    if ($verbose) { Write-Host "  Looking for WRSVC in $RegStartupPath" }
    $RegPathCheck = Get-ItemProperty -Path $RegStartupPath -Name "WRSVC" -Verbose -ErrorAction SilentlyContinue
    if ($RegPathCheck.Count -gt 0) {
        Write-Host "  Removing WRSVC from $RegStartupPath"
        Remove-ItemProperty -Path $RegStartupPath -Name "WRSVC" -Verbose -ErrorAction SilentlyContinue
        # Verify removal
        $RegPathVerify = Get-ItemProperty -Path $RegStartupPath -Name "WRSVC" -Verbose -ErrorAction SilentlyContinue
        if ($RegPathVerify.Count -gt 0) {
            Write-Host "  Failure. Reg Key Item WRSVC in: $($RegStartupPath) still exists."
        }
        else {
            Write-Host "  Success. Reg Key Item WRSVC in: $($RegStartupPath) removed."
        }
    }
}

# Remove Webroot SecureAnywhere folders
Write-Host " Looking for file folders..."
ForEach ($Folder in $Folders) {
    Write-Host "  Removing $Folder"
    Remove-Item -Path "$Folder" -Force -Verbose -Recurse -ErrorAction SilentlyContinue
}

## Display installed AV products
$avproducts = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Where-Object { $_.displayName -like "Webroot*" }
Write-Host " Looking for AV in Security Center registry keys..."
ForEach ($avproduct in $avproducts) {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Security Center\Provider\Av\$($avproduct.instanceGuid)" -Force -Recurse -ErrorAction SilentlyContinue

    $AVProductVerify = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Security Center\Provider\Av\$($avproduct.instanceGuid)" -ErrorAction SilentlyContinue
    if ($AVProductVerify.Count -gt 0) {
        Write-Host "  Failure Reg Key: $($avproduct.instanceGuid) still exists. Reboot and run this script again. If this still exists, then proceed to the WBEMTEST manual procedure."
    }
    else {
        Write-Host "  Success Reg Key: $($avproduct.instanceGuid) removed."
    }


}
