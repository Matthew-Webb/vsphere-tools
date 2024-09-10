$credential = Get-Credential -Message "`n Provide user and password. The value never processed in plain text."
$user = $credential.getNetworkCredential().username
$path = "C:\<PATH>\" + $user + "-secure-credential.txt"

$credential.Password | ConvertFrom-SecureString | Out-File $path

$credential.GetNetworkCredential().Password
