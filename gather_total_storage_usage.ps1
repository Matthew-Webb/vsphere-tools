# Variables
$vcServer = "<VCTR_FQDN>"
$user = "<SERVICE_ACCOUNT>"
$pass = Get-Content "C:\<PATH>\secure-credential.txt" | ConvertTo-SecureString
$credential=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
$datestamp = Get-Date -Format "yyyyMMdd"
[int ]$totalStorage = 0

# Authenticate to Vcenter
Connect-VIServer -Server $vcServer -Protocol https -Credential $credential

$vmInventory = Get-VM -Location <VCTR_FOLDER>

# Iterate over inventory ignoring the first 2 lines
foreach ($vm in $vmInventory)
{
    if ($vm -ne 'Name'-or $vm -ne '----')
    {
    $vm | select Name, ResourcePool, UsedSpaceGB, ProvisionedSPaceGB | Export-Csv -Path "C:\<PATH>\$datestamp-individualVmStorage.csv" -Append
    $totalStorage += ($vm.UsedSpaceGB)
    $totalStorage | Out-File "C:\<PATH>\$datestamp-totalStorageGB.txt"
    }
}
