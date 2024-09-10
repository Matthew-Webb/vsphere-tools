# Variables
$vcServer = "<VCTR_FQDN>"
$credential = Get-Credential -Message "`n Provide Vsphere user and password. The value is passed as a secure string."
$user = $credential.getNetworkCredential().username
$path = "C:\Users\$user\Desktop"

# Authenticate to Vcenter
Write-Host "`n Authenticating to '$vcServer' with username '$user'..."
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-VIServer -Server $vcServer -Protocol https -Credential $credential

##################################
### VIRTUAL MACHINE PROCESSING ###
##################################

# Create/Empty Files
Write-Host "`n----- Creating and/or Emptying VM output files. -----"
New-Item -ItemType "file" -Path "$path\taggedVms.csv" -Force
New-Item -ItemType "file" -Path "$path\taglessVMs.csv" -Force

# Gather VM Inventory
Write-Host "`n----- Gathering VM inventory... -----`n"
$vmInventory = Get-VM -Location <VCENTER_FOLDER_NAMES> | sort name

# Define variables to show progress
$vmTotal = $vmInventory | Measure-Object -Line | select -ExpandProperty Lines
[Int]$vmCount=0

# Iterate over inventory ignoring the first 2 lines
Write-Host "`n----- Creating a CSV list of VMs with tags, this will take a few minutes. ----- `n"
foreach ($vm in $vmInventory)
{
    if ($vm -ne 'Name'-or $vm -ne '----')
    {
        $vmCount++
        Get-TagAssignment $vm | Select Entity, Tag, Uid | Export-CSV -Path "$path\taggedVms.csv" -Append
        Write-Host "$vmCount/$vmTotal"
    }
}

Write-Host "`n ----- File saved to $path\taggedVms.csv -----"



# Check for any VM that doesn't have tags.
$listTaggedVms = Import-CSV "$path\taggedVms.csv" | select Entity -ExpandProperty Entity | sort Entity -Unique
$vmTemp = Compare-Object $listTaggedVms $vmInventory | select -ExpandProperty InputObject | select Name, ResourcePool
$vmtemp | Select *,@{Name='Owner';Expression={'<UNIFIED_OWNER>'}},@{Name='Team Name';Expression={'<TEAM_ABBREVIATION>'}},@{Name='Project';Expression={'<PROJECT_NAME>'}} | Export-CSV -Path "$path\taglessVMs.csv" -Append
Write-Host "`n ----- List of tagless machines written to file: $path\taglessVMs.csv -----"

###########################
### TEMPLATE PROCESSING ###
###########################

# Create/Empty Files
Write-Host "`n----- Creating and/or Emptying Template output files. -----"
New-Item -ItemType "file" -Path "$path\taggedTemplates.csv" -Force
New-Item -ItemType "file" -Path "$path\taglessTemplates.csv" -Force

# Gather Template Inventory
Write-Host "`n----- Gathering Template inventory... -----"
$templateInventory = Get-Template -Location <VCENTER_FOLDER_NAMES>

# Define variables to show progress
$templateTotal = $templateInventory | Measure-Object -Line | select -ExpandProperty Lines
[Int]$templateCount=0

# Iterate over inventory ignoring the first 2 lines
Write-Host "`n----- Creating a CSV list of Templates with tags. -----`n"
foreach ($template in $templateInventory)
{
    if ($template -ne 'Name'-or $template -ne '----')
    {
        $templateCount++
        Get-TagAssignment $template | Select Entity, Tag, Uid | Export-CSV -Path "$path\taggedTemplates.csv" -Append
        Write-Host "$templateCount/$templateTotal"

    }
}

Write-Host "`n ----- File saved to $path\taggedTemplates.csv -----"

# Check for any Template that doesn't have tags.
$listTaggedTemplates = Import-CSV "$path\taggedTemplates.csv" | sort Entity -Unique | Select -Property @{Name='Name';Expression={$_.Entity}}
$taglessTemplates = Compare-Object -ReferenceObject $listTaggedTemplates -DifferenceObject ($templateInventory | sort Name -Unique) -Property Name | Select -ExpandProperty Name
foreach ($tem in $taglessTemplates)
{
    $temDups = Get-Template $tem
    
    foreach ($item in $temDups)
    {  
        if ($item -ne 'Name' -or $item -ne '----')
        {
            switch ($item.FolderId)
            {
                Folder-group-v53791 # UAT-DCW
                {
                $item | Select *,@{Name='Location';Expression={'<VCTR_FOLDER>/Templates'}},@{Name='Owner';Expression={'<OWNER>'}},@{Name='Team Name';Expression={'<USEFUL_TAG>'}},@{Name='Project';Expression={'<PROJECT_NAME>'}} | Select Name, Location, Owner, "Team Name", Project | Export-CSV -Path "$path\taglessTemplates.csv" -Append
                }
                Folder-group-v54222 # UAT-DCE
                {
                Write-Host "$item alread exists in another location, ignoring this duplicate." # Ignoring the UAT-DCW templates that exist in both UAT DCE/DCW 
                }
                Folder-group-v79239 # QA01
                {
                $item | Select *,@{Name='Location';Expression={'<VCTR_FOLDER>/Templates'}},@{Name='Owner';Expression={'<OWNER>'}},@{Name='Team Name';Expression={'<USEFUL_TAG>'}},@{Name='Project';Expression={'<PROJECT_NAME>'}} | Select Name, Location, Owner, "Team Name", Project | Export-CSV -Path "$path\taglessTemplates.csv" -Append
                }
                Folder-group-v73728 # QA02 DCE
                {
                $item | Select *,@{Name='Location';Expression={'<VCTR_FOLDER>/Templates'}},@{Name='Owner';Expression={'<OWNER>'}},@{Name='Team Name';Expression={'<USEFUL_TAG>'}},@{Name='Project';Expression={'<PROJECT_NAME>'}} | Select Name, Location, Owner, "Team Name", Project | Export-CSV -Path "$path\taglessTemplates.csv" -Append
                }
                Default{Write-Host "No environment found for $item $_"}
            }#>
        }
    }        
}

Write-Host "`n ----- List of tagless templates written to file: $path\taglessTemplates.csv -----"
