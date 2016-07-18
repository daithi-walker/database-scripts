--https://blogs.oracle.com/In-Memory/entry/getting_started_with_oracle_database

SQL> set pagesize 1000   
SQL> set linesize 180 
SQL> show parameter inmemory;

NAME                                        TYPE            VALUE
------------------------------------        -----------     ------------------------------
inmemory_clause_default                     string
inmemory_force                              string          DEFAULT
inmemory_max_populate_servers               integer         0
inmemory_query                              string          ENABLE
inmemory_size                               big integer     0
inmemory_trickle_repopulate_servers_percent integer         1
optimizer_inmemory_aware                    boolean         TRUE

SQL> select name, value from v$sga;

NAME                    VALUE
--------------------    ----------
Fixed Size              2932432
Variable Size           637534512
Database Buffers        411041792
Redo Buffers            5455872

SQL> exec dbms_feature_usage_internal.exec_db_usage_sampling(sysdate);

PL/SQL procedure successfully completed.

SQL> select u1.name, u1.detected_usages
from dba_feature_usage_statistics u1
where u1.version in (select max(u2.version) 
from dba_feature_usage_statistics u2
where u1.name = u2.name
and u1.name like 'In-%'
);

NAME                                 DETECTED_USAGES
---------------------------------------------------------------- ---------------
In-Memory Aggregation                                  0
In-Memory Column Store                                 0

SQL> ALTER SYSTEM SET inmemory_size = 500M scope=spfile;             

System altered.

SQL> show parameter sga_target;

NAME                                 TYPE         VALUE
------------------------------------ -----------  ------------------------------
sga_target                            big integer 0

SQL> ALTER SYSTEM SET sga_target = 1G scope=spfile;

System altered.

SQL> 
create pfile='$ORACLE_HOME/dbs' from memory;


