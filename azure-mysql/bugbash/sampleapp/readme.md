# Instruction to run this app

  

##  Create a sample database

1. Find OrcasNinjaTeam/azure-mysql/bugbash/hatest/weather.sql file

2. At MySQL Workbench, run weather.sql to create ‘weather’ database with ‘weatherhistory’ table

  

## Deploy a function app to Azure

1. At VSCode, Open OrcasNinjaTem/azure-mysql/bugbash/hatest
2. Install Azure Functions extension if not yet installed,
3. Click ‘Azure’ extension then click ‘publish’ Icon located next to ‘FUNCTIONS’
4. Select your Azure subscription from the list
5. Select ‘Create a new function app in Azure (advanced)…’
6. Enter global unique function name
7. Select ‘.NET Core 5.0’ from the dropdown list
8. Select ‘Linux’ from the dropdown list
9. Select ‘Consumption’ from the dropdown list
10. Select ‘Create new resource group’ and enter a resource group name
11. Select ‘Create new storage account’ and enter a account name
12. Select ‘Create new Application Insights resource’ and enter a resource name
13. Select location to deploy (same region as the Flex server)
14. Wait until the deployment is completed

  

## Configure a function app
1. Go to Azure portal
2. Go to the new function app that created above
3. Go to ‘Configuration’ at the left pane
4. Add those three App settings entry
          HOST_NAME: copy from the flex server connection string
          UID: admin user of the flex server
          DBPWD: password of admin user

  ## Monitor the app
1. At Azure portal, go to the function app then ‘Log stream’
2. Make sure you see this message in every five seconds

    2021-05-19T08:09:53Z [Information] Executed 'Functions.mnDBaccess5' (Succeeded, Id=0b092b87-e90a-4c20-b64a-b61604452423, Duration=2061ms)

