 
# Login to Azure Account and set the Tenant
Connect-AzAccount -TenantId "9c37bff0-cd20-49a7-b4d4-cf005991fcf6"

# List out your subscriptions.  In case you have trouble locating your tenant ID.
#Get-AzSubscription

# List resource locations. Refresher on location ID.
Get-AzLocation | Format-Table Location, DisplayName -AutoSize

# Create the resource group.
$PSResourceGroup = New-AzResourceGroup -Name "th-oracle-psql2" -Location westus

# You can point to local file or a Git repo.
$GitPath = '.'

New-AzResourceGroupDeployment -ResourceGroupName $PSResourceGroup.ResourceGroupName -TemplateFile "$GitPath\template.json" -Debug