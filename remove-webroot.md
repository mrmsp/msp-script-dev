Webroot Uninstall Guide
=======================

Goal
----

To remove enough remnants of webroot for other anti-virus software to install another AV. In Syncro, Bitdefender will not install if there are certain remnants of Webroot still installed. Checking the Security Center is the best way to determine if Webroot is blocking the install. Run this Powershell to see a list of registered anti-virus software: `Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct`.

The Security Center is not the only thing that will block an install. Some registry keys (citation neede) and still showing as an installed program still seem to have an effect. If you ran something in this guide that has made an impact on the uninstall, stop and run the test again to see if it has helped.

Testing
-------

Check the Security Center via the powershell script `Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct` and Apps uninstall to see if there is a change. Run the `Syncro Full Sync` script if you think one of the methods has made a change. If you don't run the `Syncro Full Sync script`, this could take 2 hours to a day to update. This takes several minutes (time check needed) to update. Refresh the Syncro webpage to see if Webroot is gone.

Procedure
=========

Remove from old RMM
-------------------

*   Deactivate Webroot from the old RMM / Webroot control panel first. I can't stress this enough to start. There is a script that you can force the polling to webroot to get those commands to uninstall quickly.
*   Run the "Webroot Poll" script for a day or a week for offline machines if needed first.

Best Removal Method
-------------------

The scripts are much less effective than any of the actual uninstall methods. Always try these first every time. 

### Uninstall from Settings

*   Uninstall from Settings. Seriously, **try this first**. 

### Uninstall from wrsa.exe

*   Look in `Program Files (x86)\Webroot` and `Program Files\Webroot` for the `WRSA.EXE` file to attempt an uninstall. If you still have the `WRSA.EXE` file this is your best bet BEFORE running any scripts as they are rarely very effective. Sometimes this will let you run `wrsa.exe -uninstall` from normal mode. Try this first in normal mode. Stop here, Reboot in safe mode and try this again next if it won't let you uninstall from normal mode as `wrsa.exe -uninstall` is the best uninstall method.

Stubborn Removals
-----------------

### Install / Uninstall from wsasme.msi

Windows installer is usually not available in safe mode. Try this in normal mode.

*   Download the wsasme.msi file using this command: `Invoke-WebRequest -URI 'https://anywhere.webrootcloudav.com/zerol/wsasme.msi' -UseBasicParsing -OutFile .\wsasme.msi`
*   Then attempt to uninstall first using: `msiexec /x wsasme.msi /qn /L*v wsasme-uninstall.log`  
    If this does not work, then attempt an install and uninstall with wsasme.msi.  
    _Note: You will need a license code to do this install. Get one from your webroot console._
*   Run: `msiexec /i wsasme.msi GUILIC=***REMOVED*** CMDLINE=SME,quiet /qn /l*v wsasme-install.log`  
    Then uninstall again: `msiexec /x wsasme.msi /qn /L*v wsasme-uninstall.log`

Windows Safe Mode Methods
-------------------------

Once in safe mode, try the uninstall from wrsa.exe. Remote control is inconvenient, especially in safe mode. On Syncro the background tools work in safe mode. Have an admin user password ready.

The safe mode script enables Syncro in safe mode and works well on ethernet connected machines. Laptops on WiFi will need to be plugged into the network before attempting a safe mode uninstall. Schedule a time with the client to have the laptop plugged into a network cable.

### Uninstall from wrsa.exe

*   Look in `Program Files (x86)\Webroot` and `Program Files\Webroot` for the `WRSA.EXE` file to attempt an uninstall. If you still have the `WRSA.EXE` file this is your best bet BEFORE running any scripts as they are rarely very effective.

### Run the script

*   Run the "Webroot Removal Script (Safe mode Required)".
*   Check the results. It will need to run several times.
*   Registry permissions will most likely prevent items from being deleted.

### Run the 2008 removal tool

*   Download the 2008 era `WRUpgradeTool.exe` from this link: `Invoke-WebRequest -URI 'http://download.webroot.com/WRUpgradeTool.exe' -UseBasicParsing -OutFile .\WRUpgradeTool.exe`
*   This tool will run from Safe or Normal mode and may help clean up. It does delete itself after running. This must be run via GUI only.

### Run WBEMTEST

*   Run this Powershell to get a list of GUIDs to remove. Do not delete any other GUID found in the next step.  
    `Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct | Where-Object {$_.displayName -like "Webroot*"}`
*   Run the Windows Management Instrumentation Tester command: `WBEMTEST.EXE`
*   Click the "Connect..." button. Enter: `root/securitycenter2`
*   Click the "Connect" button. Click the "Query..." button.
*   Enter: `SELECT * from Antivirusproduct`
*   Select the antivirus GUIDs to delete, Click the "Delete" button