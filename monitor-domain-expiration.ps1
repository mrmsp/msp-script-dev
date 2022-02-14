$minCertAge = 80
$timeoutMs = 10000
$sites = @(
    "https://google.com",
    "https://bing.com",
    "https://yahoo.com"
)
# Disable certificate validation
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
foreach ($site in $sites) {
    Write-Host Check $site -f Green
    $req = [Net.HttpWebRequest]::Create($site)
    $req.Timeout = $timeoutMs
    try { $req.GetResponse() | Out-Null } catch { Write-Host URL check error $site`: $_ -f Red }
    $expDate = $req.ServicePoint.Certificate.GetExpirationDateString()
    $expDate = $expDate.Substring(0, $expDate.IndexOf(' ')) #strip off the time
    Write-Host $expDate
    ##                                               4/10/2022 10:33:15 PM
    #$certExpDate = [datetime]::ParseExact($expDate, "d/M/yyyy HH:mm:ss", $null)
    $certExpDate = [datetime]::ParseExact($expDate, "d", $null)
    [int]$certExpiresIn = ($certExpDate - $(get-date)).Days
    $certName = $req.ServicePoint.Certificate.GetName()
    $certThumbprint = $req.ServicePoint.Certificate.GetCertHashString()
    $certEffectiveDate = $req.ServicePoint.Certificate.GetEffectiveDateString()
    $certIssuer = $req.ServicePoint.Certificate.GetIssuerName()
    if ($certExpiresIn -gt $minCertAge)
    { Write-Host The $site certificate expires in $certExpiresIn days [$certExpDate] -f Green }
    else {
        $message = "The $site certificate expires in $certExpiresIn days"
        $messagetitle = "Renew certificate"
        Write-Host $message [$certExpDate]. Details:`n`nCert name: $certName`Cert thumbprint: $certThumbprint`nCert effective date: $certEffectiveDate`nCert issuer: $certIssuer -f Red
        #Displays a pop-up notification and sends an email to the administrator
        #ShowNotification $messagetitle $message
        # Send-MailMessage -From powershell@woshub.com -To admin@woshub.com -Subject $messagetitle -body $message -SmtpServer gwsmtp.woshub.com -Encoding UTF8
    }
    write-host "________________" `n
}