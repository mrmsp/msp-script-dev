🖨 Printers - Clear Queue
powershell “Stop-Service spooler -Force; $files = Get-ChildItem -Path $env:SystemRoot\System32\spool\PRINTERS -Force; $files | Remove-Item -Force; Start-Service spooler; [System.Reflection.Assembly]::LoadWithPartialName(‘System.Windows.Forms’);  [System.Windows.Forms.Messagebox]::Show(‘Print queue cleared!’)"

🖨 Printers - Control Panel
control printers

🕸 Browsers - Force Close all
powershell "Stop-Process -processname chrome,iexplore,firefox,msedge;Start-Sleep -Second 3;Remove-Item "$ENV:HOMEDRIVE\Users\*\AppData\Local\Google\Chrome\Userda~1\Default\Sessions" -Recurse -Force;Remove-Item "$ENV:HOMEDRIVE\Users\*\AppData\Local\Microsoft\Edge\Userda~1\Default\Sessions" -Recurse -Force;Remove-Item "$ENV:HOMEDRIVE\Users\*\AppData\Roaming\Mozilla\Firefox\Profiles\*\sessionstore-backups\recovery.jsonlz4" -Force;[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms');[System.Windows.Forms.Messagebox]::Show('Browsers closed!')"

👨‍👩‍👧‍👦 Teams - Clear cache
powershell.exe -command "Get-Process Teams | stop-process -force; Start-Sleep -Milliseconds 1500; Remove-Item -path $env:APPDATA'\Microsoft\teams\Cache\*'; Remove-Item -path $env:APPDATA'\Microsoft\teams\blob_storage\*'; Remove-Item -path $env:APPDATA'\Microsoft\teams\databases\*'; Remove-Item -path $env:APPDATA'\Microsoft\teams\GPUcache\*'; Remove-Item -path $env:APPDATA'\Microsoft\teams\IndexedDB\*' -recurse; Remove-Item -path $env:APPDATA'\Microsoft\teams\Local Storage\*' -recurse; Remove-Item -path $env:APPDATA'\Microsoft\teams\tmp\*'; Start-Sleep -Milliseconds 1500; Start-Process -FilePath $env:LOCALAPPDATA'\Microsoft\Teams\Update.exe' -ArgumentList '-processStart Teams.exe'"