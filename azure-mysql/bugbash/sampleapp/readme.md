# Instruction to run this app

  

##  Create a sample database

1. In the local repo that you cloned, find OrcasNinjaTeam/azure-mysql/bugbash/sampleapp/weather.sql file

2. At MySQL Workbench, run weather.sql to create ‘weather’ database with ‘weatherhistory’ table at the flex server you created.

  

## Deploy a function app to Azure

1. At VSCode, click 'Open Folder...' then select OrcasNinjaTem/azure-mysql/bugbash/sampleapp
2. Install Azure Functions extension if not yet installed,
3. Click Azure extenstion icon at left pane.
4. Sign in to Azure, if not done yet
5. Click ‘Azure’ extension icon at left pane then click ‘Deploy to Function App’ Icon located next to ‘FUNCTIONS’
6. Select your Azure subscription from the list
7. Select ‘Create a new function app in Azure... advanced’ This is the second one from top.
8. Enter global unique function name
9. Select ‘.NET 5(non-LTS)’ from the dropdown list
10. Select ‘Windows’ from the dropdown list
11. Select ‘App Service Plan’ from the dropdown list
12. Select 'Create a new App service Plan' from the dropdown list and enter new name
13. Select 'F1' pricing tier
14. Select ‘Create new resource group’ and enter a resource group name
15. Select ‘Create new storage account’ and enter a account name
16. Select ‘Create new Application Insights resource’ and enter a resource name
17. Select location to deploy (same region as the Flex server)
18. Wait until the deployment is completed

> If you keep having issues of deploying the app, provision an empty Windows 10 VM in Azure and run the steps above in there. Make sure to install all components in the prerequisite section of the [bug bash document](https://microsoft.sharepoint.com/:w:/t/orcasql/EbdAfP2VvBtJq-uD5HrPDnkB9PmKNAOuAyPfs8BabRFv3A?e=qF8IiY).

## Configure a function app
1. Go to Azure portal
2. Open the new function app that created above
3. Go to ‘Configuration’ at the left pane
4. Add those three App settings entry\
     <strong>HOST_NAME:</strong> copy from the flex server connection string\
     <strong>UID:</strong> admin user of the flex server\
     <strong>DBPWD:</strong> password of admin user\

## Monitor the app
1. At Azure portal, go to the function app then, open ‘Log stream’ from left pane
2. Make sure you see this message in every five seconds. This is the normal state.

    2021-05-19T08:09:53Z [Information] Executed 'Functions.mnDBaccess5' (Succeeded, Id=0b092b87-e90a-4c20-b64a-b61604452423, Duration=2061ms)
3. During the failover operation, you'll see error messages like this a few times. After that it should go back to normal state.
    
    The MySQL server is running with the --read-only option so it cannot execute this statement  at: 5/19/2021 7:36:25 PM

