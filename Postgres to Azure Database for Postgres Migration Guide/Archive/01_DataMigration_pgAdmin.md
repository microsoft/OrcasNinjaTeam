# Data Migration

## Setup

Follow all the steps in the [Setup](./00_Setup.md)

## Configure Server Parameters

To support the migration, set the source and target PostgreSQL instance parameters to allow for a faster egress and ingress. Follow the steps in [Server Parameters Migration](./02.03_DataMigration_ServerParams_Ingress.md).

## Data

Wth the report of the objects from the source system and the users migrated, the migration can begin. Since the target is a Azure Database for PostgreSQL running 8.0, DMS cannot be used. Therefore, the next best alternative method of an import and export with PostgreSQL pgAdmin has been selected.

### PostgreSQL pgAdmin Backup

- Switch to PostgreSQL pgAdmin
- Connect to the local PostgreSQL server
- Expand the **Databases** node
- Expand the **Schemas** node
- Select the **reg_app** schema
- In the menu, select **Tools->Backup**
- Select **Backup**, notice PostgreSQL pgAdmin makes calls to the `pg_dump` tool
- Open the newly created export script
- In PostgreSQL pgAdmin, create a new connection to the Azure Database for PostgreSQL
  - For Hostname, enter the full server DNS (ex: `servername.postgresql.database.azure.com`)
  - Enter the username (ex: `s2admin@servername`)
  - Select the **SSL** tab
  - For the SSL CA File, browse to the **BaltimoreCyberTrustRoot.crt.pem** key file
  - Select **Test Connection**, ensure the connection completes
- Select **File->Open SQL Script**
- Browse to the just created dump file, select **Open**
- Select **Execute**

## Update Applications to support SSL

- Switch to the Java Server API in Visual Studio code
- Open the **launch.json**
- Update the **DB_CONNECTION** to `jdbc:postgresql://{servername}.postgres.database.azure.com:5432/{your_database}?user=s2admin@cjg-pg-single-01&password={your_password}&sslmode=require`. 

> Note the additional `sslmode` parameter

- Add the following **env** values:

```json

```

## Revert Server Parameters

With the migration completed, you will want to revert your server parameters to support the workload. Follow the steps in [Server Parameters Reset](./02.03_DataMigration_ServerParams_Egress.md).
