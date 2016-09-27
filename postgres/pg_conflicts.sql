--Source: https://vibhorkumar.wordpress.com/2011/11/15/new-replication-and-recovery-features-in-postgresql-9-1/

(david.walker@ess-lon-mis-db-002u:5432) 05:54:53 [mis]  
mis-# select datname, conflicts from pg_stat_database where datname = 'mis';
┌─────────┬───────────┐
│ datname │ conflicts │
├─────────┼───────────┤
│ mis     │        59 │
└─────────┴───────────┘
(1 row)

(david.walker@ess-lon-mis-db-002u:5432) 05:56:42 [mis]  
mis-# select * from pg_stat_database_conflicts where datname = 'mis';
┌───────┬─────────┬──────────────────┬────────────┬────────────────┬─────────────────┬────────────────┐
│ datid │ datname │ confl_tablespace │ confl_lock │ confl_snapshot │ confl_bufferpin │ confl_deadlock │
├───────┼─────────┼──────────────────┼────────────┼────────────────┼─────────────────┼────────────────┤
│ 16414 │ mis     │                0 │         22 │             37 │               0 │              0 │
└───────┴─────────┴──────────────────┴────────────┴────────────────┴─────────────────┴────────────────┘
(1 row)
