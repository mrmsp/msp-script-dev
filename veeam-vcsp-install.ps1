## Veeam VCSP Agent Install / Uninstall script
## Create a customer custom asset field called "nickname"
## Map variable "install_mode" to a dropdown with values install, uninstall, reinstall, enable_wake_timers
## Map variable "customer_name" to {{customer_business_name}}
## Map variable "customer_nickname" to {{customer_custom_field_nickname}}
## Edit each customer to set a nickname. Use a single non-spaced abbreviation. This helps with filenames used with the VCSP agent
## Create each client in VCSP with the nickname. Then build an installer file Discovery / Discovered Computers / Download Agent.
## Upload those agents to your primary and backup servers and put those URLs in server1 and server2 below
Import-Module $env:SyncroModule
$vcsp_server = "vcsp.veeam.example.com"
$server1 = "https://downloads.example.com/veeam/"
$server2 = "https://s3.amazonaws.com/bucket/veeam/"

function main() {
    ## Customer_Nickname custom field check
    if (!$customer_nickname) {
        Write-Host "Error Please update the nickname custom field for customer: $customer_name"
        exit 1
    }
    #$agentfile="ManagementAgent.x64." + $customer_nickname + ".msi"
    $agentfile="ManagementAgent." + $customer_nickname + ".exe"
    Write-Host $agentfile
    
    ## Uninstall Veeam VCSP Agent if uninstall or reinstall is requested
    if ($install_mode -eq "uninstall" -or $install_mode -eq "reinstall") {
        uninstall-vcsp
    }

    ## Install or Reinstall Veeam VCSP Agent
    if($install_mode -eq "install" -or $install_mode -eq "reinstall") {
        download-vcsp
        install-vcsp
    }  
    
    ## Enable the sleep wake timers in the power profiles
    if($install_mode -eq "enable_wake_timers" -or $install_mode -eq "install" -or $install_mode -eq "reinstall") {
        show-sleep-wake-timers
        enable-all-sleep-wake-timers
    }  
}

function show-sleep-wake-timers {
    ## This makes the option Allow Wake Timers available in Advanced Power Settings / Sleep. It does not enable or disable them they are just hidden in some profiles.
    ## Without enabling these, a warning may be generated in Veeam backups.
    ## https://www.tenforums.com/tutorials/65716-add-remove-allow-wake-timers-power-options-windows-10-a.html
    REG.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\BD3B718A-0680-4D9D-8AB2-E1D2B4AC806D /v Attributes /t REG_DWORD /d 2 /f
    
    ## Remove/Hide the option via powercfg
    #powercfg -attributes SUB_SLEEP BD3B718A-0680-4D9D-8AB2-E1D2B4AC806D +ATTRIB_HIDE
}

function enable-all-sleep-wake-timers {
    ## This script enables the sleep wake timers in all power profiles
    $PowerSchemes = (powercfg.exe /LIST) | Select-String "power scheme guid" -List
    $AllowWakeTimersGUID = ((powercfg.exe /q) | Select-String "(Allow wake timers)").tostring().split(" ") | where {($_.length -eq 36) -and ([guid]$_)} 

    foreach ($PowerScheme in $PowerSchemes) {
        $PowerSchemeGUID = $PowerScheme.tostring().split(" ") | where {($_.length -eq 36) -and ([guid]$_)}
        foreach ($Argument in ("/SETDCVALUEINDEX $PowerSchemeGUID SUB_SLEEP $AllowWakeTimersGUID 1","/SETACVALUEINDEX $PowerSchemeGUID SUB_SLEEP $AllowWakeTimersGUID 1")) {
            Start-Process powercfg.exe -ArgumentList $Argument -Wait -Verb runas -WindowStyle Hidden
        }
    }
}


## Function to remove invalid characters from company name to create clean filenames.
##  Not currently used
Function Remove-InvalidFileNameChars {
  param(
    [Parameter(Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [String]$Name
  )

  $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
  $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
  return ($Name -replace $re)
}

## Standard download using powershell
function download-vcsp() {
    $ProgressPreference = 'SilentlyContinue' # Hide irw progress bar to boost speed
    try { Invoke-WebRequest -Uri "$($server1)$($agentfile)" -OutFile "$($env:temp)\$($agentfile)" } catch {
        try { Invoke-WebRequest -Uri "$($server2)$($agentfile)" -OutFile "$($env:temp)\$($agentfile)" } catch {
            Write-Host "ERROR - Unable to download the VCSP agent installer $($agentfile)"
            exit 1
        }
    }

}

## Install VCSP .exe file
function install-vcsp() {
    Write-Host "Installing..."
    $file = "$($env:temp)\$($agentfile)"
    $DateStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = '{0}-{1}.log' -f $file,$DateStamp
    $Arguments = @(
        "/qn"
        "/norestart"
        "/L*v"
        $logFile
        "VAC_MANAGEMENT_AGENT_TYPE=2"
        ('VAC_SERVER_NAME={0}' -f $vcsp_server)        
        "ACCEPT_THIRDPARTY_LICENSES=1"
        "ACCEPT_EULA=1"
    )
    
    Write-Host $Arguments
    Start-Process $file -ArgumentList $Arguments -Wait -NoNewWindow 
}

function uninstall-vcsp() {
    #Get-Package -Name "Veeam Service Provider Console Management Agent" | Uninstall-Package
    Get-Package -Name "*Veeam*" | Uninstall-Package

    ## https://www.veeam.com/kb2335
    ## This registry value will reset all Veeam Agent for Microsoft Windows settings, removing existing job settings and related job history. 
    ## Restore points created before the reset will not be removed and recoverable; however, they will not be tracked for retention.
    New-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Endpoint Backup" -Name "ReCreateDatabase" -Value 1
}

## Install VCSP .msi file
function install-vcsp-msi() {
    Write-Host "Installing..."
    $file = "$($env:temp)\$($agentfile)"
    $DateStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = '{0}-{1}.log' -f $file,$DateStamp
    $MSIArguments = @(
        "/i"
        ('"{0}"' -f $file)
        "/qn"
        "/norestart"
        "/L*v"
        $logFile
        "VAC_MANAGEMENT_AGENT_TYPE=2"
        ('VAC_SERVER_NAME={0}' -f $vcsp_server)        
        "ACCEPT_THIRDPARTY_LICENSES=1"
        "ACCEPT_EULA=1"
    )

    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow 
}

## Uninstall VCSP from the .msi file
function uninstall-vcsp-msi() {
    ## Alternate uninstall using Get-Software
    Write-Host "Uninstalling..."
    ## MSI Uninstall
    $file = "$($env:temp)\$($agentfile)"
    $DateStamp = get-date -Format yyyyMMddTHHmmss
    $logFile = '{0}-uninstall-{1}.log' -f $file,$DateStamp
    $MSIArguments = @(
        "/x"
        ('"{0}"' -f $file)
        "/qn"
        "/norestart"
        "/L*v"
        $logFile
    )
    
    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow 
}

main