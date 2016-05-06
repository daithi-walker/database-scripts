-----------------------
ORATEST
-----------------------

[oracle@ess-lon-oratest-002 dpdump]$ pwd
/u01/app/oracle/admin/ffmis/dpdump
[oracle@ess-lon-oratest-002 dpdump]$ expdp sanfran TABLES=mis_arc_dt_kw_activity_marin DUMPFILE=data_pump_dir:mis_arc_dt_kw_activity_marin.dmp NOLOGFILE=YES

Export: Release 11.2.0.1.0 - Production on Mon Mar 21 16:54:45 2016

Copyright (c) 1982, 2009, Oracle and/or its affiliates.  All rights reserved.
Password: 

Connected to: Oracle Database 11g Release 11.2.0.1.0 - 64bit Production
With the Automatic Storage Management option
Starting "SANFRAN"."SYS_EXPORT_TABLE_01":  sanfran/******** TABLES=mis_arc_dt_kw_activity_marin DUMPFILE=data_pump_dir:mis_arc_dt_kw_activity_marin.dmp NOLOGFILE=YES 
Estimate in progress using BLOCKS method...
Processing object type TABLE_EXPORT/TABLE/TABLE_DATA
Total estimation using BLOCKS method: 1.487 GB
Processing object type TABLE_EXPORT/TABLE/TABLE
Processing object type TABLE_EXPORT/TABLE/GRANT/OWNER_GRANT/OBJECT_GRANT
Processing object type TABLE_EXPORT/TABLE/INDEX/INDEX
Processing object type TABLE_EXPORT/TABLE/INDEX/STATISTICS/INDEX_STATISTICS
Processing object type TABLE_EXPORT/TABLE/STATISTICS/TABLE_STATISTICS
. . exported "SANFRAN"."MIS_ARC_DT_KW_ACTIVITY_MARIN"    1.390 GB 4084495 rows
Master table "SANFRAN"."SYS_EXPORT_TABLE_01" successfully loaded/unloaded
******************************************************************************
Dump file set for SANFRAN.SYS_EXPORT_TABLE_01 is:
  /u01/app/oracle/admin/ffmis/dpdump/mis_arc_dt_kw_activity_marin.dmp
Job "SANFRAN"."SYS_EXPORT_TABLE_01" successfully completed at 16:56:25

[oracle@ess-lon-oratest-002 dpdump]$ ls -ltr
total 1458380
-rw-r----- 1 oracle oinstall 1493377024 Mar 21 16:56 mis_arc_dt_kw_activity_marin.dmp
[oracle@ess-lon-oratest-002 dpdump]$ scp /u01/app/oracle/admin/ffmis/dpdump/mis_arc_dt_kw_activity_marin.dmp oracle@ess-lon-ora-001:/u01/app/oracle/admin/ffmis/dpdump/mis_arc_dt_kw_activity_marin.dmp
Warning: the RSA host key for 'ess-lon-ora-001' differs from the key for the IP address '192.168.16.8'
Offending key for IP in /home/oracle/.ssh/known_hosts:2
Matching host key in /home/oracle/.ssh/known_hosts:1
Are you sure you want to continue connecting (yes/no)? yes
oracle@ess-lon-ora-001's password: 
mis_arc_dt_kw_activity_marin.dmp                                                                                                                                           100% 1424MB  27.4MB/s   00:52    
[oracle@ess-lon-oratest-002 dpdump]$ 

-----------------------
ORAPROD
-----------------------

[oracle@ess-lon-ora-001 dpdump]$ impdp sanfran TABLES=mis_arc_dt_kw_activity_marin DIRECTORY=data_pump_dir DUMPFILE=mis_arc_dt_kw_activity_marin.dmp

Import: Release 11.2.0.1.0 - Production on Mon Mar 21 17:15:36 2016

Copyright (c) 1982, 2009, Oracle and/or its affiliates.  All rights reserved.
Password: 

Connected to: Oracle Database 11g Release 11.2.0.1.0 - 64bit Production
With the Automatic Storage Management option
Master table "SANFRAN"."SYS_IMPORT_TABLE_01" successfully loaded/unloaded
Starting "SANFRAN"."SYS_IMPORT_TABLE_01":  sanfran/******** TABLES=mis_arc_dt_kw_activity_marin DIRECTORY=data_pump_dir DUMPFILE=mis_arc_dt_kw_activity_marin.dmp 
Processing object type TABLE_EXPORT/TABLE/TABLE
Processing object type TABLE_EXPORT/TABLE/TABLE_DATA
. . imported "SANFRAN"."MIS_ARC_DT_KW_ACTIVITY_MARIN"    1.390 GB 4084495 rows
Processing object type TABLE_EXPORT/TABLE/GRANT/OWNER_GRANT/OBJECT_GRANT
Processing object type TABLE_EXPORT/TABLE/INDEX/INDEX
Processing object type TABLE_EXPORT/TABLE/INDEX/STATISTICS/INDEX_STATISTICS
Processing object type TABLE_EXPORT/TABLE/STATISTICS/TABLE_STATISTICS
Job "SANFRAN"."SYS_IMPORT_TABLE_01" successfully completed at 17:23:58

[oracle@ess-lon-ora-001 dpdump]$ 
