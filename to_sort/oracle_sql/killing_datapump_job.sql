************************************************************************************************************************************************************
************************************************************************************************************************************************************

https://pavandba.com/2011/07/12/how-to-deleteremove-non-executing-datapump-jobs/

Sometimes, we may get a requirement to delete datapump jobs which are stopped abruptly due to some reason. The following steps will actually help us to do that

1. First we need to identify which jobs are in NOT RUNNING status. For this, we need to use below query (basically we are getting this info from dba_datapump_jobs)

SET lines 200

SELECT owner_name, job_name, operation, job_mode,
state, attached_sessions
FROM dba_datapump_jobs
ORDER BY 1,2;

The above query will give the datapump jobs information and it will look like below

OWNER_NAME JOB_NAME            OPERATION JOB_MODE  STATE       ATTACHED
———- ——————- ——— ——— ———– ——–
SCOTT      SYS_EXPORT_TABLE_01 EXPORT    TABLE     NOT RUNNING        0
SCOTT      SYS_EXPORT_TABLE_02 EXPORT    TABLE     NOT RUNNING        0
SYSTEM     SYS_EXPORT_FULL_01  EXPORT    FULL      NOT RUNNING        0

In the above output, you can see state is showing as NOT RUNNING and those jobs need to be removed.

Note: Please note that jobs state will be showing as NOT RUNNING even if a user wantedly stopped it. So before taking any action, consult the user and get confirmed

2. we need to now identify the master tables which are created for these jobs. It can be done as follows

SELECT o.status, o.object_id, o.object_type,
       o.owner||’.’||object_name “OWNER.OBJECT”
  FROM dba_objects o, dba_datapump_jobs j
 WHERE o.owner=j.owner_name AND o.object_name=j.job_name
   AND j.job_name NOT LIKE ‘BIN$%’ ORDER BY 4,2;

STATUS   OBJECT_ID OBJECT_TYPE  OWNER.OBJECT
——- ———- ———— ————————-
VALID        85283 TABLE        SCOTT.EXPDP_20051121
VALID        85215 TABLE        SCOTT.SYS_EXPORT_TABLE_02
VALID        85162 TABLE        SYSTEM.SYS_EXPORT_FULL_01

3. we need to now drop these master tables in order to cleanup the jobs

SQL> DROP TABLE SYSTEM.SYS_EXPORT_FULL_01;
SQL> DROP TABLE SCOTT.SYS_EXPORT_TABLE_02 ;
SQL> DROP TABLE SCOTT.EXPDP_20051121;

4. Re-run the query which is used in step 1 to check if still any jobs are showing up. If so, we need to stop the jobs once again using STOP_JOB parameter in expdp or DBMS_DATAPUMP.STOP_JOB package

Some imp points:

1. Datapump jobs that are not running doesn’t have any impact on currently executing ones.
2. When any datapump job (either export or import) is initiated, master and worker processes will be created.
3. When we terminate export datapump job, master and worker processes will get killed and it doesn’t lead to data courrption.
4. But when import datapump job is terminated, complete import might not have done as processes(master & worker)  will be killed.

************************************************************************************************************************************************************
************************************************************************************************************************************************************

http://blog.oracle48.nl/killing-and-resuming-datapump-expdp-and-impdp-jobs/

Kill, cancel and resume or restart datapump expdp and impdp jobs
  By Ian Hoogeboom | 9 June 2011 | Oracle
The expdp and impdp utilities are command-line driven, but when starting them from the OS-prompt, one does not notice it. When you want to kill, cancel, start or resume a job, you will and up in the datapump command prompt… now what?!

All command shown here can be used with expdp and impdp datapump.

Identifying datapump jobs
Do a select from dba_datapump_jobs in sqlplus to get the job name:

> expdp system full=y

SELECT owner_name, job_name, operation, job_mode, state
FROM dba_datapump_jobs;

OWNER_NAME JOB_NAME             OPERATION  JOB_MODE   STATE
---------- -------------------- ---------- ---------- ------------
SYSTEM     SYS_EXPORT_FULL_01   EXPORT     FULL       EXECUTING
Or when you use the JOB_NAME parameter when datapumping, you already identified the job with a name. You don’t need to look up afterwards…

expdp system full=y JOB_NAME=EXP_FULL

OWNER_NAME JOB_NAME             OPERATION  JOB_MODE   STATE
---------- -------------------- ---------- ---------- ------------
SYSTEM     EXP_FULL             EXPORT     FULL       EXECUTING
Killing or stopping a running datapump job
The difference between Kill and Stop is simple to explain. When killing a job, you won’t be able to resume or start it again. Also logs and dumpfiles will be removed!

When exporting (or importing), press Ctrl-c to show the datapump prompt and type KILL_JOB or STOP_JOB[=IMMEDIATE]. You will be prompted to confirm if you are sure…

Adding ‘=IMMEDIATE‘ to STOP_JOB will not finish currently running ‘sub-job’ and must be redone when starting it again.

