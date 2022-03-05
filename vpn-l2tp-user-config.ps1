# VPN Settings
$Settings = @{
    Name                  = "$ENV:VPNName"
    ServerAddress         = "$ENV:ServerAddress"
    L2tpPsk	              = "$ENV:L2tpPsk"
    TunnelType 		      = "L2TP" 
    EncryptionLevel       = "Optional" 
    AuthenticationMethod  = "MSChapv2"
    Force	          	  = $True 
    RememberCredential    = $True 
    SplitTunneling        = $False
    AllUserConnection	  = $True
    DnsSuffix             = "$ENV:DnsSuffix"
}


# VPN User Credentials
$UserSettings = @{
    connectionname        = "$ENV:VPNName"
    username              = "$ENV:VPNUserName"
    password              = "$ENV:VPNUserPass" 
}


function ConvertStringToBoolean ([string]$value) {
    $value = $value.ToLower();


    switch ($value) {
        "true" { return $true; }
        "1" { return $true; }
        "false" { return $false; }
        "0" { return $false; }
    }
}


[bool]$UseWinCredsSwitch = ConvertStringToBoolean($ENV:UseWinCreds)


# Create VPN Connection
$VPN = Get-VPNconnection -name $($Settings.Name)
if (!$VPN) {
    Add-VPNconnection @Settings -UseWinLogonCredential:$UseWinCredsSwitch -verbose
}
else {
    Set-VpnConnection @settings -UseWinLogonCredential:$UseWinCredsSwitch -Verbose
}
# Checks if user credentials are set, otherwise ends script.
# Sets script bypass policy, installs NuGet + credentials helper module.
# Finds current user and creates a scheduled task that runs once on next login, then deletes itself. 
if (!"$ENV:VPNUserName") { break } 
else {
Set-ExecutionPolicy Bypass -Scope Process
Install-PackageProvider -Name NuGet -Force
Install-Module -Name VPNCredentialsHelper -Force
# Finds current user and creates a scheduled task that runs once on next login, then deletes itself. 
$ENV:Confirm = '$false'
$current_user = (Get-CimInstance –ClassName Win32_ComputerSystem | Select-Object -expand UserName)
$action1 = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-WindowStyle Hidden Import-Module VPNCredentialsHelper; Set-VpnConnectionUserNamePassword -connectionname '$ENV:VPNName' -username '$ENV:VPNUserName' -password '$ENV:VPNUserPass' -domain ''"
$delete = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-WindowStyle Hidden Unregister-ScheduledTask -TaskName VPNSetup -TaskPath \ -Confirm:$ENV:confirm"
$trigger1 = New-ScheduledTaskTrigger -AtLogOn -User $current_user
$task = New-ScheduledTask -Action $action1,$delete -Trigger $trigger1 
Register-ScheduledTask -Action $action1,$delete -Trigger $trigger1 -User $current_user -Description "Add VPN Credentials" -TaskName 'VPNSetup' -RunLevel Highest
$ScheduledTaskSettings1 = New-ScheduledTaskSettingsSet –AllowStartIfOnBatteries –DontStopIfGoingOnBatteries -Hidden
Set-ScheduledTask -TaskName 'VPNSetup' -TaskPath \ -Settings $ScheduledTaskSettings1


# Set VPN Profile to Private
$action2 = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "Set-NetConnectionProfile -InterfaceAlias '$ENV:VPNName' -NetworkCategory Private"
$delete2 = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-WindowStyle Hidden Unregister-ScheduledTask -TaskName 'SetVPNProfile' -TaskPath \ -Confirm:$ENV:confirm"
$CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
$trigger2 = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$trigger2.Subscription = 
@"
<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name='Rasman'] and EventID=20267]]</Select></Query></QueryList>
"@
Register-ScheduledTask -Action $action2,$delete2 -Trigger $trigger2 -TaskName "SetVPNProfile" -Description 'Set VPN Profile to Private' -User 'System' -Force 
$ScheduledTaskSettings2 = New-ScheduledTaskSettingsSet –AllowStartIfOnBatteries –DontStopIfGoingOnBatteries -Hidden
Set-ScheduledTask -TaskName 'SetVPNProfile' -TaskPath \ -Settings $ScheduledTaskSettings2
}