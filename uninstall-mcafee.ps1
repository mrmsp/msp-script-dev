Import-Module $env:SyncroModule

Function main {
    ## Make sure choco is available to install 7-Zip if necessary
    #verify-kabuto-patch-manager-choco

    ## Install 7-Zip
    #choco-install-7zip
    manual-install-7zip
    
    ## Download and run the McAfee uninstall tool
    download-mcafee-uninstall-tool
    ## Use Powershell to uninstall any windows apps or Store apps
    uninstall-mcafee-windows


    #"c:\Program Files\McAfee\Agent\x86\frminst.exe" /forceuninstall
    #"c:\Program Files\McAfee\Common Framework\x86\frminst.exe" /forceuninstall

    ## Optional Uninstall 7Zip
    #manual-uninstall-7zip

    exit 0
}

Function uninstall-mcafee-windows {
    # Remove the Store apps from McAfee
    $RemoveApp = 'Mcafee'
    Write-Host "Running Powershell McAfee uninstalls"
    Get-apppackage -AllUsers -Name *McAfee* 
    Get-apppackage -AllUsers -Name *McAfee* | Remove-AppPackage
    Get-apppackage -Name *McAfee* | Remove-AppPackage

    Get-AppxPackage -AllUsers | Where-Object {$_.Name -Match $RemoveApp} | Remove-AppxPackage
    Get-AppxPackage | Where-Object {$_.Name -Match $RemoveApp} | Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -Match $RemoveApp} | Remove-AppxProvisionedPackage -Online
}


Function download-mcafee-uninstall-tool {
    Invoke-WebRequest -Uri "https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe" -OutFile "$($env:temp)\mcpr.exe"
    $hash = Get-FileHash "$($env:temp)\mcpr.exe"
    $signerhash = Get-AuthenticodeSignature "$($env:temp)\mcpr.exe"
    if ($hash.Hash -eq "EBE35EED514B72AC550F98F9B225FEC9A2D6C6929E5DE66B37952EFF293D2A2C" -and $signerhash.Status -eq "Valid") {        
        Start-Process "$($env:Programfiles)\7-Zip\7z.exe" -ArgumentList "x $($env:temp)\mcpr.exe -aoa -o$($env:temp)\mcpr" -passthru -Wait -NoNewWindow
        Set-Location "$($env:temp)\mcpr\`$TEMP\`$_0_"
        Write-Host "Starting to remove Mcafee"
        $programArg= "-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUE -v -s"
        $process = Start-Process ".\mccleanup.exe" -ArgumentList $ProgramArg -passthru -Wait -NoNewWindow
    }
    #Remove-Item "$($env:temp)\mcpr" -Recurse -Force
    #Remove-Item "$($env:temp)\mcpr.exe" -Force
    
}

Function manual-install-7zip {
    ## Download 7-Zip x64 directly 
    if (-not(Test-Path -Path "$($env:Programfiles)\7-Zip\7z.exe")) { 
        Write-Host "Installing 7-Zip manually."
        Invoke-WebRequest -Uri "https://www.7-zip.org/a/7z2107-x64.exe" -OutFile "$($env:temp)\7z2107-x64.exe"
        $hash = Get-FileHash "$($env:temp)\7z2107-x64.exe"
        #$signerhash = Get-AuthenticodeSignature "$($env:temp)\7z2107-x64.exe"
        if ($hash.Hash -ne "0B461F0A0ECCFC4F39733A80D70FD1210FDD69F600FB6B657E03940A734E5FC1") { ##-or $signerhash.Status -ne "Valid") {
            Remove-Item "$($env:temp)\7z2107-x64.exe" -Force
            Write-Host "The 7-Zip download did not pass the hash or verification check."
        }
        Start-Process "$($env:temp)\7z2107-x64.exe" -ArgumentList "/S" -passthru -Wait -NoNewWindow
        Remove-Item "$($env:temp)\7z2107-x64.exe" -Force
    }
}

Function manual-uninstall-7zip {
    ## Uninstall 7-Zip directly
    Start-Process "$($env:Programfiles)\7-Zip\Uninstall.exe" -ArgumentList "/S" -passthru -Wait -NoNewWindow
}

Function choco-install-7zip {
    ## This needs more testing on a machine that has choco installed
    choco install 7zip.install -y
}

Function verify-kabuto-patch-manager-choco {
    ## Make sure the choco.exe file exists in the Syncro folder if Third Party Patch Management is enabled on this assets policy
    $sourcefile = "C:\Program Files\RepairTech\Syncro\kabuto_app_manager\kabuto_patch_manager.exe"
    $file = "C:\Program Files\RepairTech\Syncro\kabuto_app_manager\choco.exe"
    if (Test-Path -Path $sourcefile) {
        if (-not(Test-Path -Path $file)) {
            try {
                Copy-Item $sourcefile -Destination $file -Force -ErrorAction Stop
                Write-Host "The file [$file] has been copied."
            }
            catch {
                Write-Host "The file [$file] has NOT been copied. Try another way. This is usually due to no Third Party Patch Mangement enabled in this policy yet."
            }
        }
    }
}

main