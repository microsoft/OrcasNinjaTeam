Prep checklist here: https://github.com/citusdata/wiki/wiki/Warp-prep-checklist 

How to invoke:
```
screen
./citus_warp -s postgres://source -d  postgres://destination --batch-statements=1000 --batch-transactions=500
```
Script generally runs on destination system and connects directly to source. This means SE access is necessary. 

Automatically creates replication slot on source and replication origin on target. Note that replication slot is not removed if warp stops. `citus_warp -s postgres://source -d  postgres://destination --clean` removes both slots. 

It is suggested that you get the postgres user password from /var/lib/pgsql/.pgpass

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

Overall suggestions:

1. Use parallel flags as seen in wiki. Successful Warps have seen values as high as 1000, best practices aren't known
To do this, create temp directory on /dat partition of coordinator
2. Bigger coordinator might help. 
3. Use pg_dump `-t` or `-T` for table management
4. Note batch-transactions and batch-statements to reduce round trip time
5. ALL WARP TARGET TABLES ARE TRUNCATED ON PROCESS START
6. Once you have caught up and are ready to cut over, remove all batch size arguments to avoid messages getting lost in the queue
7. Increase instance size on destination for duration of Warp to speed replication

How to monitor replication lag: 
Shown in screen session, no need for special monitoring
Replication lag is in total size and should drop consistently. 
Should be <100MB before cutover. 

How to pause and resume:
Can automatically tell that a base backup has been applied. Just cancel and relaunch. 

Basic setup:
1. RDS replication needs to be enabled if they're on RDS
2. Warp is a go binary

Batching:
If rate of change does not keep up


Heroku: 

1. Customer cuts over single node Heroku to single-node coordinator and from there to Citus Cloud. 
2. Read replica from Heroku 
3. Warp from single-node coordinator to cloud


Config steps of note:

1. Source should have wal_sender_timeout increased if customer uses large, long-running transactions
2. Probably worth dropping indexes on destination for initial catchup period. 
