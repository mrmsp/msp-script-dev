# Create a Syncro RMMAlert when a Veeam backup fails. Also sets the asset custom field "Backup Status" to latest Veeam result. 
# Required Asset custom field "Backup Status". Must be run daily as the event log search is limited to 1 day back.
# Optional pass in $prev_status platform variable from {asset_custom_field_backup_status} to Alert if no backups after x number of days
# Optional pass in $num_days runtime variable to allow a few days between backups for some machines (weekends/mobile devices). Default 5 days
Import-Module $env:SyncroModule

## Set the default number of days back to check for good backups
if (!(Test-Path variable:$num_days)) { $num_days = -5 }
## If a positive number was passed in, convert it to negative
if ($num_days -gt 0) { $num_days *= -1 }
## If days was set to 0, then change it to 1 day
if ($num_days -gt -1) { $num_days = -1 }

## Fetch the most recent Veeam log entry
$event = Get-EventLog "Veeam Agent" -InstanceID 190 -newest 1 -ErrorAction SilentlyContinue
##$event = Get-EventLog "Veeam Agent" -newest 1 -After (Get-Date).AddDays(-1) | Where-Object {$_.EventID -eq 190}

## No backup events found and Backup Status is empty
if ($event.count -eq 0 -and $prev_status -eq "") {
    write-host "Veeam Backup Missing! No Backups found."
    Rmm-Alert -Category "veeam_backup_failed" -Body "Veeam Backup Missing! No Backups found."
    exit 0
}

## If the log entry contains the keyword "Error"
if($event.entrytype -eq "Error") {
    write-host "Veeam Agent Error: $($event.message)"
    Rmm-Alert -Category "veeam_backup_failed" -Body "Veeam Backup Error: $($event.message)"
}

## Update the Asset Field with the most current log entry
if ($event) {
    Set-Asset-Field -Name "Backup Status" -Value "$($event.timegenerated) $($event.entrytype) $($event.message)"
    ## We have a good backup so clean up any remaining alerts
    $prev_status = ""
    Close-Rmm-Alert -Category "veeam_backup_failed" -CloseAlertTicket "true"
}

## If the last backup is too old, then set an Alert
if ($prev_status) {
    $prev_date = [datetime]::parseexact($prev_status.substring(0, 10), 'MM/dd/yyyy', $null)
    if ($prev_date -lt (Get-Date).AddDays($num_days)) {
        write-host "Veeam Backup Missing Last backup: $($prev_status.substring(0, 10))"
        Rmm-Alert -Category "veeam_backup_failed" -Body "Veeam Backup Missing! Last backup: $($prev_status.substring(0, 10))"
    }
}

exit 0