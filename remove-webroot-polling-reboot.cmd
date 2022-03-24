REM https://community.webroot.com/webroot-business-endpoint-protection-20/agent-uninstall-command-from-console-not-working-342910
echo "Checking for Webroot"
if exist "%ProgramFiles(x86)%\Webroot\wrsa.exe" (echo "Webroot found x86 & rebooting" && shutdown /r /t 300 && "%ProgramFiles(x86)%\Webroot\wrsa.exe" -uninstall && "%ProgramFiles(x86)%\Webroot\wrsa.exe" -poll )
if exist "%ProgramFiles%\Webroot\wrsa.exe" (echo "Webroot found & rebooting" && shutdown /r /t 300 &&  "%ProgramFiles%\Webroot\wrsa.exe" -uninstall &&  "%ProgramFiles%\Webroot\wrsa.exe" -poll )