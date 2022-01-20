Param(
    [Parameter(Mandatory=$true)]
    [String] $AccountID,
    [Parameter(Mandatory = $true)]
    [String] $rgname,
    [Parameter(Mandatory = $true)]
    [String] $hostname,
    [Parameter(Mandatory = $true)]
    [String] $username,
    [Parameter(Mandatory = $true)]
    [String] $password,
	[Parameter(Mandatory = $true)]
    [String] $dbnames,
    [Parameter(Mandatory = $true)]
    [String] $storagename,
    [Parameter(Mandatory = $true)]
    [String] $backupfileshare  
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

#get the managed identity
# Connect to Azure with user-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $AccountID).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

Write-Output "Successfully connected with Automation account's Managed Identity"  

$datetimestr=get-date -format "yyyyMMddhhmmss"
$filename="--result-file=/data/backups/dumps"+$datetimestr+".sql"
$h1 = "--host="+$hostname
$user = "--user="+$username
$pwd = "--password="+$password
$dbnamearray = $dbnames.split(" ")

$cmd = "mysqldump","--opt","--single-transaction",$h1,$user,$pwd,$filename,"--databases"

foreach ($names in $dbnamearray)
{
    $cmd+=$names

}

#get storage keys
$storagekey=((Get-AzStorageAccountKey -ResourceGroupName $rgname -AccountName $storagename) | Where-object {$_.KeyName -eq "Key1"}).value
#create mount object as backup volume in container
$volumemount=New-AzContainerInstanceVolumeMountObject -Name "backups" -MountPath "/data/backups/" -ReadOnly $false
#create new volume on the mount object from the azure fileshare
$volume=New-AzContainerGroupVolumeObject -Name "backups" -AzureFileShareName $backupfileshare `
        -AzureFileStorageAccountName $storagename `
        -AzureFileStorageAccountKey (ConvertTo-SecureString $storagekey -AsPlainText -Force)
#create container object
$container = New-AzContainerInstanceObject -Name mysqldumpci1 -Image schnitzler/mysqldump -VolumeMount $volumemount `
            -Command $cmd
#deploy the container in azure container groups
Write-Output "creating container"
$containergroup=New-AzContainerGroup -ResourceGroupName $rgname -Name mysqldumpci1  -Location eastus -Container $container -Volume $volume `
            -RestartPolicy Never -OSType Linux 

while ($true)
{
	$status=(get-azcontainergroup -name mysqldumpci1 -resourcegroupname $rgname | select-object -property @{name="Status";expression={$_.InstanceViewState}}).Status
	if ($status -eq "Failed")
	{
		Write-Output "Container in Failed State, Please check the logs below"
		Break
	}
	elseif(($status -eq "Stopped")  -or ($status -eq "Succeeded"))
	{
		Write-Output "Container execution is done, Please check the logs below"
		Break
	}
	else
	{
		Write-Output $status
        start-sleep -seconds 30
	}
}

Get-AzContainerInstanceLog -ContainerGroupName mysqldumpci1 -ContainerName mysqldumpci1 -ResourceGroupName $rgname | Write-Output

#stop container after backup
Write-Output "stopping container"
Stop-AzContainerGroup -Name mysqldumpci1 -ResourceGroupName $rgname

#remove container

