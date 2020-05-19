# Index-only scans are powerful 

- If a table has a very large row width but your queries are only accessing some columns at a time, create indexes on all those columns to use index-only scans. 
- They help a lot in reducing IO by preventing full row scans – thereby helping in exponential performance gains. We have seen this to be useful for many customers. 
- After the initial loading of data, it is important to VACUUM ANALYZE the table, then only index-only scans are used. VACUUM ing the table helps refreshing the visibility map of the table. 
- Useful resources about index only scans: 
    - [Index Only Scans Postgres Wiki](https://wiki.postgresql.org/wiki/Index-only_scans)
    - [Index Only Scans Postgres Docs](https://www.postgresql.org/docs/10/indexes-index-only-scans.html)
    - [Index Only Scans are not always Index Only Scans](https://blog.dbi-services.com/an-index-only-scan-in-postgresql-is-not-always-index-only/)
    - To see whether a btree index is efficiently using its page space you can ask pgstatindex. The average leaf density is the percentage of index leaf page usage: 
    ```SELECT avg_leaf_density FROM pgstatindex('btree_index_name');```