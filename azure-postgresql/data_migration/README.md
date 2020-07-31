# Faster dump/restore
pg\_dump/pg\_restore can sometimes might not optimal approach for data migration because:
- pg\_restore has to wait until pg\_dump finishes. Can be bottlenecked on client IO.
- pg\_dump/pg\_restore cannot run in parallel across a single table. You can parallelize them across tables but a single table can be read/written only via a single threads. This can be done if the table is partitioned though.

This tool address both the above issues:
- Simultaneous reading and writing from source table
- Ability to use multi-threading to dump/restore on a single table

The tool chunks out the source table based on a watermark (id) columns and uses multiple threads to read from the source table and write into destination table. It uses COPY command in postgres for the reading and writing.

## Benefits
- Faster offline xio to pfs migrations 
- Faster offline upgrades 
- Faster offline migrations. 
- If workload is append only, help improve initial load and reduce downtime for the lag (during initial load) to be applied. 

## Usage:
```
python load_mod.py "source_connection_string" source_table "destination_connection_string" destination_table number_of_threads count_of_table
```
Ex:
```
python load_mod.py "host=test_src.postgres.database.azure.com port=5432 dbname=postgres user=test@test_src password=xxxx sslmode=require" test_table "host=test_dest.postgres.database.azure.com port=5432 dbname=postgres user=test@test_dest password=xxxx sslmode=require" test_table 8 411187501
```

## Pre-requisites/Recommendations
- sequential id column has to be present on the table.
- Index on that id column is strongly recommended because the script splits the table based on the id column. Under the covers it uses WHERE clause filters on start and end ranges of the id column based on the number of threads you specify. It splits the total count into number\_of\_threads chunks.
- Also it is recommended that the source db, client (can be azure VM) and the destination db are colocated in the same region. Switch on accelrated networking on the client.
- As data-migration migrations are not permanent, recommendation is to beefup the source db, destination db and client vm hardware.

## Sample results
-  Migrated 1.4TB table from Sterling single-server to Sterling single-server in *7 hours and 45 minutes*. Medium sized servers (16 vcores)
-  Can tweak this and make it migrate at a faster rate too - better network, more Vcores, more memory etc.
- ![Network Throughput: 10GB every 5 minutes](https://github.com/microsoft/OrcasNinjaTeam/blob/master/azure-postgresql/data_migration/image003.png) 