Processing object type DATABASE_EXPORT/SCHEMA/TABLE/TABLE_DATA
[Ctrl-c]
Export> KILL_JOB
..or..
Export> STOP_JOB=IMMEDIATE
Are you sure you wish to stop this job ([yes]/no): yes
Resuming a stopped job
Identify your job with SQL or you already knew it because you used ‘JOB_NAME=‘ ;)

SELECT owner_name, job_name, operation, job_mode, state
FROM dba_datapump_jobs;

OWNER_NAME JOB_NAME             OPERATION  JOB_MODE   STATE      
---------- -------------------- ---------- ---------- ------------
SYSTEM     EXP_FULL             EXPORT     FULL       NOT RUNNING
Now we can ATTACH to the job using it as a parameter to the expdp or impdp command, and a lot of gibberish is shown:

> expdp system ATTACH=EXP_FULL

Job: EXP_FULL
 Owner: SYSTEM
 Operation: EXPORT
 Creator Privs: TRUE
 GUID: A5441357B472DFEEE040007F0100692A
 Start Time: Thursday, 08 June, 2011 20:23:39
 Mode: FULL
 Instance: db1
 Max Parallelism: 1
 EXPORT Job Parameters:
 Parameter Name      Parameter Value:
 CLIENT_COMMAND        system/ ******** full=y JOB_NAME=EXP_FULL
 State: IDLING
 Bytes Processed: 0
 Current Parallelism: 1
 Job Error Count: 0
 Dump File: /u01/app/oracle/admin/db1/dpdump/expdat.dmp
 bytes written: 520,192

Worker 1 Status:
 Process Name: DW00
 State: UNDEFINED
(Re)start the job with START_JOB, use ‘=SKIP_CURRENT‘ if you want to skip the current job. To show progress again, type CONTINUE_CLIENT (Job will be restarted if idle).

Export> START_JOB[=SKIP_CURRENT]
Export> CONTINUE_CLIENT
Job EXP_FULL has been reopened at Thursday, 09 June, 2011 10:26
Restarting "SYSTEM"."EXP_FULL":  system/ ******** full=y JOB_NAME=EXP_FULL

Processing object type DATABASE_EXPORT/TABLESPACE
Processing object type DATABASE_EXPORT/PROFILE
Done…

Happy pumping!


************************************************************************************************************************************************************
************************************************************************************************************************************************************

http://dbatricksworld.com/how-to-kill-oracle-datapump-export-job/

We can kill oracle datapump job by two methods, First method includes killing data pump job via data pump export prompt and another method includes running SQL package on SQL prompt as sysdba.

//To simulate both the scenario, i am going to start oracle datapump export as below:

[oracle@dbserver ~]$ expdp system/manager full=y directory=bkupdir dumpfile=Full_export.dmp logfile=Export_log.LOG
Export: Release 11.2.0.3.0 – Production on Fri Apr 11 16:43:56 2014
Copyright (c) 1982, 2011, Oracle and/or its affiliates. All rights reserved.
Connected to: Oracle Database 11g Release 11.2.0.3.0 – 64bit Production
Starting “SYSTEM”.”SYS_EXPORT_FULL_01″: system/ ******** full=y directory=bkupdir dumpfile=Full_export.dmp logfile=Export_log.LOG
Estimate in progress using BLOCKS method…
Processing object type DATABASE_EXPORT/SCHEMA/TABLE/TABLE_DATA
Total estimation using BLOCKS method: 3.431 GB
Processing object type DATABASE_EXPORT/TABLESPACE
Processing object type DATABASE_EXPORT/PROFILE
Processing object type DATABASE_EXPORT/SYS_USER/USER
. .. …

First Method: Kill Data pump job by datapump export prompt:
//After initiating export backup, Kindly make sure datapump job by issuing the following query as sysdba:

SQL> select * from dba_datapump_jobs;

OWNER_NAME JOB_NAME
—————————— ——————————
OPERATION JOB_MODE
—————————— ——————————
STATE DEGREE ATTACHED_SESSIONS DATAPUMP_SESSIONS
—————————— ———- —————– —————–
SYSTEM SYS_EXPORT_FULL_01
EXPORT FULL
EXECUTING 1 1 3

//Now connect to datapump export prompt with JOB_NAME(attach) as below & issue the datapump command: KILL_JOB.

[oracle@dbserver ~]$ expdp system/manager attach=SYS_EXPORT_FULL_01
Export: Release 11.2.0.3.0 – Production on Fri Apr 11 17:01:13 2014
Copyright (c) 1982, 2011, Oracle and/or its affiliates. All rights reserved.
Connected to: Oracle Database 11g Release 11.2.0.3.0 – 64bit Production

