## Reboot mode script. Shows available operating systems, reboot in safe mode with syncro, reboot back to normal, enable F8 startup key, disabled F8 startup key
## Create Syncro variable $boot_mode of type dropdown with these values: list (default), reboot_safe_networking, reboot_normal, enable_f8, disable_f8
Import-Module $env:SyncroModule

switch -Exact ($boot_mode)
{
    'list'
    {
        ## List the current boot environments to the script output
        bcdedit
    }
    'reboot_safe_networking'
    {
        ## Reboot now in Safe Mode with Networking

        ## Enable Syncro services in Safe Mode
        REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\Syncro /f /ve /t REG_SZ /d Service
        REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\SyncroLive /f /ve /t REG_SZ /d Service
        REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Network\SyncroOvermind /f /ve /t REG_SZ /d Service

        ## Set current boot OS to safe mode with networking
        bcdedit /set {current} safeboot network
        shutdown -r -t 5

        ## TODO Add a startup script to reboot back to normal mode after 30 min
        ##   We know scheduled events don't work, AT has been deprecated, Winlogin may support a batch file
        ##   HKLM\Software\Microsft\Windows NT\CurrentVersion\Winlogin
        ##   Append the 'Winlogon' list. By default it only has 'explorer.exe'.  Add a ', ' (note the space after the comma) 
        ##   and then the an executable path.
        ##   reg.exe add "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v "Shell" /t REG_SZ /d "explorer.exe, c:\safe_mode_emergency_exit.bat" /f
        ## 
        ## pseudocode:
        ## if (safemode) {
        ##    reg.exe add "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" /v "Shell" /t REG_SZ /d "explorer.exe" /f
        ##    bcdedit /deletevalue {current} safeboot
        ##    shutdown -r -t 6000 }
    }
    'reboot_normal'
    {
        ## Reboot now in Normal Mode
        bcdedit /deletevalue {current} safeboot
        shutdown -r -t 5
    }
    'enable_f8'
    {
        ##Enable F8 mode
        bcedit /set {default} bootmenupolicy legacy
    }
    'disable_f8'
    {
        ##Disable F8 mode
        bcedit /set {default} bootmenupolicy STANDARD
    }
}