# This script will test our ability to reach keys for the uninstall script on different OSes - Win 7, Win 8.1 and Win 10

# Access to HKCR requires a temporary drive mapping
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

# Stop Ninja service
net stop NinjaRMMAgent

# Set current Ninja install and registry paths
if([system.environment]::Is64BitOperatingSystem)
{ 
    $ninjaSoftKey = 'HKLM:\SOFTWARE\WOW6432Node\NinjaRMM LLC\NinjaRMMAgent'
    $uninstallKey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'  
}
else
{ 
    $ninjaSoftKey = 'HKLM:\SOFTWARE\NinjaRMM LLC\NinjaRMMAgent'
    $uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'    
}
try {
    $ninjaDir = $((Get-ItemProperty -Path $ninjaSoftKey).Location)
    $ninjaDir = $ninjaDir.Replace('/','\') # repair path with slash instead of backslash
} catch {
    Write-Output "Ninja directory not present or could not be found."
}
$installerKey = 'HKCR:\Installer\Products'
$installerProductsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\'
$installerComponentsKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components'
$ninjaSoftKeyRoot = 'HKLM:\SOFTWARE\WOW6432Node\NinjaRMM LLC'
$servicesKey = 'HKLM:\SYSTEM\Setup\FirstBoot\Services'
$msiKey = 'HKLM:\SOFTWARE\WOW6432Node\EXEMSI.COM\MSI Wrapper\Installed'
function Test-RegistryValue {

    param (    
     [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Path,
     [parameter(Mandatory=$true)]
     [ValidateNotNullOrEmpty()]$Value
    )    
    try {

    Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
     return $true
    } catch {
        return $false
    }
    
}

# get packageCode and childName
Set-Location HKCR:
$keys = Get-ChildItem $installerKey | Get-ItemProperty -name 'ProductName' 
foreach ($key in $keys) {
    if ($key.'ProductName' -eq 'NinjaRMMAgent'){
        $foundHKCRKey = $key
        $packageCode = (Get-Item $key.PSPath | Get-ItemProperty -name 'PackageCode').packageCode
        $childName = (Get-ItemProperty $key.PSPath).PSChildName
        
        }
}

# get installerProductsKey
Set-Location HKLM:
$foundInstallerProductsKey = Get-ChildItem $installerProductsKey\$childName

# get installerComponentsKey
$keys = Get-ChildItem $installerComponentsKey
foreach ($key in $keys) {
    if (Test-RegistryValue -Path $key -Value $childName){
        $foundComponentKey = $key       
    } 
}

# get servicesKey
$keys = Get-ChildItem $servicesKey |  Get-ItemProperty -name 'ServiceName'
foreach ($key in $keys) {
    if ($key.'ServiceName' -eq 'NinjaRMMAgent'){
        $foundServicesKey = $key       
    } 
}

# get msiKey
$keys = Get-ChildItem $msiKey
foreach ($key in $keys) {
    if ($key.PSChildName -like 'NinjaRMMAgent*'){
        $foundMsiKey = $key       
    } 
}


#Handle Removing agents that are uninstall protected
$uninstallProtectionFile = "C:\ProgramData\NinjaRMMAgent\storage\njfile.bin"

if ( Test-Path $uninstallProtectionFile )
{
	if ( -not(Test-Path $ninjaDir\uninstall.exe) )
	{
		#disable uninstall prevention
		echo "Disabling uninstall prevention"
		& "$ninjaDir\NinjaRMMAgent.exe" -disableUninstallPrevention
	}	
	
	if ( -not(Test-Path $ninjaDir\uninstall.exe) )
	{
		echo "Missing uninstall.exe! Exiting..."
		exit 1 
	}
}

# Executes uninstall.exe in Ninja install directory
#& '$ninjaDir\uninstall.exe' --% --mode unattended | out-null
try {
    $filePath = Join-Path -Path $ninjaDir -ChildPath "uninstall.exe"
    Start-Process -FilePath $filePath -ArgumentList '--mode unattended'
} catch {
    Write-Output "Could not run Ninja agent uninstall. May have already been removed or cannot be found. Continuing removal."
}

Start-Sleep -Seconds 180

# Delete Ninja install directory and all contents
try {
    & cmd.exe /c rd /s /q $ninjaDir
}
catch {
    Write-Output "Unable to delete Ninja directory as it has already been removed. Continuing cleanup."
}

# Removes the Ninja service
sc.exe DELETE NinjaRMMAgent

Start-Sleep -Seconds 90

#delete foundHKCRKey
try {
    Remove-Item -Path $foundHKCRKey.PSPath -Recurse -Force
    Write-Output "foundHKCRKey deleted"
} catch {
    Write-Output "foundHKCRKey already deleted or was not found"
}
# delete installerProductsKey
try {
    Remove-Item -Path $foundInstallerProductsKey.PSPath -Recurse -Force
    Write-Output "foundInstallerProductsKey deleted"
} catch {
    Write-Output "foundInstallerProductsKey already deleted or was not found"
}

# delete installerComponentsKey
try {
    Remove-Item -Path $foundComponentKey.PSPath -Recurse -Force
    Write-Output "foundComponentKey deleted"
} catch {
    Write-Output "foundComponentKey already deleted or was not found"
}


# delete ninjaSoftKeyRoot
try {
    Remove-Item -Path $ninjaSoftKeyRoot.PSPath -Recurse -Force
    Write-Output "foundSoftKeyRoot deleted"
} catch {
    Write-Output "foundSoftKeyRoot already deleted or was not found"
}


# delete servicesKey
try {
    Remove-Item -Path $foundServicesKey.PSPath  -Recurse -Force
    Write-Output "foundServicesKey deleted"
} catch {
    Write-Output "foundServicesKey already deleted or was not found"
}

# delete msiKey
try {
    Remove-Item -Path $foundMsiKey.PSPath -Recurse -Force
    Write-Output "foundMsiKey deleted"
} catch {
    Write-Output "foundMsiKey already deleted or was not found"
}

#remove drive mapping previously created to HKCR
Remove-PSDrive -Name HKCR

Write-Output "Script complete."

Exit