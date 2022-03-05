## Reboot mode script. Shows available operating systems, reboot in safe mode with syncro, reboot back to normal, enable F8 startup key, disabled F8 startup key
## Create Syncro variable dropdown with these values: list (default), reboot_safe_networking, reboot_normal, enable_f8, disable_f8
Import-Module $env:SyncroModule

main {
    switch -Exact ($boot_mode) {
        'list' {
            ## List the current boot environments to the script output
            bcdedit
        }
        'test' {
            ## List the current boot environments to the script output
            ## Fail-Safe return to Normal Mode
            if ( !(Test-RegistryValue ('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon', 'Shell_Backup') ) ) { 
                Write-Host "Making a backup of the Winlogon key"
                $WinlogonData = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "Shell"
            }
            
        }
        'reboot_safe_networking' {
            ## Reboot now in Safe Mode with Networking

            ## Enable Syncro services in Safe Mode
            REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\Syncro /f /ve /t REG_SZ /d Service
            REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\SyncroLive /f /ve /t REG_SZ /d Service
            REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\SyncroOvermind /f /ve /t REG_SZ /d Service

            ## Enable Installer Service
            REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\MSIServer /f /ve /t REG_SZ /d Service

            ## TODO Add Fail-Safe reboot script in safe mode here

            ## Set current boot OS to safe mode with networking
            $args = "/set {current} safeboot network"
            Start-Process -FilePath "bcdedit.exe" -ArgumentList $args
            ##Start-Process bcdedit.exe /set {current} safeboot network
            shutdown -r -t 5
        }
        'reboot_normal' {
            ## Reboot now in Normal Mode
            $args = "/deletevalue {current} safeboot"
            Start-Process -FilePath "bcdedit.exe" -ArgumentList $args
            ##bcdedit.exe /deletevalue {current} safeboot
            shutdown -r -t 5
        }
        'enable_f8' {
            ##Enable F8 mode
            $args = "/set {default} bootmenupolicy legacy"
            Start-Process -FilePath "bcdedit.exe" -ArgumentList $args
            ##bcedit.exe /set {default} bootmenupolicy legacy
        }
        'disable_f8' {
            ##Disable F8 mode
            $args = " /set {default} bootmenupolicy STANDARD"
            Start-Process -FilePath "bcdedit.exe" -ArgumentList $args
            ##bcedit.exe /set {default} bootmenupolicy STANDARD
        }
    }
}

function Test-RegistryValue {
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Path,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$Value
    )

    try {
        Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
        return $true
    }

    catch {
        return $false
    }
}

main