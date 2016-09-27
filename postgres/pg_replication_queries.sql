postgres@ess-lon-mis-db-002u:~$ cat /var/lib/postgresql/9.4/main/recovery.conf
standby_mode = 'on'
primary_conninfo = 'host=ess-lon-mis-db-001u port=5432 user=repmgr password=eeChieyah4aish6Cae2aiche5lahth0g sslmode=prefer'
#trigger_file = '/etc/postgresql/postgresql.trigger'



(david.walker@ess-lon-mis-db-001u:5432) 05:52:55 [mis]  
mis-# select * from pg_stat_replication;
┌─[ RECORD 1 ]─────┬───────────────────────────────┐
│ pid              │ 31789                         │
│ usesysid         │ 41633403                      │
│ usename          │ repmgr                        │
│ application_name │ walreceiver                   │
│ client_addr      │ 192.168.16.87                 │
│ client_hostname  │                               │
│ client_port      │ 56377                         │
│ backend_start    │ 2016-08-23 16:57:57.306111+01 │
│ backend_xmin     │                               │
│ state            │ streaming                     │
│ sent_location    │ 2496/EC9EC000                 │
│ write_location   │ 2496/EC9EC000                 │
│ flush_location   │ 2496/EC9EC000                 │
│ replay_location  │ 2455/655DB2B8                 │
│ sync_priority    │ 0                             │
│ sync_state       │ async                         │
└──────────────────┴───────────────────────────────┘


(david.walker@ess-lon-mis-db-002u:5432) 05:41:11 [mis]  
mis-# select  pg_is_in_recovery()
mis-# ,       pg_last_xlog_receive_location()
mis-# ,       pg_last_xlog_replay_location()
mis-# ,       pg_last_xact_replay_timestamp();
┌───────────────────┬───────────────────────────────┬──────────────────────────────┬───────────────────────────────┐
│ pg_is_in_recovery │ pg_last_xlog_receive_location │ pg_last_xlog_replay_location │ pg_last_xact_replay_timestamp │
├───────────────────┼───────────────────────────────┼──────────────────────────────┼───────────────────────────────┤
│ t                 │ 2495/AFE6A000                 │ 2454/1C7F2E60                │ 2016-09-20 04:15:01.005643+01 │
└───────────────────┴───────────────────────────────┴──────────────────────────────┴───────────────────────────────┘
(1 row)


(david.walker@ess-lon-mis-db-002u:5432) 05:42:28 [mis]  
mis-# select pg_is_xlog_replay_paused();
┌──────────────────────────┐
│ pg_is_xlog_replay_paused │
├──────────────────────────┤
│ t                        │
└──────────────────────────┘
(1 row)



(david.walker@ess-lon-mis-db-002u:5432) 05:44:16 [mis]  
mis-# select pg_xlog_replay_resume();
┌───────────────────────┐
│ pg_xlog_replay_resume │
├───────────────────────┤
│                       │
└───────────────────────┘
(1 row)

(david.walker@ess-lon-mis-db-002u:5432) 05:44:42 [mis]  
mis-# select pg_is_xlog_replay_paused();
┌──────────────────────────┐
│ pg_is_xlog_replay_paused │
├──────────────────────────┤
│ f                        │
└──────────────────────────┘
(1 row)

(david.walker@ess-lon-mis-db-002u:5432) 05:44:52 [mis]  
mis-# select  pg_is_in_recovery()
,       pg_last_xlog_receive_location()
,       pg_last_xlog_replay_location()
,       pg_last_xact_replay_timestamp();
┌───────────────────┬───────────────────────────────┬──────────────────────────────┬───────────────────────────────┐
│ pg_is_in_recovery │ pg_last_xlog_receive_location │ pg_last_xlog_replay_location │ pg_last_xact_replay_timestamp │
├───────────────────┼───────────────────────────────┼──────────────────────────────┼───────────────────────────────┤
│ t                 │ 2495/D2F82000                 │ 2454/8035BD78                │ 2016-09-20 04:27:27.92317+01  │
└───────────────────┴───────────────────────────────┴──────────────────────────────┴───────────────────────────────┘
(1 row)
