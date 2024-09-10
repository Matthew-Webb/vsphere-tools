# Variables
$vcServer = "<VCTR_FQDN>"
$user = "<SERVICE_ACCOUNT>"
$pass = Get-Content "C:\<PATH>\secure-credential.txt" | ConvertTo-SecureString
$credential=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
$snapshotName = Read-Host -Prompt "`n Provide a name to apply to the snapshots, this value is a required identifier but inconsequential"
$snapshotDescriptionUser = Read-Host -Prompt "`n Provide a brief description of the snapshots"
[String]$startDate = Get-Date
$snapshotDescriptionFull = "Batch snapshots initiated by " + $executor + " on " + $startDate + "`n" + $snapshotDescriptionUser
[String]$hostRole = "ignore"

# Authenticate to Vcenter
Write-Host "`nConnecting to VIServer...`n"
Connect-VIServer -Server $vcServer -Protocol https -Credential $credential

# Gather Environment information
$environment = New-Object System.Collections.ArrayList
[String]$gatherAll = Read-Host -Prompt "`nDo you want to include all environments (uat, qa01, and qa02)? [y/n]"
if ($gatherAll -eq 'n')
{
    [String]$gatherUat = Read-Host -Prompt "Do you want to include UAT? [y/n]"
    [String]$gatherQa01 = Read-Host -Prompt "Do you want to include QA01? [y/n]"
    [String]$gatherQa02 = Read-Host -Prompt "Do you want to include QA02? [y/n]"
}

# Setting requested enviroments
if ($gatherAll -eq 'y' -or $gatherUat -eq 'y')
{
    $environment += "DCW"
    $environment += "-DCE"
}
if ($gatherAll -eq 'y' -or $gatherQa01 -eq 'y')
{
    $environment += "qa-env"
}
if ($gatherAll -eq 'y' -or $gatherQa02 -eq 'y')
{
    $environment += "qa02-east-env"
    $environment += "qa02-east-env"
}

# Gather host role information
$input = Read-Host -Prompt "Do you want to specify a server identifier? (ie matchable FQDN text) [y/n]"
if ($input -eq 'y')
{
    [String]$role = Read-Host -Prompt "`nProvide a string that can be used to identify the servers you would like to included.`nKeep in mind the provided string will be wrapped in wildcards.`n(ie using `"apache`" would match with every server that has the string apache in it.)`nEnter `"ignore`" if you no longer wish to specify a role type"
}
# Gather VM inventory
Write-Host "`n Gathering VM inventory... `n"
$vmInventory = Get-VM -Location $environment

# Iterate over inventory ignoring the first 2 lines
foreach ($vm in $vmInventory)
{
    if ($role -eq 'ignore')
    {
        if ($vm -ne 'Name'-or $vm -ne '----')
        {
        Write-Host "Creating snapshot for '$vm'..."
        New-Snapshot -VM $vm -Name $snapshotName -Description $snapshotDescriptionFull -RunAsync
        }
    }
    else
    {
        if ($vm -ne 'Name'-or $vm -ne '----' -and $vm -like "*$role*")
        {
        Write-Host "Creating snapshot for '$vm'..."
        New-Snapshot -VM $vm -Name $snapshotName -Description $snapshotDescriptionFull -RunAsync
        }
    }
}
