# Solution for automating Azure DB for MySQL backups for long term retention using serverless compute

This solution provides the capability to store backups of Azure DB for MySQL databases for long term retention using azure container instances.

In many cases storing database backups for long term is required for several reasons such as auditing, compliance or data archiving.

This template will deploy the resources like automation account, blob storage, managed identity and the runbook which takes the backup of mysql database and stores in a fileshare until it is deleted manually. There are few steps that you need to do after the deployment.

1. provide the managed identity with contributor access to the resource group where automation account, storage account is deployed.

2. Provide access to the MySQL instance to the container for it to take the backup of the instance.

3. Provide parameters to the runbook and execute. more on the parameters below.

Below button can be used to deploy the resources under the desired subscription.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FNaginder%2Fmysqlltr%2Fmain%2Ftemplate%2Ftemplate.json)

When the deployment is finished, perform the following steps for providing contributor access to the managed identity
1. Go to the resource group where the template was deployed
2. click on the Managed identity and on the Managed identity blade, click on azure role assignments
on the azure role assignments blade, click on add role assignment
3. in the add role assignment blade, select Resource group as the scope and select Contributor under the Role drop down.
4. Click Save

For the container to be able to access the MySQL instance there are multiple ways to allow the same.

1. You can enable "Allow access to Azure services" option under the Connection security tab however this allows all resources including other subscriptions so this should be enabled with care
2. You can also deploy the ACI into existing or new Vnet which in case can be the Vnet where MySQL (flexible server) is deployed or can be peered to the same. For single server, the ACI could be deployed into the Vnet where private link is created to allow access.
3. For single server you can deploy the ACI such that it exposes the IP externally, which can be added to the firewall of the MySQL instance 
 
After this the runbook can be executed to take the backup. Parameters are needed to execute the runbook. Following will explain each parameter and its value.

1. ACCOUNTID - This is the object(principal) ID of the Managed identity, you can find this in the Overview page of the Managed Identity
2. RGNAME - This is the resource group name where the template was deployed
3. HOSTNAME - This is the Azure DB for MySQL Hostname
4. USERNAME - Username to connect to Azure DB for MySQL Host
5. PASSWORD - Password of the above user to connect to Azure DB for MySQL Host
6. DBNAMES - Name of the database/s to backup. For more than one, provide the database names seperated by space
7. STORAGENAME - Storage account name deployed by the template
8. BACKUPFILESHARE - Fileshare name where the backup will be placed, this is created in the above storage account.

provide the above values and execute the runbook. Once the runbook finishes, it will show the status and logs from the Container instance which can be used to debug in case of any errors.

The Runbook can also be scheduled to run at certain times to ensure period backups are taken.

In case if there is a need to host the docker image in your own repo, you can use the dockerfile to build your own docker and host it in your registry.