-- Source: https://www.postgresql.org/message-id/CADKbJJWz9M0swPT3oqe8f9+tfD4-F54uE6Xtkh4nERpVsQnjnw@mail.gmail.com

Looking at the documentation and all the blog posts about how to monitor
replication delay I don't think there is one good and most importantly safe
solution which works all the time.

*Solution #1:*

I used to check replication delay/lag by running the following query on the
slave:

SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))::INT;

This query works great and it is a very good query to give you the lag in
seconds. The problem is if the master is not active, it doesn't mean a
thing. So you need to first check if two servers are in sync and if they
are, return 0.


*Solution #2:*

This can be achieved by comparing pg_last_xlog_receive_location()  and
pg_last_xlog_replay_location() on the slave, and if they are the same it
returns 0, otherwise it runs the above query again:

SELECT
CASE
WHEN pg_last_xlog_receive_location() = pg_last_xlog_replay_location() THEN 0
 ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp())::INTEGER
END
AS replication_lag;

This query is all good, but the problem is that it is not safe. If for some
reason the master stops sending transaction logs, this query will continue
to return 0 and you will think the replication is working, when it is not.


*Solution #3:*

The Postgres Wiki
http://wiki.postgresql.org/wiki/Streaming_Replicationrecommends to run
the following two queries:

Master:
SELECT pg_current_xlog_location();

Slave:
SELECT pg_last_xlog_receive_location();

and by comparing these two values you could see if the servers are in sync.
The problem yet again is that if streaming replication fails, both of these
functions will continue to return same values and you could still end up
thinking the replication is working. But also you need to query both the
master and slave to be able to monitor this, which is not that easy on
monitoring systems, and you still don't have the information about the
actual lag in seconds, so you would still need to run the first query.


*Solution #4:*

You could query pg_stat_replication on the master, compare sent_location
and replay_location, and if they are the same, the replication is in sync.
One more good thing about pg_stat_replication is that if streaming
replication fails it will return an empty result, so you will know it
failed. But the biggest problem with this system view is that only the postgres
user can read it, so it's not that monitoring friendly since you don't want
to give your monitoring system super user privileges, and you still don't
have the delay in seconds.


*Real solution?*

Looking at all four solutions, I think the best one would be #2 combined
with a check if the wal receiver process is running before running that
query with something like:

$ ps aux | egrep 'wal\sreceiver'
postgres  3858  0.0  0.0 2100112 3312 ?        Ss   19:35   0:01 postgres:
wal receiver process   streaming 36/900A738

This solution would only be run on the slave and it is pretty easy to setup.

Does anyone have a better idea?