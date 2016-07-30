--Source: https://oracle-base.com/articles/10g/auditing-10gr2
--Source: https://docs.oracle.com/cd/E11882_01/network.112/e36292/auditing.htm#CEGFIHGB

$ docker exec -ti oracle_dev bash
root@a617aa92e5eb:/opt/essence-mis-1# su oracle
oracle@a617aa92e5eb:/opt/essence-mis-1$ sqlplus / as sysdba

SQL*Plus: Release 11.2.0.2.0 Production on Sun Jul 17 08:20:24 2016

Copyright (c) 1982, 2011, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Express Edition Release 11.2.0.2.0 - 64bit Production

SQL> set sqlprompt "_user'@'_connect_identifier> "

SYS@XE> show parameter audit;

NAME                     TYPE    VALUE
------------------------------------ ----------- ------------------------------
audit_file_dest              string  /u01/app/oracle/admin/XE/adump
audit_sys_operations             boolean     FALSE
audit_syslog_level           string
audit_trail              string  NONE

SYS@XE> alter system set audit_trail=db scope=spfile;

System altered.

SYS@XE> shutdown
Database closed.
Database dismounted.
ORACLE instance shut down.

SYS@XE> startup

ORACLE instance started.

Total System Global Area  601272320 bytes
Fixed Size          2228848 bytes
Variable Size         197135760 bytes
Database Buffers      398458880 bytes
Redo Buffers            3448832 bytes
Database mounted.
Database opened.

SYS@XE> show parameter audit

NAME                     TYPE    VALUE
------------------------------------ ----------- ------------------------------
audit_file_dest              string  /u01/app/oracle/admin/XE/adump
audit_sys_operations             boolean     FALSE
audit_syslog_level           string
audit_trail              string  DB

SYS@XE> create tablespace u1 datafile 'u1.dbf' size 20M autoextend on;

Tablespace created.

SYS@XE> create user u1 identified by u1 default tablespace u1;

User created.

SYS@XE> grant connect, create session to u1;

Grant succeeded.

SYS@XE> grant unlimited tablespace to u1;

Grant succeeded.

SYS@XE> connect u1/u1
Connected.

U1@XE> show user;           
USER is "U1"

U1@XE>> connect / as sysdba
Connected.

SYS@XE> set linesize 180
SYS@XE> COL os_username FOR A15
SYS@XE> COL username FOR A15
SYS@XE> COL userhost FOR A15
SYS@XE> COL terminal FOR A15
SYS@XE> COL timestamp FOR A21
SYS@XE> COL action_name FOR A15
SYS@XE> SELECT  das.os_username
,       das.username
,       das.userhost
,       das.terminal
,       TO_CHAR(das.timestamp,'DD-MM-YYYY HH24:MI:SS') AS timestamp
,       das.action_name
FROM    sys.dba_audit_session das
WHERE   das.TIMESTAMP > SYSDATE-7
AND     das.returncode = 0;  2    3    4    5    6    7    8    9  

OS_USERNAME USERNAME    USERHOST    TERMINAL    TIMESTAMP         ACTION_NAME
--------------- --------------- --------------- --------------- --------------------- ---------------
oracle      U1      a617aa92e5eb            17-07-2016 08:36:20   LOGON
oracle      U1      a617aa92e5eb            17-07-2016 08:38:52   LOGOFF

SYS@XE> 


-- CLEANUP!! --

-- initialise the cleanup
begin
  dbms_audit_mgmt.init_cleanup(
   audit_trail_type           => dbms_audit_mgmt.audit_trail_aud_std,
   default_cleanup_interval   => 12 );
end;
/

-- force set the last archive flag. audit rail will be purged after this date.
begin
  dbms_audit_mgmt.set_last_archive_timestamp(
   audit_trail_type     =>  dbms_audit_mgmt.audit_trail_aud_std,
   last_archive_time    =>  systimestamp);
end;
/

select last_archive_ts from dba_audit_mgmt_last_arch_ts;

-- purge the audit trail manually.
begin
  dbms_audit_mgmt.clean_audit_trail(
   audit_trail_type           =>  dbms_audit_mgmt.audit_trail_aud_std,
   use_last_arch_timestamp    =>  true);
end;
/

-- schedule the purging of the audit trail.
begin
  dbms_audit_mgmt.create_purge_job (
   audit_trail_type            => dbms_audit_mgmt.audit_trail_aud_std, 
   audit_trail_purge_interval  => 720,
   audit_trail_purge_name      => 'standard_audit_trail_pj',
   use_last_arch_timestamp     => true );
end;
/

-- change the tablespace that the audit tables belong to.
begin
  dbms_audit_mgmt.set_audit_trail_location(
    audit_trail_type           => dbms_audit_mgmt.audit_trail_aud_std,
    audit_trail_location_value => 'audit_aux');
end;
/