Job: SYS_EXPORT_FULL_01
Owner: SYSTEM
Operation: EXPORT
Creator Privs: TRUE
GUID: F6C3A9B1D87AC043E0430100007F07F7
Start Time: Friday, 11 April, 2014 17:00:38
Mode: FULL
Instance: orcl
Max Parallelism: 1
EXPORT Job Parameters:
Parameter Name Parameter Value:
CLIENT_COMMAND system/ ******** full=y directory=bkupdir dumpfile=Full_export.dmp logfile=Export_log.LOG
State: EXECUTING
Bytes Processed: 0
Current Parallelism: 1
Job Error Count: 0
Dump File: /backup/Export/Full_export.dmp
bytes written: 4,096

Worker 1 Status:
Process Name: DW00
State: EXECUTING
Object Schema: ELET
Object Type: DATABASE_EXPORT/SCHEMA/PROCACT_SCHEMA
Completed Objects: 80
Worker Parallelism: 1

Export> KILL_JOB
Are you sure you wish to stop this job ([yes]/no): yes
[oracle@dbserver ~]$

//Datapump export job has been killed successfully. Same message will be display in datapump logfile as below:

[oracle@dbserver ~]$ expdp system/manager full=y directory=bkupdir dumpfile=Full_export.dmp logfile=Export_log.LOG
Export: Release 11.2.0.3.0 – Production on Fri Apr 11 16:43:56 2014
Copyright (c) 1982, 2011, Oracle and/or its affiliates. All rights reserved.
Connected to: Oracle Database 11g Release 11.2.0.3.0 – 64bit Production
Starting “SYSTEM”.”SYS_EXPORT_FULL_01″: system/ ******** full=y directory=bkupdir dumpfile=Full_export.dmp logfile=Export_log.LOG
Estimate in progress using BLOCKS method…
Processing object type DATABASE_EXPORT/SCHEMA/TABLE/TABLE_DATA
Total estimation using BLOCKS method: 3.431 GB
Processing object type DATABASE_EXPORT/TABLESPACE
Processing object type DATABASE_EXPORT/PROFILE
Processing object type DATABASE_EXPORT/SYS_USER/USER
Processing object type DATABASE_EXPORT/SCHEMA/USER
Processing object type DATABASE_EXPORT/ROLE
Processing object type DATABASE_EXPORT/GRANT/SYSTEM_GRANT/PROC_SYSTEM_GRANT
Processing object type DATABASE_EXPORT/SCHEMA/GRANT/SYSTEM_GRANT
Processing object type DATABASE_EXPORT/SCHEMA/ROLE_GRANT
. .. …
Job “SYSTEM”.”SYS_EXPORT_FULL_01″ stopped due to fatal error at 16:45:35

—x—

Second Method: Kill Datapump job by running SQL package:
//After inititating the oracle datapump export, ensure datapump job by issuing the following query as sysdba:

SQL> select * from dba_datapump_jobs;

OWNER_NAME JOB_NAME
—————————— ——————————
OPERATION JOB_MODE
—————————— ——————————
STATE DEGREE ATTACHED_SESSIONS DATAPUMP_SESSIONS
—————————— ———- —————– —————–
SYSTEM SYS_EXPORT_FULL_01
EXPORT FULL
EXECUTING 1 1 3

//To kill datapump job, We need two parameter as input to SQL package are: JOB_NAME of the datapump job & OWNER_NAME who initiated export.

SQL> DECLARE
h1 NUMBER;
BEGIN
h1:=DBMS_DATAPUMP.ATTACH(‘SYS_EXPORT_FULL_01‘,’SYSTEM‘);
DBMS_DATAPUMP.STOP_JOB (h1,1,0);
END;
/

PL/SQL procedure successfully completed.
SQL>

//Datapump export job has been killed successfully, same message will be display in datapump logfile as below:

[oracle@dbserver ~]$ expdp system/manager full=y directory=bkupdir dumpfile=Full_export.dmp logfile=Export_log.LOG
Export: Release 11.2.0.3.0 – Production on Fri Apr 11 17:00:37 2014
Copyright (c) 1982, 2011, Oracle and/or its affiliates. All rights reserved.
Connected to: Oracle Database 11g Release 11.2.0.3.0 – 64bit Production

Starting “SYSTEM”.”SYS_EXPORT_FULL_01″: system/ ******** full=y directory=bkupdir dumpfile=Full_export.dmp logfile=Export_log.LOG
Estimate in progress using BLOCKS method…
Processing object type DATABASE_EXPORT/SCHEMA/TABLE/TABLE_DATA
Total estimation using BLOCKS method: 3.431 GB
Processing object type DATABASE_EXPORT/TABLESPACE
Processing object type DATABASE_EXPORT/PROFILE
Processing object type DATABASE_EXPORT/SYS_USER/USER
Processing object type DATABASE_EXPORT/SCHEMA/USER
Processing object type DATABASE_EXPORT/ROLE
Processing object type DATABASE_EXPORT/GRANT/SYSTEM_GRANT/PROC_SYSTEM_GRANT
. .. …
Job “SYSTEM”.”SYS_EXPORT_FULL_01″ stopped due to fatal error at 17:01:23

By above two methods, we can kill oracle datapump export job.
