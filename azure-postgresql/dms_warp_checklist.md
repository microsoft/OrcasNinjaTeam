Basic architecture:

1. First, pg_dump and pg_restore for base backup
2. Replication

Common issues:

1. Schema mismatch. Typically errors out in backup/restore, can be in either
* Symptom: pg_restore errors out, Warp exits. Alternate symptom: column foobar does not exist
* Resolution: fix schema, clean slots, start over
2. Too high rate of change
* Symptom: 
* Resolution: 
3. DDL changes
* Symptom: similar to (1)
* Resolution: 
4. Lack of primary keys on source. Allowed to miss them on insert only tables only
* Symptom: replication errors out with "missing primary key" type message
* Resolution: add pkeys, restart warp
5. Out of disk
6. Too much load on source
7. Replication slot creation needs all transactions to finish, is load sensitive
8. Doesn't play nicely with camelcase tablenames
9. Sequences might need manual reset at end. 

Config steps of note:

1. Source should have wal_sender_timeout increased if customer uses large, long-running transactions
2. Probably worth dropping indexes on destination for initial catchup period. 
