# Variables
$vcServer = "<VCTR_FQDN>"
$user = "<SERVICE_ACCOUNT>"
$pass = Get-Content "C:\<PATH>\secure-credential.txt" | ConvertTo-SecureString
$credential=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
$datestamp = Get-Date -Format "yyyyMMdd"
$snapshotName = "nightly lab snapshots " + $datestamp
$snapshotDescription = "Automated snapshots initiated on <EVENT_MANAGER_HOST> starting at:`n" + $(Get-Date)

# Authenticate to Vcenter
Connect-VIServer -Server $vcServer -Protocol https -Credential $credential

# Gather VM Inventory
$vmInventory = Get-VM -Location <VCTR_FOLDER> | Where { $_.Name -notlike "<EXCLUDE_THIS>*" -or $_.Name -notlike "<EXCLUDE_THIS>*"}

# Iterate over inventory
foreach ($vm in $vmInventory)
{
    # Gather all snapshots from $vm
    $snapshots = Get-Snapshot $vm | Sort Created

    # Remove manual snapshots older than 4 weeks
    $snapshots | Where { $_.Name -notlike "nightly lab snapshots*" -and $_.Name -notlike "Baseline*" } | Where { $_.Created -lt (Get-Date).AddDays(-28) } | Remove-Snapshot -Confirm:$false

    # Gather inventory of only nightly snapshots
    $nightly = $snapshots | Where { $_.Name -like "nightly lab snapshots*" -or $_.Name -like "Baseline*" }

    # Create new Baseline if none exists
    if (-not ($nightly -match "Baseline*"))
    {
        $vm | Select Name, PoweredOn | Out-File "C:\<PATH>\$datestamp-NoBaseline.txt" -Append
        $nightly[0] | Set-Snapshot -Name "Baseline $datestamp"
        Start-Sleep -Seconds 10
        $nightly = Get-Snapshot $vm | Where { $_.Name -like "nightly lab snapshots*" -or $_.Name -like "Baseline"} | Sort Created
    }
    # Move basline if nightly are getting too big
    elseif ($nightly[1].SizeGB -gt '5' )
    {
        $nightly[1] | Select VM, Name, SizeMB | Export-Csv -Path "C:\<PATH>\$datestamp-TooBig.csv" -Append
        $nightly[1] | Set-Snapshot -Name "Baseline $datestamp"
        $nightly[0] | Remove-Snapshot -Confirm:$false
        $nightly = Get-Snapshot $vm | Where { $_.Name -like "nightly lab snapshots*" -or $_.Name -like "Baseline"} | Sort Created
    }
    else
    {
        # If there are multiple Baseline, only keep the newest
        $nightly | Where { $_.Name -like "Baseline*" } | Select -SkipLast 1 | Remove-Snapshot -Confirm:$false
    }
        
    # Remove nightly snapshots
    $nightly | Where { $_.Name -like "nightly lab snapshots*" } | Select -SkipLast 2 | Remove-Snapshot -Confirm:$false

    # Create nightly snapshot
    New-Snapshot -VM $vm -Name $snapshotName -Description $snapshotDescription | Export-Csv -Path "C:\<PATH>\$datestamp-uat.csv" -Append
}
