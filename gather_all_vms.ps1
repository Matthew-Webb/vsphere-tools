# Variables
$vcServer = "<VCTR_FQDN>"
$user = "<USER_NAME>"
$pass = Get-Content "<C:\PATH\secure-credential.txt>" | ConvertTo-SecureString
$credential=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
$path = "C:\<LOG_PATH>"

# Authenticate to Vcenter
Write-Host "`n Authenticating to '$vcServer' with username '$user'..."
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Connect-VIServer -Server $vcServer -Protocol https -Credential $credential

##################################
### VIRTUAL MACHINE PROCESSING ###
##################################

# Create/Empty Files
Write-Host "`n----- Creating and/or Emptying VM output files. -----"
New-Item -ItemType "file" -Path "$path\vms.csv" -Force

# Gather VM Inventory
Write-Host "`n----- Gathering VM inventory... -----`n"
$vmInventory = Get-VM -Location <VCENTER_LOCATIONS_COMMA_SEPARATED> | sort name

$vmInventory | Select * | Export-Csv -Path "$path\vms_all.csv"
