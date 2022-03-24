# Development Scripts

Do not rely on these scripts staying here. Once finished they will be moved to a more stable repository.

- Ninja agentRemoval.ps1 - Default script from Ninja. No changes.
- diagnose-disk-controller-alerts.ps1 - Script to help determine which drive is listed in a Sycnro error like \Device\Harddisk2\DR2
- install-syncro-intune.ps1 - Micrsoft Intune Endpoint Syncro install script template with failover URL support
- ip-scanner.ps1 - LAN IP scanner. TODO add Syncro network pull to make it run without input
- monitor-domain-expiration.ps1 - TODO Needs complete rewrite and pull domains from Syncro for automation
- remove-webroot.ps1 - Safe Mode webroot removal script. Use with wbemtest for final step. TODO cleanup script.
- remove-webroot.md - Aims to be the definitive guide to removing Webroot.
- remove-webroot-polling.cmd - A script to run agressively (every 15 min) while you are decommissioning Webroot. It forces Webroot to check in with the cloud more often to initiate an uninstall. 
- remove-webroot-polling-reboot.cmd - An even more agressive polling script as it adds a reboot. Run every 15 min during a maintenance window and let it reboot as much as needed.
- safe-mode-f8-reboot.ps1 - Safe mode reboot script. Automatically reverts to normal mode after 15 minutes in case you cannot connect. Includes the ability to enable F8 start in safe mode like Windows 7.
- tray-one-line-scripts.ps1 - One liner scripts to add to Syncro tray icon.
- uninstall-mcafee.ps1 - Downloads the mcafee uninstaller directly and runs it. TODO working but needs cleaned up.
- veeam-backup-monitoring.ps1 - Monitors the event log for veeam success or errors and stores them in an asset custom field. Creates an alert on error or missing backups.
- vpn-l2tp-user-config.ps1 - Adds LT2P VPN connection still used with Unifi. TODO clean up and pull creds from Syncro. Has interesting scheduled task to add user creds. This trick can be adapted to other things like mapping network drives.