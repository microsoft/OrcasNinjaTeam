# Setup Guide for Migrating a Java Oracle Application to Azure Database for PostgreSQL Sample Application
- [Setup Guide for Migrating a Java Oracle Application to Azure Database for PostgreSQL Sample Application](#setup-guide-for-migrating-a-java-oracle-application-to-azure-database-for-postgresql-sample-application)
  - [Starting Sample Application Architecture](#starting-sample-application-architecture)
  - [Oracle Database ER Diagram](#oracle-database-er-diagram)
  - [Git repo structure](#git-repo-structure)
  - [Installing the Oracle database](#installing-the-oracle-database)
    - [Add the sample blobs](#add-the-sample-blobs)
  - [Installing the Application](#installing-the-application)
    - [Make sure your local Java and Maven environmental variables are set](#make-sure-your-local-java-and-maven-environmental-variables-are-set)
    - [Set your development application runtime environment variables](#set-your-development-application-runtime-environment-variables)
    - [Test the Java API](#test-the-java-api)
  - [Installing and running the Angular application locally](#installing-and-running-the-angular-application-locally)
  - [Summary](#summary)
  - [Migrating to the Cloud](#migrating-to-the-cloud)
    - [Create and configure your Azure resources - Run the ARM template](#create-and-configure-your-azure-resources---run-the-arm-template)
    - [Capture the PostgreSQL configuration](#capture-the-postgresql-configuration)
  - [Set up your migration server and migrate the Oracle database to PostgreSQL](#set-up-your-migration-server-and-migrate-the-oracle-database-to-postgresql)
  - [Finish your Azure resource configuration](#finish-your-azure-resource-configuration)
    - [Update your secrets in Key Vault](#update-your-secrets-in-key-vault)
    - [Update your web application configuration settings with the Azure Key Vault secret values](#update-your-web-application-configuration-settings-with-the-azure-key-vault-secret-values)
  - [Deploy the Java API application to Azure](#deploy-the-java-api-application-to-azure)
  - [Deploy the Angular application to Azure](#deploy-the-angular-application-to-azure)
  - [Summary](#summary-1)
  - [Legal Disclosure](#legal-disclosure)

## Starting Sample Application Architecture
![A diagram describing the architecture.](media/2020-03-26-15-09-15.png "Sample Application Architecture")

This sample application utilizes the following frameworks and components. The reader is responsible for installing the dependencies.

1. Angular 9 front end
2. Java SE 11 JDK
3. Maven 3.6.3
4. Sprint Boot 2.2.5 RELEASE
5. Embedded Tomcat
6. Oracle 11g Express Edition
7. Azure Database for PostgreSQL 11.
8. npm 6.4.x
9. NodeJS 10.15.x
10. Angular CLI 9.1
11. PowerShell 7.1

## Oracle Database ER Diagram

This diagram provides an overview of the database table structure.

![](media/2020-03-26-15-10-27.png)

## Git repo structure

![The Git repo structure is displayed.](media/2020-04-23-16-17-24.png "Git Repo Strucutre")
## Installing the Oracle database

In order to run the sample application, you need to have access to some instance of Oracle.  This application has been tested with Oracle 11g XE. The structure is basic enough to work on most versions.  To create your own Oracle instance locally, you can download a copy of Oracle Express Edition.  Also, it is recommended to install the SQLDeveloper client tool as well.  You can use any Oracle compatible client tool of choice.  Once you have access to the database instance, follow these steps.

Create the **REG_APP** user.

>Note: If you are utilizing a server other than a local copy, this account will need elevated permissions to this database in order to properly capture schema and data information for PostgreSQL export.  If you are using a local Oracle XE copy, grant all the rights. It is recommended to use local test instance.

![Edit user image is displayed. All of the Oracle database roles are checked.](media/2020-03-26-15-05-37.png)

While connected to the REG_APP schema, run the **conferencedemo-oracle.sql** script.  This script will create all of the necessary objects and sample data for your application to run.

![SQL Developer shows the database connections.](media/2020-03-26-15-15-49.png "SQL Developer Connections")

Also, there is a SQL Loader option available as well in the repo as well. It contains the sample blobs as well.

![Git repo shows the SQL Loader import option.](media/2020-04-12-06-27-57.png "SQL Loader Option")

### Add the sample blobs

>Note: You can skip this section if you used the Oracle SQL Loader option.

The basic database schema should be created now with sample data. To update the sample speaker picture blob records, open SQL Developer.  Select the Speaker table and the **Data** tab.  The records should be displayed. The SPEAKER_PIC and SPEAKER_BIO fields will be NULL. Select the pencil icon in the record field.

![Picture shows the pencil icon is highlighted in SQL Developer database record.](media/2020-04-12-05-48-42.png "SQL Developer Pencil Icon")

Sample images for the next steps are in the **application-setup** Git folder. Any PNG image can be used.

![The sample png folder shows the speaker bio pic file is highlighted.](media/2020-04-12-06-08-15.png "Sample Bio Pic")

Next, select the **Load** button and upload an image.

![SQL Developer Load button is displayed.](media/2020-04-12-05-58-22.png "SQL Developer Load Button")

The blob fields will updated with the sample image.  Commit your changes.

![The SQL Developer database record shows the blob field is now populated.](media/2020-04-12-05-45-34.png "SQL Developer Blob Field")

## Installing the Application

### Make sure your local Java and Maven environmental variables are set

![Java and Maven environment variable reminder.](media/2020-03-26-15-18-00.png "Java Maven Environment Vars")

### Set your development application runtime environment variables

![Example of setting the debug runtime environment variables.](media/2020-03-26-15-19-58.png "Debug runtime environment vars")

- DB_CONNECTION_URL - Connection to local Oracle database.
- DB_USER_NAME - Oracle database user name.
- DB_PASSWORD - Oracle database password.
- ALLOWED_ORIGINS - e.g. http://localhost:4200  (Default Angular development URL)

>Note:  Your configuration values will be different.  The database user name should be the same.  Use strong passwords.

An alternative, would be to update your application.properties file.  Hardcoding the environment secrets in the application configuration file is not recommended as they will be saved into SCM.  Injecting the secrets at runtime via tokens is a more secure method.

![The picture shows the Java application.properties](media/2020-03-26-15-23-50.png "Java Application Properties")

Open your command line or terminal.  Run this Maven command to test your set up and configuration.

``` cmd
    mvn clean package
```

Run your Java API application.

![Example of successful Java API app message log.](media/2020-03-26-15-28-04.png "Java API Message Log")

You should see an output similar to this output.

### Test the Java API

In your browser, navigate to:  http://localhost:8888/api/v1/events.

![Sample API RESTful call to events.](media/2020-04-12-06-37-01.png "Java REST call")

## Installing and running the Angular application locally

This project requires NPM, NodeJS, and the Angular CLI to be installed.

- Install the Angular project dependencies.

``` cmd
  npm install
```

- Build and run the application.

``` cmd
  ng serve -o
```

A web landing page similar to this should be visible:

![The picture shows an example of the landing page.](media/2020-03-26-15-41-42.png "Landing Page")

## Summary

At this point, you have simulated the legacy application running on-premises and the migration process can start . The Azure target environment will need to be created. The next section of this document will guide you through these steps.

## Migrating to the Cloud

Once you have tested the sample application locally, you will need to set up the Azure resources.  The **conferencedemo-azure-psql** project contains the Java API project configured to work with the PostgreSQL database.

### Create and configure your Azure resources - Run the ARM template

- Make sure you have Powershell version 5.1 or higher. Run this command in PowerShell to determine your installed version.

  ```ps
  $PSVersionTable.PSVersion
  ```

  ![PowerShell version is displayed.](media/2020-04-22-09-22-28.png "PowerShell Version")

- You must have the Azure module installed. To install the module, run this command.
  
  ```ps
  Install-Module -Name Az -AllowClobber
  ```

- Open the Powershell **deployment.ps1** script in the ISE.

  ![The PowerShell deployment script is displayed.](media/2020-04-23-15-43-01.png "PowerShell Deployment Script")

- Change the PS console directory to the ARM template directory.

  ```cmd
  cd .\arm-template
  ```

- Log into your Azure tenant.  If you can't remember your tenant ID, then run:

  ```cmd
  Get-AzSubscription
  ```

  ![The picture shows an example of the subscriptions for this account.](media/2020-04-23-15-49-41.png "Subscription List")

- Capture the resource Location you wish to create the resources. Make sure to  create the resources in a region that supports the services.

  ![The picture shows the region locations.](media/2020-04-23-15-52-06.png "Region Locations")

- Enter your resource group name and execute only this command.  e.g. th-oracle-psql2.

  ![The script shows how to create the resource group.](media/2020-04-23-16-00-58.png "Create Resource Group")

- Create your resources. You should see prompts in the console for your template parameter values. Below is an example of a successful output screen.

  ![The picture shows the script output for creating all of the resources](media/2020-04-23-16-07-20.png)

  >Note:  This lab was tested using PostgreSQL 11.  Deploying a different version will bring different challenges.

  Once your base resources are created, create the Azure Key Vault in your resource group.

- Set up the Managed Identity. Set the **Status** to On.

  ![The picture shows the System assigned Managed Identity turned on.](media/2020-04-20-19-14-44.png "System assign Managed Identity")

- Select the **Save** button. Select **Yes**.

  ![The save confirmation message is displayed.](media/2020-04-20-19-16-55.png "Save Confirmation")

- Add Access Policy.

  ![The picture shows the Add Access Policy highlighted.](media/2020-04-20-19-23-55.png "Add Access Policy")

- Select Get and List permissions for the Secrets.
  - Select the service principal you just created.
  
  ![The picture shows the principal you just created.](media/2020-04-20-19-22-37.png "Service Principal")

- Select the Add button.

  ![The picture shows the Add access policy configuration.](media/2020-04-20-19-26-33.png "Add Access Policy") 

- Create your secrets. Select Get and List options.  

  - **yourdept-regapp-db-connectionurl** - Connection URL to PostgreSQL database.
  - **yourdept-regapp-db-username** - PostgreSQL database admin user name.
  - **yourdept-regapp-db-password** - PostgreSQL database password.
  
  ![The picture shows the create secret screen.](media/2020-04-20-19-31-31.png "Create Secret")

### Capture the PostgreSQL configuration

- Navigate to the PostgreSQL server resource.  Select the **Overview** link.  

  ![The picture shows the PostgreSQL overview panel.](media/2020-03-26-15-50-35.png "PostgreSQL Overview")

- Set up your Firewall rules.  
  
  If you have a migration server VM that gets shut down at some point, you will have to edit the firewall rules every time you want to connect because you get a new IP address every time you start the VM.  On-premises development environments with test data may be ok with opening the firewall.  It is better to start off as secure as possible.

  0.0.0.0 to 255.255.255.255, **DO NOT USE THIS IP ADDRESS SETTING** if you have ***sensitive protected*** data in this database. It does not matter if it is test data.

  ![PostgreSQL firewall configuration is displayed.](media/2020-03-26-15-52-49.png "Firewall Configuration")

## Set up your migration server and migrate the Oracle database to PostgreSQL

The basic tasks of migration have been listed below.  The task details have been discussed in the *A Guide to Migrating a Java Oracle Application to Azure Database for PostgreSQL* Word document.

- Navigate to your migration server. It can be a VM or your local machine.
- Install the ora2pg utility.
- Make sure the Oracle server or client libraries are installed.
- Install the pgAdmin utility.
- Create a migration user login. Grant access.
- Create the **reg_app** schema in pgAdmin. Grant access to the migration user.
- Create a ora2pg project structure and migrate the database.
  - Configure a conf file to point to the Oracle and PG reg_app schema.
  - Export the Oracle table schema.
  - Run the ora2pg COPY command to migrate the data.
  - Export the rest of the Oracle schema objects and migrate them to the PostgreSQL database.
  - Update the procedure code to call the **reg_app** schema.
  - Update the procedures to work in PostgreSQL PL/pgSQL.

    ![The picture shows an example of a PostgreSQL function that needs to be converted.](media/2020-04-12-17-04-41.png "PostgreSQL Function Conversion")
  
The PostgreSQL database should be ready to test using the application.

## Finish your Azure resource configuration

### Update your secrets in Key Vault

- Navigate to the Azure Key Vault.

- Select the Secrets link.
  
  These secrets will be injected into the Java application upon initialization.

  ![Key Vault list is displayed.](media/2020-03-26-15-55-13.png "Azure Key Vault List")

  >Note: To create a new version of the password secret, select the **New Version** button.
    
  ![The picture shows an example of the password change screen.](media/2020-03-26-15-58-16.png "Password Update")

### Update your web application configuration settings with the Azure Key Vault secret values

- Make sure your Java API web application has access to your Key Vault. You will need to set up a policy. Adhere to the policy of least privilege by granting only Get, List, and Decrypt access.

  ![Reminder to set up the Access policy for the Java API.](media/2020-04-19-11-55-46.png "Access Policy")

- Capture the Secret Identifier for each of the parameters.
  - Select the parameter.  Select the Current Version.
  - Copy the Secret Identifier URL.

  ![Example of capturing the secret URL.](media/2020-04-12-09-54-05.png "Secret URL")

- Wrap the secrets with:
@Microsoft.KeyVault(SecretUri=[Secret Identifier URL]).  See the example below.

  ![The picture shows how to wrap the secret URL.](media/2020-04-12-09-57-53.png "Wrap Secret URL")

- Update your web configuration for DB_CONNECTION_URL, DB_USER_NAME, and DB_PASSWORD parameters.

  ![Update the Java API application with the environmental variables for the application.](media/2020-03-26-16-00-59.png "Set the Java API App Environment Variables")

  Your updated Application settings should look similar to this:

  ![The picture shows the Application Configuration settings.](media/2020-04-12-17-50-45.png "Application Settings")

- Next, add your Angular web site URL to the ALLOWED_ORIGINS application setting. This setting will prevent CORS errors. The Angular web site URL can be located in the conferencedemo-client web site overview.

  >Note: Do not include a trailing backslash.

  ![Add the ALLOWED_ORIGINS value to the Application Configuration Setting.](media/2020-04-12-19-22-40.png "Allowed Origins Configuration")

## Deploy the Java API application to Azure

Update the **conferencedemo-azure-psql** project to point to your deployed Azure resources.

- Update the pom.xml file in your Maven project.
  - Update the **subscriptionId** with the subscription id you ran the ARM template against.
  - Update the **resourceGroup** with the resource group name.
  - Update the **appName** with the Java API App web site name.
  - Update the **region** with the same region on the Java App API web site is deployed in.
  
  ![Example of the POM.xml file.](media/2020-04-12-10-41-41.png "POM File")

  ```cmd
  rem ## Create the JAR.
  mvn clean package
  ```

  ```cmd
  rem ## Deploy to Azure.
  mvn azure-webapp:deploy
  ```

  Example of a valid deployment messages from the console.

  ![Example of a valid deployment messages from the console.](media/2020-04-12-11-24-43.png "Deployment Messages")

- Test your deployment by calling an endpoint. e.g. http://[your java api url]/api/v1/events.
  
  ![The picture shows an example of the Java API Application RESTFul call.](media/2020-04-12-11-26-53.png "Java API REST Call")

- Check your Azure web site logs

  ![The picture shows the menu for opening the logs.](media/2020-04-12-11-33-03.png "Opening Logs")

  There should be Hibernate calls logged in the Azure web site logs. Use these entries for debugging purposes.

  ![Example of the Java API application logs.  Shows the Hibernate calls.](media/2020-04-12-11-36-50.png "Hibernate Calls")

  More advanced logging can be found by selecting the Advanced Tools link.

  ![The picture shows a link the Advanced Tools.](media/2020-04-12-12-34-50.png "Advanced Tools Link")

## Deploy the Angular application to Azure

Once your know your Java API URL, it is time to update your Angular application production configuration.

- Navigate to the **environment.prod.ts** file and update the webApiUrl with the API root URL.  Do not include the ending backslash.

  ![The picture shows how to update the Angular production URL.](media/2020-04-12-17-15-27.png "Update the production URL")

- At the terminal console, build your Angular application using the production settings.

  ```cmd
  ng build --configuration=production
  ```

  ![The picture shows the build configuration call and the log messages.](media/2020-04-12-17-18-44.png "Build Call Log")

- Navigate to the Azure conferencedemo-client web site. Under **Development Tools**, select **Advanced Tools** in the left panel.
- Open the Debug console using the **CMD**. Drag the Angular dist folder contents from the Windows Explorer into the site root.
  
  ![The picture shows how to open the command console.](media/2020-04-12-17-22-52.png "Command Console")

- Test your migrated web site. Navigate to the Angular web site URL.

  ![The picture shows an example of the landing page once you have configured everything.](media/2020-04-13-08-45-44.png "Landing Page Example")

## Summary

At this point, the legacy application environment has been completely migrated to the Azure Cloud Hosted environment.

Delete your resource group when you are done.

## Legal Disclosure

Information in this document, including URL and other Internet Web site references, is subject to change without notice. Unless otherwise noted, the example companies, organizations, products, domain names, e-mail addresses, logos, people, places, and events depicted herein are fictitious, and no association with any real company, organization, product, domain name, e-mail address, logo, person, place or event is intended or should be inferred. Complying with all applicable copyright laws is the responsibility of the user. Without limiting the rights under copyright, no part of this document may be reproduced, stored in or introduced into a retrieval system, or transmitted in any form or by any means (electronic, mechanical, photocopying, recording, or otherwise), or for any purpose, without the express written permission of Microsoft Corporation.

Microsoft may have patents, patent applications, trademarks, copyrights, or other intellectual property rights covering subject matter in this document. Except as expressly provided in any written license agreement from Microsoft, the furnishing of this document does not give you any license to these patents, trademarks, copyrights, or other intellectual property.

The names of manufacturers, products, or URLs are provided for informational purposes only and Microsoft makes no representations and warranties, either expressed, implied, or statutory, regarding these manufacturers or the use of the products with any Microsoft technologies. The inclusion of a manufacturer or product does not imply endorsement of Microsoft of the manufacturer or product. Links may be provided to third party sites. Such sites are not under the control of Microsoft and Microsoft is not responsible for the contents of any linked site or any link contained in a linked site, or any changes or updates to such sites. Microsoft is not responsible for webcasting or any other form of transmission received from any linked site. Microsoft is providing these links to you only as a convenience, adnd the inclusion of any link does not imply endorsement of Microsoft of the site or the products contained therein.

© 2020 Microsoft Corporation. All rights reserved.

Microsoft and the trademarks listed at <https://www.microsoft.com/en-us/legal/intellectualproperty/Trademarks/Usage/General.aspx> are trademarks of the Microsoft group of companies. All other trademarks are property of their respective owners.