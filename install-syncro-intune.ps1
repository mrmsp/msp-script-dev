## Install SyncroRMM if not already installed
if (-not(Test-Path -Path 'C:\ProgramData\Syncro\bin\Syncro.Overmind.Service.exe' -PathType Leaf)) {
    $ProgressPreference = 'SilentlyContinue' # Hide irw progress bar to boost speed
    try {
        Invoke-WebRequest -Uri https://example.com/syncro/SyncroSetup-mspname-0000000.exe -Outfile $env:temp\SyncroSetup-mspname-0000000.exe
        & $env:temp\SyncroSetup-mspname-0000000.exe --console
    } catch {
        try {
            Invoke-WebRequest -Uri https://rmm.syncromsp.com/dl/rs/xxxxxxxxxx=?policy_id=0000000  -Outfile $env:temp\SyncroSetup-mspname-0000000.exe
            & $env:temp\SyncroSetup-mspname-0000000.exe --console --customerid 111111 --policyid 0000000
        } catch {}
    }
}