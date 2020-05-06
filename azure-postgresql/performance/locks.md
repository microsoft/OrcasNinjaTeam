# Locks in PostgreSQL - How to identify and solve performance issues because of locking?

Queries waiting to acquire locks for longer than acceptable time can cause performance issues. Some common scenarios for that include:
- Concurent transactions with trying to DELETE/UPDATE same rows.
- DDL operations (ALTER TABLE, CREATE INDEX) running for long time can block other queries. They take write exclusive lock.

## How to capture locking issues:
- [Queries to capture locks](https://wiki.postgresql.org/wiki/Lock_Monitoring)
- [Log Locks](https://pganalyze.com/blog/postgresql-log-monitoring-101-deadlocks-checkpoints-blocked-queries)
- [Capture Query Wait Stats](https://docs.microsoft.com/en-us/azure/postgresql/tutorial-monitor-and-tune)

##  Best practices to prevent/fix locking issues:
- [7 tips for dealing with locks](https://www.citusdata.com/blog/2018/02/22/seven-tips-for-dealing-with-postgres-locks/): This blog has a concise summary of best practices around locking.

## Resources
- [PostgreSQL rocks, except when it blocks: Understanding locks](https://www.citusdata.com/blog/2018/02/15/when-postgresql-blocks/)
