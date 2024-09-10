# Variables
$vcServer = "<VCTR_FQDN>"
$credential = Get-Credential -Message "`n Provide Vsphere user and password. The value is passed as a secure string."
$user = $credential.getNetworkCredential().username
[Int]$keep = Read-Host -Prompt "How many of the most recent snapshots would you like to keep? (INT value expected)"

# Gather Environment information
$environment = New-Object System.Collections.ArrayList
[String]$gatherAll = Read-Host -Prompt "Do you want to include all environments (uat, qa01, and qa02)? [y/n]"
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
    $environment += "DCE"
}
if ($gatherAll -eq 'y' -or $gatherQa01 -eq 'y')
{
    $environment += "qa-env"
}
if ($gatherAll -eq 'y' -or $gatherQa02 -eq 'y')
{
    $environment += "qa02-east-env"
    $environment += "qa02-west-env"
}

if ($keep -ge 0 -or $keep -le 100)
{
    # Authenticate to Vcenter
    Write-Host "`n Authenticating to '$vcServer' with username '$user'..."
    Connect-VIServer -Server $vcServer -Protocol https -Credential $credential

    # Gather VM Inventory
    Write-Host "`n Folders being used to gather VM inventory: '$environment' `n"
    $vmInventory = Get-VM -Location $environment


    foreach ($vm in $vmInventory)
    {
    #Write-Host "Creating snapshot for '$vm'..."
    Get-VM -Name $vm | Get-Snapshot | Select-Object -SkipLast 2 | Remove-Snapshot -RunAsync -Confirm:$false
    }
}
else
{
    Write-Host "Requested amount of snapshots to keep is outside of the expected integer value (0-100). Requested value: '$keep'"
}
