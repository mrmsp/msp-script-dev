## Reboot mode script. Shows available operating systems, reboot in safe mode with syncro, reboot back to normal, enable F8 startup key, disabled F8 startup key
## Safe mode contains a 15 min return to normal mode automatically script. Returning to normal mode by running the script again also works.
## Note you must login for the timer to begin. If you can't login, once a client logs in, it will start the reboot timer and clean itself up. You might not be able to login, but at least the next client login will get it back to normal.
## If the client PC is connected via WIFI the script will cancel itself as WIFI will not automatically connect in Safe Mode.
## Create Syncro variable dropdown with these values: list (default), reboot_safe_networking, reboot_normal, enable_f8, disable_f8
Import-Module $env:SyncroModule

function main {

    switch -Exact ($boot_mode) {
        'list' {
            ## List the current boot environments to the script output
            bcdedit
        }

        'reboot_safe_networking' {
            ## Reboot now in Safe Mode with Networking

            ## Enable Syncro services in Safe Mode
            REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\Syncro /f /ve /t REG_SZ /d Service
            REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\SyncroLive /f /ve /t REG_SZ /d Service
            REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\SyncroOvermind /f /ve /t REG_SZ /d Service

            ## Enable Installer Service
            REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Minimal\MSIServer /f /ve /t REG_SZ /d Service

            ## WIFI CHECK
            if ( (netsh wlan show interfaces | select-string SSID).Length ) { Write-Host "Client is connected via WIFI. Cancelling Safe Mode reboot."; exit 1}

            ## Fail-Safe return to Normal Mode
            if ( (Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Value 'Shell_Backup') -ne $true ) {
                Write-Host "Making a backup of the Winlogon key"
                $WinlogonData = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "Shell"
            }
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  -Name "Shell" -Value "explorer.exe, c:\fail_safe_normal_reboot.cmd" -PropertyType String -Force

            ## Write the fail-safe script
            Remove-Item "c:\fail_safe_normal_reboot.cmd" -Force
            Add-Content -Path "c:\fail_safe_normal_reboot.cmd" -Value $FailSafeScript

            ## Set current boot OS to safe mode with networking
            $args = "/set {current} safeboot network"
            Start-Process -FilePath "bcdedit.exe" -ArgumentList $args
            shutdown -r -t 5
        }
        'reboot_normal' {
            ## Reboot now in Normal Mode
        
            ## Remove the failsafe script
            Remove-Item "c:\fail_safe_normal_reboot.cmd" -Force -ErrorAction SilentlyContinue
        
            ## Remove the registry entry
            if ( (Test-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Value 'Shell_Backup') -eq $true ) {
                ## Restore from the backup Shell entry we made
                $WinlogonData = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "Shell_Backup"
                New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  -Name "Shell" -Value $WinlogonData -PropertyType String -Force
            }
            else {
                ## No backup found. Put it back to explorer.exe
                New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  -Name "Shell" -Value "explorer.exe" -PropertyType String -Force
            }
        
            $args = "/deletevalue {default} safeboot"
            Start-Process -FilePath "bcdedit.exe" -ArgumentList $args
       
            shutdown -a
            shutdown -r -t 5
        }
        'enable_f8' {
            ## Enable F8 mode - Adds the ability to hit F8 on startup for Safe Mode like Windows 7
            $args = "/set {default} bootmenupolicy legacy"
            Start-Process -FilePath "bcdedit.exe" -ArgumentList $args
        }
        'disable_f8' {
            ## Disable F8 mode - Removes the ability to hit F8 on startup for Safe Mode (Windows Default)
            $args = " /set {default} bootmenupolicy STANDARD"
            Start-Process -FilePath "bcdedit.exe" -ArgumentList $args
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

$FailSafeScript = @'
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "Shell" /t REG_SZ /d "explorer.exe" /f 
bcdedit.exe /deletevalue {default} safeboot
shutdown -r -t 900 
(goto) 2>nul & del "%~f0"
'@

main