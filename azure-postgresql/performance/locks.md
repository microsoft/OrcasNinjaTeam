# Locks in PostgreSQL - How to identify and solve performance issues because of locking?

Queries waiting to acquire locks for longer than acceptable time can cause performance issues. Some common scenarios for that include:
- Concurent transactions with trying to DELETE/UPDATE same rows.
- DDL operations (ALTER TABLE) running for long time can block other queries. They take write exclusive lock.

## How to capture locking issues:
- [Queries to capture locks](https://wiki.postgresql.org/wiki/Lock_Monitoring)
- [Log Locks] (https://pganalyze.com/blog/postgresql-log-monitoring-101-deadlocks-checkpoints-blocked-queries)
- [Capture Query Wait Stats](https://docs.microsoft.com/en-us/azure/postgresql/tutorial-monitor-and-tune)

##  Fix locking issues:

