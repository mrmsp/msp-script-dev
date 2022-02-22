## Use this to diagnose which disk is reporting an event log "controller error". Most of the time it will be removable disks like USB flash drives 
## Syncro likes to alert on errors like this: "The driver detected a controller error on \Device\Harddisk2\DR2"
##
## Figuring out what is Harddisk2 (physical) DR2 (arbitrary sequantial disk number) can be done by looking at the output of dd.exe --list
## Determine \Device\HarddiskN\DRx Where N is the physical drive Number and x is the sequential disk number
##
## Download dd from http://www.chrysocome.net/dd and included it in Syncro files. Set Destination File Name to c:\windows\temp\dd.exe
##
## Note other messages like The device, \Device\Harddisk0\DR0, has a bad block. may also be generated. This script won't find those. 

if ($RunMode -eq "list_drives") {
    ## Use dd to dump a list of disks to the Script Output
    c:\windows\temp\dd.exe --list
    
    ##Get-PhysicalDisk | Select -Prop DeviceId,FriendlyName,SerialNumber
    Get-PhysicalDisk | Format-List DeviceId,FriendlyName,SerialNumber
    ## Index Time          EntryType   Source                 InstanceID Message 
    Get-EventLog -Logname System -EntryType Error -Message "*Device\Harddisk*" | Format-List TimeGenerated,Message
    #| Tee-Object -Variable hdderrors
    #Write-Host "Total disk device errors: $($hdderrors.count)"
    ## Remove dd.exe as it is dangerous to leave on a system
    Remove-Item c:\windows\temp\dd.exe
}

if ($RunMode -eq "clear_system_eventlog") {
    ## This removes all events from the System log. There is no other way to clear the entries. Be careful.
    Write-Host "Clearing System Event Log"
    Clear-EventLog -Logname System
    Log-Activity -Message "System Event Log cleared" -EventName "Event Log"
}
