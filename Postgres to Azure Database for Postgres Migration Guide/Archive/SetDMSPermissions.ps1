Import-Module Az.Resources

#replace with your subscription id
$subscriptionId = "{SubscriptionID}"

$readerActions = `
"Microsoft.Network/networkInterfaces/ipConfigurations/read", `
"Microsoft.DataMigration/*/read", `
"Microsoft.Resources/subscriptions/resourceGroups/read"

$writerActions = `
"Microsoft.DataMigration/services/*/write", `
"Microsoft.DataMigration/services/*/delete", `
"Microsoft.DataMigration/services/*/action", `
"Microsoft.Network/virtualNetworks/subnets/join/action", `
"Microsoft.Network/virtualNetworks/write", `
"Microsoft.Network/virtualNetworks/read", `
"Microsoft.Resources/deployments/validate/action", `
"Microsoft.Resources/deployments/*/read", `
"Microsoft.Resources/deployments/*/write"

$writerActions += $readerActions

$subScopes = ,"/subscriptions/$subscriptionId/"

function New-DmsReaderRole() {
$aRole = [Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition]::new()
$aRole.Name = "Azure Database Migration Reader"
$aRole.Description = "Lets you perform read only actions on DMS service/project/tasks."
$aRole.IsCustom = $true
$aRole.Actions = $readerActions
$aRole.NotActions = @()

$aRole.AssignableScopes = $subScopes
#Create the role
New-AzRoleDefinition -Role $aRole
}

function New-DmsContributorRole() {
$aRole = [Microsoft.Azure.Commands.Resources.Models.Authorization.PSRoleDefinition]::new()
$aRole.Name = "Azure Database Migration Contributor"
$aRole.Description = "Lets you perform CRUD actions on DMS service/project/tasks."
$aRole.IsCustom = $true
$aRole.Actions = $writerActions
$aRole.NotActions = @()

  $aRole.AssignableScopes = $subScopes
#Create the role
New-AzRoleDefinition -Role $aRole
}

function Update-DmsReaderRole() {
$aRole = Get-AzRoleDefinition "Azure Database Migration Reader"
$aRole.Actions = $readerActions
$aRole.NotActions = @()
Set-AzRoleDefinition -Role $aRole
}

function Update-DmsConributorRole() {
$aRole = Get-AzRoleDefinition "Azure Database Migration Contributor"
$aRole.Actions = $writerActions
$aRole.NotActions = @()
Set-AzRoleDefinition -Role $aRole
}

# Invoke above functions
New-DmsContributorRole
Update-DmsConributorRole