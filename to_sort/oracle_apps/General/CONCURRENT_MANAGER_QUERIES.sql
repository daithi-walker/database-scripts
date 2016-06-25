Concurrent Manager Queries
By using below Concurrent Manager and Program rules:

--Gives Detail of the Concurrent_queue_name and User_concurrent_program_name

SELECT b.concurrent_queue_name, c.user_concurrent_program_name 
FROM FND_CONCURRENT_QUEUE_CONTENT a, fnd_concurrent_queues b, fnd_concurrent_programs_vl c
WHERE a.queue_application_id = 283 
and a.concurrent_queue_id = b.concurrent_queue_id
and a.type_id = c.concurrent_program_id
order by decode(INCLUDE_FLAG, 'I', 1, 2), type_code;


Cancelling Concurrent request:

--By request id 
update fnd_concurrent_requests
set status_code='D', phase_code='C'
where request_id=&req_id;

--By program_id
update fnd_concurrent_requests
set status_code='D', phase_code='C'
where CONCURRENT_PROGRAM_ID=&prg_id;

Checking last run of a Concurrent Program along with Processed time:

-- Useful to find the Details of Concurrent programs which run daily and comparison purpose

SELECT DISTINCT c.USER_CONCURRENT_PROGRAM_NAME,
            round(((a.actual_completion_date-a.actual_start_date)*24*60*60/60),2) AS Process_time,
            a.request_id,a.parent_request_id,To_Char(a.request_date,'DD-MON-YY HH24:MI:SS'),To_Char(a.actual_start_date,'DD-MON-YY HH24:MI:SS'),
  To_Char(a.actual_completion_date,'DD-MON-YY HH24:MI:SS'), (a.actual_completion_date-a.request_date)*24*60*60 AS end_to_end,
            (a.actual_start_date-a.request_date)*24*60*60 AS lag_time,
            d.user_name, a.phase_code,a.status_code,a.argument_text,a.priority
FROM   apps.fnd_concurrent_requests a,
            apps.fnd_concurrent_programs b ,
            apps.FND_CONCURRENT_PROGRAMS_TL c,
            apps.fnd_user d
WHERE       a.concurrent_program_id= b.concurrent_program_id AND
            b.concurrent_program_id=c.concurrent_program_id AND
            a.requested_by =d.user_id AND
--          trunc(a.actual_completion_date) = '24-AUG-2005'
c.USER_CONCURRENT_PROGRAM_NAME='Incentive Compensation Analytics - ODI' --  and argument_text like  '%, , , , ,%';
--          and status_code!='C'

Checking the concurrent programs running currently with Details of Processed time and Start Date:

SELECT DISTINCT c.USER_CONCURRENT_PROGRAM_NAME,round(((sysdate-a.actual_start_date)*24*60*60/60),2) AS Process_time,
 a.request_id,a.parent_request_id,a.request_date,a.actual_start_date,a.actual_completion_date,(a.actual_completion_date-a.request_date)*24*60*60 AS end_to_end,
 (a.actual_start_date-a.request_date)*24*60*60 AS lag_time,d.user_name, a.phase_code,a.status_code,a.argument_text,a.priority
FROM   apps.fnd_concurrent_requests a,apps.fnd_concurrent_programs b,apps.FND_CONCURRENT_PROGRAMS_TL c,apps.fnd_user d
WHERE  a.concurrent_program_id=b.concurrent_program_id AND b.concurrent_program_id=c.concurrent_program_id AND
a.requested_by=d.user_id AND status_code='R' order by Process_time desc;

Checking the last run of concurrent Program:

- Use below query to check all the concurrent request running which may refer given package
-- This is very useful check before compiling any package on given instance.
-- The query can be modified as per requirement.
-- Remove FND_CONCURRENT_REQUESTS table and joins to check all program dependent on    given package.

SELECT
 FCR.REQUEST_ID
,FCPV.USER_CONCURRENT_PROGRAM_NAME
,FCPV.CONCURRENT_PROGRAM_NAME
,FCPV.CONCURRENT_PROGRAM_ID
,FCR.STATUS_CODE
,FCR.PHASE_CODE
FROM FND_CONCURRENT_PROGRAMS_VL FCPV
,FND_EXECUTABLES FE
,SYS.DBA_DEPENDENCIES DD
,FND_CONCURRENT_REQUESTS FCR
WHERE FCPV.EXECUTABLE_ID = FE.EXECUTABLE_ID
AND FE.EXECUTION_METHOD_CODE = 'I'
AND SUBSTR(FE.EXECUTION_FILE_NAME,1,INSTR(FE.EXECUTION_FILE_NAME, '.', 1, 1) - 1) = UPPER(DD.NAME)
AND DD.REFERENCED_TYPE IN ('VIEW', 'TABLE', 'TRIGGER', 'PACKAGE') -- add as required
--AND referenced_owner = 'XXCUS'
AND DD.REFERENCED_NAME = UPPER('&Package_name')
AND FCR.CONCURRENT_PROGRAM_ID = FCPV.CONCURRENT_PROGRAM_ID
AND fcr.phase_code NOT IN ( 'C','P');


Concurrent Program count under QUEUE:

col  "program name" format a55;
col "name" format  a17;
col "queue name" format a15
col "statuscode" format a3
select user_CONCURRENT_PROGRAM_NAME "PROGRAM NAME",concurrent_queue_name "QUEUE NAME", priority,decode(phase_code,'P','Pending') "PHASE", 
decode(status_code,'A','Waiting','B','Resuming','C','Normal','D','Cancelled','E','Error','F',
'Scheduled','G','Warning','H','On Hold','I','Normal','M','No Manager','Q','Standby','R','Normal','S',
'Suspended','T','Terminating','U','Disabled','W','Paused','X','Terminated','Z','Waiting') " 
NAME", status_code,count(*) from 
fnd_concurrent_worker_requests 
where  phase_code='P' and hold_flag!='Y' 
and requested_start_date<=sysdate
and concurrent_queue_name<> 'FNDCRM'
and concurrent_queue_name<> 'GEMSPS'
group by 
user_CONCURRENT_PROGRAM_NAME,
concurrent_queue_name,priority,phase_code,status_code
order by count(*) desc

Concurrent QUEUE Details:

set echo off
set linesize 130
set serveroutput on size 50000
set feed off
set veri off
DECLARE
running_count NUMBER := 0;
pending_count NUMBER := 0;
crm_pend_count NUMBER := 0;
--get the list of all conc managers and max worker and running workers
CURSOR conc_que IS
SELECT concurrent_queue_id,
concurrent_queue_name,
user_concurrent_queue_name, 
max_processes,
running_processes
FROM apps.fnd_concurrent_queues_vl
WHERE enabled_flag='Y' and 
concurrent_queue_name not like 'XDP%' and 
concurrent_queue_name not like 'IEU%' and 
concurrent_queue_name not in ('ARTAXMGR','PASMGR') ;
BEGIN
DBMS_OUTPUT.PUT_LINE('====================================================================================================');
DBMS_OUTPUT.PUT_LINE('QueueID'||' '||'Queue          '||
'Concurrent Queue Name              '||' '||'MAX '||' '||'RUN '||' '||
'Running '||' '||'Pending   '||' '||'In CRM');
DBMS_OUTPUT.PUT_LINE('====================================================================================================');
FOR i IN conc_que Loop

Concurrent request status for a given sid:

col MODULE for a20
col OSUSER for a10
col USERNAME for a10
set num 10
col MACHINE for a20
set lines 200
col SCHEMANAME for a10
select s.INST_ID,s.sid,s.serial#,p.spid os_pid,s.status, s.osuser,s.username, s.MACHINE,s.MODULE, s.SCHEMANAME,
s.action from gv$session s, gv$process p WHERE s.paddr = p.addr and s.sid = '&oracle_sid';

CONCURRENT REQUESTS COMPLETED WITH ERRORS:

COL name FORMAT a50
COL st_time FORMAT a7
COL requestor FORMAT a18
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET TERM OFF
SET VERIFY OFF
SET PAGES 9000
SET LINES 120
SELECT a.request_id request_id
, SUBSTR(a.user_concurrent_program_name,1,50) name
, TO_CHAR(a.actual_start_date,'Hh34:MI') st_time
, TO_CHAR(a.actual_completion_date,'Hh34:MI') end_time
, requestor
, DECODE(a.phase_code, 'R'
,'Running', 'P'
,'Inactive', 'C'
,'Completed', a.phase_code) phase_code
, DECODE(a.status_code, 'E'
,'Error', 'C'
,'Normal', 'X'
,'Terminated', 'Q'
,'On Hold', 'D'
,'Cancelled', 'G'
,'Warning', 'R'
,'Normal', 'W'
,'Paused', a.status_code) status_code
FROM apps.fnd_conc_req_summary_v a
WHERE TRUNC(actual_completion_date) >= TRUNC(SYSDATE -1)
AND a.status_code IN ('E','X','D')
ORDER BY actual_start_date
/

CONCURRENT REQUESTS PERFORMANCE HISTORY (PER DAY):

SELECT TO_CHAR(TRUNC(ACTUAL_START_DATE),'DD-MON-YY DY') STARTDATE,
COUNT(*) COUNT, ROUND(SUM(ACTUAL_COMPLETION_DATE - ACTUAL_START_DATE) * 24, 2) RUNNING_HOURS,
ROUND(AVG(ACTUAL_COMPLETION_DATE - ACTUAL_START_DATE) * 24, 2) AVG_RUNNING_HOURS,
ROUND(SUM(ACTUAL_START_DATE - REQUESTED_START_DATE) * 24, 2) PENDING_HOURS,
ROUND(AVG(ACTUAL_START_DATE - REQUESTED_START_DATE) * 24, 2) AVG_PENDING_HOURS
FROM APPLSYS.FND_CONCURRENT_PROGRAMS P,APPLSYS.FND_CONCURRENT_REQUESTS R
WHERE R.PROGRAM_APPLICATION_ID = P.APPLICATION_ID
AND R.CONCURRENT_PROGRAM_ID = P.CONCURRENT_PROGRAM_ID
AND R.STATUS_CODE IN ('C','G')
AND TRUNC(ACTUAL_COMPLETION_DATE) > TRUNC(SYSDATE-6)
AND TO_CHAR(TRUNC(ACTUAL_START_DATE),'DD-MON-YY DY') IS NOT NULL
GROUP BY TRUNC(ACTUAL_START_DATE) 
ORDER BY TRUNC(ACTUAL_START_DATE) ASC;

CONCURRENT REQUESTS WHICH HAS MORE THAN 30 MINUTES OF EXECUTION TIME:

SELECT a.request_id
, SUBSTR(user_concurrent_program_name,1,50) name
, TO_CHAR(actual_start_date,'DD-MON-YY Hh34:MI') st_dt
, TO_CHAR(actual_completion_date,'Hh34:MI') end_tm
, TRUNC(((actual_completion_date-actual_start_date)*24*60*60)/60)+(((actual_completion_date-actual_start_date)*24*60*60)-(TRUNC(((actual_completion_date-actual_start_date)*24*60*60)/60)*60))/100 exe_time
, requestor
, DECODE(a.status_code, 'E'
,'Error', 'X'
,'Terminated', 'Normal') status_code
FROM apps.fnd_conc_req_summary_v a
WHERE actual_start_date >= DECODE(TO_CHAR(SYSDATE,'DAY'), 'MONDAY'
,TRUNC(SYSDATE)-3, 'SUNDAY'
,TRUNC(SYSDATE)-2, TRUNC(SYSDATE-1))
AND NVL(actual_completion_date,SYSDATE) - actual_start_date >= 30/24/60
ORDER BY actual_start_date, name
/

Find out Concurrent Program which enable with trace:

col User_Program_Name for a40
col Last_Updated_By for a30
col DESCRIPTION for a30
SELECT A.CONCURRENT_PROGRAM_NAME "Program_Name",
SUBSTR(A.USER_CONCURRENT_PROGRAM_NAME,1,40) "User_Program_Name",
SUBSTR(B.USER_NAME,1,15) "Last_Updated_By",
SUBSTR(B.DESCRIPTION,1,25) DESCRIPTION
FROM APPS.FND_CONCURRENT_PROGRAMS_VL A, APPLSYS.FND_USER B
WHERE A.ENABLE_TRACE='Y'
AND A.LAST_UPDATED_BY=B.USER_ID;

Find out request id from Oracle_Process Id:

select REQUEST_ID,ORACLE_PROCESS_ID,OS_PROCESS_Id from apps.fnd_concurrent_requests where ORACLE_PROCESS_ID='&a';

For checking the locks in concurrent jobs:

SELECT DECODE(request,0,'Holder: ','Waiter: ')||sid sess,inst_id,id1, id2, lmode, request, type FROM gV$LOCK 
WHERE (id1, id2, type) IN (SELECT id1, id2, type FROM gV$LOCK WHERE request>0) ORDER BY id1,request;

For each manager get the number of pending and running requests in each queue:

SELECT /*+ RULE */ nvl(sum(decode(phase_code, 'R', 1, 0)), 0), 
nvl(sum(decode(phase_code, 'P', 1, 0)), 0)
INTO running_count, pending_count
FROM fnd_concurrent_worker_requests
WHERE
requested_start_date <= sysdate
and concurrent_queue_id = i.concurrent_queue_id
AND hold_flag != 'Y'; 
--for each manager get the list of requests pending due to conflicts in each manager
SELECT /*+ RULE */ count(1)
INTO crm_pend_count
FROM apps.fnd_concurrent_worker_requests a
WHERE concurrent_queue_id = 4
AND hold_flag != 'Y'
AND requested_start_date <= sysdate
AND exists (
SELECT 'x' 
FROM apps.fnd_concurrent_worker_requests b
WHERE a.request_id=b.request_id
and concurrent_queue_id = i.concurrent_queue_id
AND hold_flag != 'Y'
AND requested_start_date <= sysdate);
--print the output by joining the outputs of manager counts,  
DBMS_OUTPUT.PUT_LINE(
rpad(i.concurrent_queue_id,8,'_')||
rpad(i.concurrent_queue_name,15, ' ')||
rpad(i.user_concurrent_queue_name,40,' ')||
rpad(i.max_processes,6,' ')||
rpad(i.running_processes,6,' ')||
rpad(running_count,10,' ')||
rpad(pending_count,10,' ')||
rpad(crm_pend_count,10,' '));
--DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------------------');
END LOOP;
DBMS_OUTPUT.PUT_LINE('====================================================================================================');
END;
/
set verify on
set echo on

Gives detail of Concurrent job completed and pending:

SELECT
 FCR.REQUEST_ID
,FCPV.USER_CONCURRENT_PROGRAM_NAME
,FCPV.CONCURRENT_PROGRAM_NAME
,FCPV.CONCURRENT_PROGRAM_ID
,FCR.STATUS_CODE
,FCR.PHASE_CODE
FROM FND_CONCURRENT_PROGRAMS_VL FCPV
,FND_EXECUTABLES FE
,SYS.DBA_DEPENDENCIES DD
,FND_CONCURRENT_REQUESTS FCR
WHERE FCPV.EXECUTABLE_ID = FE.EXECUTABLE_ID
AND FE.EXECUTION_METHOD_CODE = 'I'
AND SUBSTR(FE.EXECUTION_FILE_NAME,1,INSTR(FE.EXECUTION_FILE_NAME, '.', 1, 1) - 1) = UPPER(DD.NAME)
AND DD.REFERENCED_TYPE IN ('VIEW', 'TABLE', 'TRIGGER', 'PACKAGE') -- add as required
--AND referenced_owner = 'XXCUS'
AND DD.REFERENCED_NAME = UPPER('&Package_name')
AND FCR.CONCURRENT_PROGRAM_ID = FCPV.CONCURRENT_PROGRAM_ID
AND fcr.phase_code NOT IN ( 'C','P');

Gives Detail of Running and Completed Concurrent jobs with Start date and end date:

select
      f.request_id ,
      pt.user_concurrent_program_name user_conc_program_name,
      f.actual_start_date start_on,
      f.actual_completion_date end_on,
      floor(((f.actual_completion_date-f.actual_start_date)
        *24*60*60)/3600)
        || ' HOURS ' ||
        floor((((f.actual_completion_date-f.actual_start_date)
        *24*60*60) -
        floor(((f.actual_completion_date-f.actual_start_date)
        *24*60*60)/3600)*3600)/60)
        || ' MINUTES ' ||
        round((((f.actual_completion_date-f.actual_start_date)
        *24*60*60) -
        floor(((f.actual_completion_date-f.actual_start_date)
        *24*60*60)/3600)*3600 -
        (floor((((f.actual_completion_date-f.actual_start_date)
        *24*60*60) -
        floor(((f.actual_completion_date-f.actual_start_date)
        *24*60*60)/3600)*3600)/60)*60) ))
        || ' SECS ' time_difference,
      p.concurrent_program_name concurrent_program_name,
      decode(f.phase_code,'R','Running','C','Complete',f.phase_code) Phase,
      f.status_code
from  apps.fnd_concurrent_programs p,
      apps.fnd_concurrent_programs_tl pt,
      apps.fnd_concurrent_requests f
where f.concurrent_program_id = p.concurrent_program_id
      and f.program_application_id = p.application_id
      and f.concurrent_program_id = pt.concurrent_program_id
      and f.program_application_id = pt.application_id
      AND pt.language = USERENV('Lang')
      and f.actual_start_date is not null
order by
      f.actual_start_date desc;


Gives Details of Running Concurrent jobs:

SELECT DISTINCT c.USER_CONCURRENT_PROGRAM_NAME,
      round(((sysdate-a.actual_start_date)*24*60*60/60),2) AS Process_time,
    a.request_id,a.parent_request_id,a.request_date,a.actual_start_date,a.actual_completion_date,
      (a.actual_completion_date-a.request_date)*24*60*60 AS end_to_end,
      (a.actual_start_date-a.request_date)*24*60*60 AS lag_time,
      d.user_name, a.phase_code,a.status_code,a.argument_text,a.priority
FROM     apps.fnd_concurrent_requests a,
    apps.fnd_concurrent_programs b , 
    apps.FND_CONCURRENT_PROGRAMS_TL c,
    apps.fnd_user d
WHERE   a.concurrent_program_id=b.concurrent_program_id AND
    b.concurrent_program_id=c.concurrent_program_id AND
    a.requested_by=d.user_id AND
    status_code='R' order by Process_time desc;

HISTORY OF CONCURRENT REQUEST - SCRIPT (PROGRAM WISE):

set pagesize 200
set linesize 200
col "Who submitted" for a25
col "Status" for a10
col "Parameters" for a20
col USER_CONCURRENT_PROGRAM_NAME for a42
SELECT distinct t.user_concurrent_program_name,
r.REQUEST_ID,
to_char(r.ACTUAL_START_DATE,'dd-mm-yy hh24:mi:ss') "Started at",
to_char(r.ACTUAL_COMPLETION_DATE,'dd-mm-yy hh24:mi:ss') "Completed at",
decode(r.PHASE_CODE,'C','Completed','I','Inactive','P ','Pending','R','Running','NA') phasecode,
decode(r.STATUS_CODE, 'A','Waiting', 'B','Resuming', 'C','Normal', 'D','Cancelled', 'E','Error', 'F','Scheduled', 'G','Warning', 'H','On Hold', 'I','Normal', 'M',
'No Manager', 'Q','Standby', 'R','Normal', 'S','Suspended', 'T','Terminating', 'U','Disabled', 'W','Paused', 'X','Terminated', 'Z','Waiting') "Status",r.argument_text "Parameters",substr(u.description,1,25) "Who submitted",round(((nvl(v.actual_completion_date,sysdate)-v.actual_start_date)*24*60)) Etime
FROM
apps.fnd_concurrent_requests r ,
apps.fnd_concurrent_programs p ,
apps.fnd_concurrent_programs_tl t,
apps.fnd_user u, apps.fnd_conc_req_summary_v v
WHERE 
r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID
AND r.actual_start_date >= (sysdate-30)
--AND r.requested_by=22378
AND   r.PROGRAM_APPLICATION_ID = p.APPLICATION_ID
AND t.concurrent_program_id=r.concurrent_program_id
AND r.REQUESTED_BY=u.user_id
AND v.request_id=r.request_id
--AND r.request_id ='2260046' in ('13829387','13850423')
and t.user_concurrent_program_name like '%%'
order by to_char(r.ACTUAL_COMPLETION_DATE,'dd-mm-yy hh24:mi:ss');

History of concurrent requests which are error out:

SELECT a.request_id "Req Id"
,a.phase_code,a.status_code
, actual_start_date
, actual_completion_date
,c.concurrent_program_name || ': ' || ctl.user_concurrent_program_name "program"
FROM APPLSYS.fnd_Concurrent_requests a,APPLSYS.fnd_concurrent_processes b
,applsys.fnd_concurrent_queues q
,APPLSYS.fnd_concurrent_programs c
,APPLSYS.fnd_concurrent_programs_tl ctl
WHERE a.controlling_manager = b.concurrent_process_id
AND a.concurrent_program_id = c.concurrent_program_id
AND a.program_application_id = c.application_id
AND a.status_code = 'E'
AND a.phase_code = 'C'
AND actual_start_date > sysdate - 2
AND b.queue_application_id = q.application_id
AND b.concurrent_queue_id = q.concurrent_queue_id
AND ctl.concurrent_program_id = c.concurrent_program_id
AND ctl.LANGUAGE = 'US'
ORDER BY 5 DESC; 

LIST ALL THE REGISTERED CONCURRENT PROGRAMS BY MODULE:

set lines 180
set pages 300
col SHORT_NAME for a10
col APPLICATION_NAME for a30
SELECT SUBSTR(a.application_name,1,60) Application_NAME
, b.application_short_name SHORT_NAME
, DECODE(SUBSTR(cp.user_concurrent_program_name,4,1),':'
, 'Concurrent Manager Executable'
, 'Subprogram or Function') TYPE
, SUBSTR(d.concurrent_program_name,1,16) PROGRAM 
, SUBSTR(cp.user_concurrent_program_name,1,55) USER_PROGRAM_NAME
FROM applsys.FND_CONCURRENT_PROGRAMS_TL cp, applsys.FND_CONCURRENT_PROGRAMS d, applsys.FND_APPLICATION_TL a, applsys.fnd_application b
WHERE cp.application_id = a.application_id
AND d.CONCURRENT_PROGRAM_ID = cp.CONCURRENT_PROGRAM_ID 
AND a.APPLICATION_ID = b.APPLICATION_ID
AND b.application_short_name LIKE UPPER('PA')
UNION ALL
SELECT SUBSTR(a.application_name,1,60) c1
, b.application_short_name c2 , 'Form Executable' c3
, SUBSTR(f.form_name,1,16) c4 , 
SUBSTR(d.user_form_name,1,55) c5
FROM applsys.fnd_form f , applsys.FND_APPLICATION_TL a, applsys.fnd_application b, applsys.FND_FORM_TL d
WHERE f.application_id = a.application_id 
AND d.FORM_ID = f.FORM_ID
AND a.APPLICATION_ID = b.APPLICATION_ID
AND b.application_short_name LIKE UPPER('PA') ORDER BY 1,2,3,4;

Lists the Manager Names with the No. of Requests in PendingRunning:

col "USER_CONCURRENT_QUEUE_NAME" format a40;

SELECT a.USER_CONCURRENT_QUEUE_NAME,a.MAX_PROCESSES,
sum(decode(b.PHASE_CODE,'P',decode(b.STATUS_CODE,'Q',1,0),0)) Pending_Standby,
sum(decode(b.PHASE_CODE,'P',decode(b.STATUS_CODE,'I',1,0),0)) Pending_Normal,
sum(decode(b.PHASE_CODE,'R',decode(b.STATUS_CODE,'R',1,0),0)) Running_Normal
FROM FND_CONCURRENT_QUEUES_VL a, FND_CONCURRENT_WORKER_REQUESTS b
where a.concurrent_queue_id = b.concurrent_queue_id
AND b.Requested_Start_Date<=SYSDATE
GROUP BY a.USER_CONCURRENT_QUEUE_NAME,a.MAX_PROCESSES

NUMBER OF CONCURRENT REQUESTS IN A DAY:

SET LINES 120
SET PAGES 0
COL cnt FORMAT 999999 HEADING "Total No of Requests"
SELECT ' Number of Concurrent Requests for ', SYSDATE - 1 FROM dual ;
SET PAGES 900
SELECT COUNT(*) cnt
FROM apps.fnd_concurrent_requests
WHERE TRUNC(actual_start_date) = TRUNC(SYSDATE) - 1
/

PRESENTLY RUNNING REQUEST:

set lines 180
set pages 500
col USER_CONCURRENT_PROGRAM_NAME for a50
col USER_NAME for a30
SELECT fcr.request_id, ftp.user_concurrent_program_name, fcu.user_name
FROM apps.fnd_concurrent_requests fcr,
apps.fnd_concurrent_programs_tl ftp,
apps.fnd_user fcu
WHERE fcr.status_code = 'R'
AND fcr.phase_code = 'R'
AND fcu.user_id = fcr.requested_by
AND fcr.concurrent_program_id = ftp.concurrent_program_id;

PROGRAMS RAN MORE 200 TIMES IN A DAY:

SET LINES 120
SET PAGES 900
COL program FORMAT a70
COL cnt FORMAT 999999 HEADING "Number of Runs"
ttitle 'Programs that ran for more than 200 times ' skip 2
SELECT SUBSTR(user_concurrent_program_name,1,70) program
, COUNT(*) cnt
FROM apps.fnd_conc_req_summary_v
WHERE TRUNC(actual_start_date) = TRUNC(SYSDATE) -1
GROUP BY SUBSTR(user_concurrent_program_name,1,70)
HAVING COUNT(*) > 200
ORDER BY 2

Query we can get sid,serial#,spid of the concurrent Request:

SELECT a.request_id, d.sid, d.serial# , c.SPID
    FROM apps.fnd_concurrent_requests a,
    apps.fnd_concurrent_processes b,
    v$process c,
    v$session d
    WHERE a.controlling_manager = b.concurrent_process_id
    AND c.pid = b.oracle_process_id
    AND b.session_id=d.audsid
    AND a.request_id = &Request_ID
    AND a.phase_code = 'R';

Query will display the time taken to execute the concurrent Programs:

The following query will display the time taken to execute the concurrent Programs
--for a particular user with the latest concurrent programs sorted in least time taken

SELECT
      f.request_id ,
      pt.user_concurrent_program_name user_conc_program_name,
      f.actual_start_date start_on,
      f.actual_completion_date end_on,
      floor(((f.actual_completion_date-f.actual_start_date)
        *24*60*60)/3600)
        || ' HOURS ' ||
        floor((((f.actual_completion_date-f.actual_start_date)
        *24*60*60) -
        floor(((f.actual_completion_date-f.actual_start_date)
        *24*60*60)/3600)*3600)/60)
        || ' MINUTES ' ||
        round((((f.actual_completion_date-f.actual_start_date)
        *24*60*60) -
        floor(((f.actual_completion_date-f.actual_start_date)
        *24*60*60)/3600)*3600 -
        (floor((((f.actual_completion_date-f.actual_start_date)
        *24*60*60) -
        floor(((f.actual_completion_date-f.actual_start_date)
        *24*60*60)/3600)*3600)/60)*60) ))
        || ' SECS ' time_difference,
      p.concurrent_program_name concurrent_program_name,
      decode(f.phase_code,'R','Running','C','Complete',f.phase_code) Phase,
      f.status_code
from  apps.fnd_concurrent_programs p,
      apps.fnd_concurrent_programs_tl pt,
      apps.fnd_concurrent_requests f
where f.concurrent_program_id = p.concurrent_program_id
      and f.program_application_id = p.application_id
      and f.concurrent_program_id = pt.concurrent_program_id
      and f.program_application_id = pt.application_id
      AND pt.language = USERENV('Lang')
      and f.actual_start_date is not null
order by
      f.actual_start_date desc;

Request_id from sid:

SELECT a.request_id, a.PHASE_CODE, a.STATUS_CODE,
d.sid as Oracle_SID,
d.serial#,
d.osuser,
d.process,
c.SPID as OS_Process_ID
FROM apps.fnd_concurrent_requests a,
apps.fnd_concurrent_processes b,
gv$process c,
gv$session d
WHERE a.controlling_manager = b.concurrent_process_id
AND c.pid = b.oracle_process_id
AND b.session_id=d.audsid AND a.PHASE_CODE='R' AND a.STATUS_CODE='R'
AND d.sid = &SID;

Request id related manager:

SELECT * FROM fnd_concurrent_processes a ,fnd_concurrent_queues_vl b,fnd_concurrent_requests c
WHERE 1=1
AND a.concurrent_queue_id = b.concurrent_queue_id
AND a.concurrent_process_id = c.controlling_manager
AND c.request_id = '&Request_id';

Requests completion date details:

SELECT request_id, TO_CHAR( request_date, 'DD-MON-YYYY HH24:MI:SS' )
request_date, TO_CHAR( requested_start_date,'DD-MON-YYYY HH24:MI:SS' )
requested_start_date, TO_CHAR( actual_start_date, 'DD-MON-YYYY HH24:MI:SS' )
actual_start_date, TO_CHAR( actual_completion_date, 'DD-MON-YYYY HH24:MI:SS' )
actual_completion_date, TO_CHAR( sysdate, 'DD-MON-YYYY HH24:MI:SS' )
current_date, ROUND( ( NVL( actual_completion_date, sysdate ) - actual_start_date ) * 24, 2 ) duration
FROM fnd_concurrent_requests
WHERE request_id = TO_NUMBER('&p_request_id');

SCHEDULED REQUESTS:

SET LINE 130 PAGESIZE 1000
COLUMN request_id FORMAT 999999999
COLUMN conc_prog_name FORMAT A47
COLUMN requestor FORMAT A18
COLUMN phase_code FORMAT A10 head 'Phase Code'
COLUMN status_code FORMAT A10 head 'Status Code'
COLUMN req_start_dt FORMAT A20 head 'Requested Start Date'
SELECT fcr.request_id
, SUBSTR(DECODE(fcp.user_concurrent_program_name, 'Report Set'
,fcp.user_concurrent_program_name || ' ' || fcr.description, fcp.user_concurrent_program_name),1,47) conc_prog_name
, fu.user_name requestor
, DECODE(fcr.phase_code, 'R'
,'Running', 'P'
,DECODE(fcr.hold_flag, 'Y'
,'Inactive', 'Pending'), 'C'
,'Completed', fcr.phase_code) phase_code
, DECODE(fcr.status_code, 'E'
,'Error', 'C'
,'Normal', 'X'
,'Terminated', 'Q'
,DECODE(fcr.hold_flag, 'Y'
,'On Hold', DECODE(SIGN(fcr.requested_start_date-SYSDATE),1
,'Scheduled','Standby')), 'D'
,'Cancelled', 'G'
,'Warning', 'R'
,'Normal', 'W'
,'Paused', 'T'
,'Terminating', 'R'
,'Normal', 'W'
,'Paused', 'T'
,'Terminating', 'I'
,'Scheduled', fcr.status_code) status_code
, TO_CHAR(fcr.requested_start_date,'DD-MON-YYYY Hh24:MI:SS') req_start_dt
FROM apps.fnd_user fu
, apps.fnd_concurrent_programs_vl fcp
, apps.fnd_concurrent_requests fcr
WHERE fcp.concurrent_program_id = fcr.concurrent_program_id
AND fcr.status_code IN ('Q', 'I')
AND fcr.phase_code = 'P'
AND fcr.requested_by = fu.user_id
ORDER BY 1
/

TO CHECK PARTICULAR PROGRAM REPORT:

set lines 180
set pages 300
SELECT to_char(a.request_id) ||'~'||
decode(to_char(parent_request_id),'-1',null,to_char(parent_request_id)) ||'~'||
a.user_concurrent_program_name ||'~'||
to_char(a.requested_start_date,'DD-MON-RR HH24:MI:SS') ||'~'||
to_char(a.actual_start_date,'DD-MON-RR HH24:MI:SS') ||'~'||
to_char(a.actual_completion_date,'DD-MON-RR HH24:MI:SS') ||'~'||
round(trunc(((actual_completion_date-actual_start_date)*24*60*60)/60)+(((actual_completion_date-actual_start_date)*24*60*60)-(trunc(((actual_completion_date-actual_start_date)*24*60*60)/60)*60))/100,2) ||'~'||
a.requestor ||'~'||
decode(a.phase_code,'R','Running','P','Inactive','C','Completed', a.phase_code) ||'~'||
decode(a.status_code,'E','Error', 'C','Normal', 'X','Terminated', 'Q','On Hold', 'D','Cancelled', 'G','Warning', 'R','Normal', 'W', 'Paused', a.status_code) ||'~'||
a.argument_text
FROM apps.fnd_conc_req_summary_v a
WHERE a.user_concurrent_program_name like ('&programname%')
order by a.user_concurrent_program_name,a.actual_start_date,a.phase_code;

TO CHECK PARTICULAR REQUEST STATUS:

set lines 180
set pages 300
col name format a20
col QUEUE for a20
col U_NAME for a20
select fcr.request_id req_id,
substr(fcq.concurrent_queue_name, 1, 20) queue,
to_char(fcr.actual_start_date,'hh24:mi') s_time,
substr(fcr.user_concurrent_program_name, 1, 60) name,
substr(fcr.requestor, 1, 9 ) u_name,
round((sysdate -actual_start_date) *24, 2) elap,
decode(fcr.phase_code,'R','Running','P','Inactive','C','Completed', fcr.phase_code) Phase,
substr(decode( fcr.status_code, 'A', 'WAITING', 'B', 'RESUMING',
'C', 'NORMAL', 'D', 'CANCELLED', 'E', 'ERROR', 'F', 'SCHEDULED',
'G', 'WARNING', 'H', 'ON HOLD', 'I', 'NORMAL', 'M', 'NO MANAGER',
'Q', 'STANDBY', 'R', 'NORMAL', 'S', 'SUSPENDED', 'T', 'TERMINATED',
'U', 'DISABLED', 'W', 'PAUSED', 'X', 'TERMINATED', 'Z', 'WAITING',
'UNKNOWN'), 1, 10)
from
apps.fnd_concurrent_queues fcq,
apps.fnd_concurrent_processes fcp,
apps.fnd_conc_req_summary_v fcr
where fcp.concurrent_queue_id = fcq.concurrent_queue_id
and fcp.queue_application_id = fcq.application_id
and fcr.controlling_manager = fcp.concurrent_process_id
and fcr.request_id = '&RequstID'
order by request_id ;

TO CHECK THE MANAGERS RUNNING OR NOT SHOULD BE ACTIVE:

set lines 180
set pages 300
col OSID for a30;
Select distinct Concurrent_Process_Id CpId, PID Opid,
Os_Process_ID Osid,
Q.Concurrent_Queue_Name Manager,
P.NODE_NAME node,
P.process_status_code Status,
To_Char(P.Process_Start_Date, 'MM-DD-YYYY HH:MI:SSAM') Started_At
from Fnd_Concurrent_Processes P, Fnd_Concurrent_Queues Q, FND_V$Process
where Q.Application_Id = Queue_Application_ID
And (Q.Concurrent_Queue_ID = P.Concurrent_Queue_ID)
And ( Spid = Os_Process_ID )
And Process_Status_Code not in ('K','S')
Order by Concurrent_Process_ID, Os_Process_Id, Q.Concurrent_Queue_Name

TO CHECK WHICH MANAGER IS RUNNING ON WHICH NODE AND MANAGER STATUS:

set verify off
set lines 256
set trims ON
set pages 60
col concurrent_queue_id format 99999 heading "QUEUE Id"
col concurrent_queue_name format a20 trunc heading "QUEUE Code"
col user_concurrent_queue_name format a30 trunc heading "Concurrent Queue Name"
col max_processes format 999 heading "Max"
col running_processes format 999 heading "Act"
col running format 999 heading "Run"
col target_node format a15 heading "Node"
col status format a12 trunc heading "Status"
col run format 9999 heading 'Run'
col pend format 9999 heading 'Pending'
col cmgr_program FOR a65;
SELECT 'Instance : '
||NAME instance_name
FROM v$database;
Prompt ===========================
Prompt concurrent manager status
Prompt ===========================
SELECT q.concurrent_queue_id,
q.concurrent_queue_name,
q.user_concurrent_queue_name,
q.target_node,
q.max_processes,
q.running_processes,
running.run running,
pending.pend,
Decode(q.control_code, 'D', 'Deactivating',
'E', 'Deactivated',
'N', 'Node unavai',
'A', 'Activating',
'X', 'Terminated',
'T', 'Terminating',
'V', 'Verifying',
'O', 'Suspending',
'P', 'Suspended',
'Q', 'Resuming',
'R', 'Restarting') status
FROM (SELECT concurrent_queue_name,
COUNT(phase_code) run
FROM fnd_concurrent_worker_requests
WHERE phase_code = 'R'
AND hold_flag != 'Y'
AND requested_start_date <= SYSDATE GROUP BY concurrent_queue_name) running, (SELECT concurrent_queue_name, COUNT(phase_code) pend FROM fnd_concurrent_worker_requests WHERE phase_code = 'P' AND hold_flag != 'Y' AND requested_start_date <= SYSDATE GROUP BY concurrent_queue_name) pending, apps.fnd_concurrent_queues_vl q WHERE q.concurrent_queue_name = running.concurrent_queue_name(+) AND q.concurrent_queue_name = pending.concurrent_queue_name(+) AND q.enabled_flag = 'Y' ORDER BY Decode(q.application_id, 0, Decode(q.concurrent_queue_id, 1, 1,4, 2)), Sign(q.max_processes) DESC, q.concurrent_queue_name, q.application_id;

To find child requests for Parent request id:

set lines 200
col USER_CONCURRENT_PROGRAM_NAME for a40
col PHASE_CODE for a10
col STATUS_CODE for a10
col COMPLETION_TEXT for a20
SELECT sum.request_id,req.PARENT_REQUEST_ID,sum.user_concurrent_program_name, DECODE(sum.phase_code,'C','Completed',sum.phase_code) phase_code, DECODE(sum.status_code,'D', 'Cancelled' ,
'E', 'Error' , 'G', 'Warning', 'H','On Hold' , 'T', 'Terminating', 'M', 'No Manager' , 'X', 'Terminated',  'C', 'Normal', sum.status_code) status_code, sum.actual_start_date, sum.actual_completion_date, sum.completion_text FROM apps.fnd_conc_req_summary_v sum, apps.fnd_concurrent_requests req where  req.request_id=sum.request_id and req.PARENT_REQUEST_ID = '&parent_concurrent_request_id';


set col os_process_id for 99
select HAS_SUB_REQUEST, is_SUB_REQUEST, parent_request_id, ORACLE_PROCESS_ID, ORACLE_SESSION_ID, OS_PROCESS_ID from fnd_concurrent_requests where request_id= '&Req_ID' ;

To find concurrent program name,phase code,status code for a given request id:

SELECT request_id, user_concurrent_program_name, DECODE(phase_code,'C','Completed',phase_code) phase_code, DECODE(status_code,'D', 'Cancelled' ,
'E', 'Error' , 'G', 'Warning', 'H','On Hold' , 'T', 'Terminating', 'M', 'No Manager' , 'X', 'Terminated',  'C', 'Normal', status_code) status_code, to_char(actual_start_date,'dd-mon-yy:hh24:mi:ss') Start_Date, to_char(actual_completion_date,'dd-mon-yy:hh24:mi:ss'), completion_text FROM apps.fnd_conc_req_summary_v WHERE request_id = '&req_id' ORDER BY 6 DESC;

To find the pid of the Concurrent job and kill it:

Select a.inst_id, sid, b.spid 
from gv$session a, gv$process b,apps.fnd_concurrent_requests c where a.paddr = b.addr and request_ID ='31689665'  
AND a.inst_id = b.inst_id and c.os_process_id = a.process;
-- Query 13:To find the Database SID of the Concurrent job
-- We need our concurrent request ID as an input.
-- c.SPID= is the operating system process id
-- d.sid= is the Oracle process id
SQL> column process heading "FNDLIBR PID"
SELECT a.request_id, d.sid, d.serial# ,d.osuser,d.process , c.SPID
FROM apps.fnd_concurrent_requests a,
apps.fnd_concurrent_processes b,
v$process c,
v$session d
WHERE a.controlling_manager = b.concurrent_process_id
AND c.pid = b.oracle_process_id
AND b.session_id=d.audsid
AND a.request_id = &Request_ID
AND a.phase_code = 'R';

To find the sql query for a given concurrent request sid:

select sid,sql_text from gv$session ses, gv$sqlarea sql where 
ses.sql_hash_value = sql.hash_value(+) and ses.sql_address = sql.address(+) and ses.sid='&oracle_sid'

TO FINDOUT PAST ONE MONTH HISTORY:

set pause off
set pagesize 2000
set linesize 120
set wrap off
column user_concurrent_program_name format a45 noprint
column argument_text format a45 print
column user_name format a15
column start_time format a15
column end_time format a15
column comp_time format 9999.99
select request_id,
user_concurrent_program_name,
to_char(actual_start_date,'DD/MON HH24:MI:SS') START_TIME,
to_char(ACTUAL_COMPLETION_DATE,'DD/MON HH24:MI:SS') END_TIME,
(actual_completion_date-actual_start_date)*24*60 comp_time, argument_text,user_name, status_code, phase_code
from apps.fnd_concurrent_requests, apps.fnd_concurrent_programs_tl,apps.fnd_user
where fnd_concurrent_requests.concurrent_program_id = fnd_concurrent_programs_tl.concurrent_program_id
and user_concurrent_program_name like '%Gather Schema%'
and fnd_concurrent_programs_tl.language='US'
and requested_by=user_id
order by actual_start_date desc,ACTUAL_COMPLETION_DATE desc;

TO FINDOUT THE ICM CURRENT LOGFILE NAME AND LOCATION:

SELECT 'LOG=' || fcp.logfile_name LogFile
FROM fnd_concurrent_processes fcp, fnd_concurrent_queues fcq
WHERE fcp.concurrent_queue_id = fcq.concurrent_queue_id
AND fcp.queue_application_id = fcq.application_id
AND fcq.manager_type = '0'AND fcp.process_status_code = 'A';

TO FINDOUT THE REQUEST LOGFILE NAME AND LOCATION:

SELECT REQUEST_ID,logfile_name, outfile_name, outfile_node_name, last_update_date FROM apps.FND_CONCURRENT_REQUESTS WHERE REQUEST_ID =&Req_ID; 

TO FINDOUT THE TRACEFILE OF A PARTICULAR REQUEST:

column traceid format a8
column tracename format a80
column user_concurrent_program_name format a40
column execname format a15
column enable_trace format a12
set lines 80
set pages 22
set head off
SELECT 'Request id: '||request_id ,
'Trace id: '||oracle_Process_id,
'Trace Flag: '||req.enable_trace,
'Trace Name:
'||dest.value||'/'||lower(dbnm.value)||'_ora_'||oracle_process_id||'.trc',
'Prog. Name: '||prog.user_concurrent_program_name,
'File Name: '||execname.execution_file_name|| execname.subroutine_name ,
'Status : '||decode(phase_code,'R','Running')
||'-'||decode(status_code,'R','Normal'),
'SID Serial: '||ses.sid||','|| ses.serial#,
'Module : '||ses.module
from apps.fnd_concurrent_requests req, v$session ses, v$process proc,
v$parameter dest, v$parameter dbnm, apps.fnd_concurrent_programs_vl prog,
apps.fnd_executables execname
where req.request_id = '&request'
and req.oracle_process_id=proc.spid(+)
and proc.addr = ses.paddr(+)
and dest.name='user_dump_dest'
and dbnm.name='db_name'
and req.concurrent_program_id = prog.concurrent_program_id
and req.program_application_id = prog.application_id
and prog.application_id = execname.application_id
and prog.executable_id=execname.executable_id;

TO FINDOUT WHICH MANAGER RAN THE REQUEST:

select b.USER_CONCURRENT_QUEUE_NAME from fnd_concurrent_processes a, 
fnd_concurrent_queues_vl b, fnd_concurrent_requests c
where a.CONCURRENT_QUEUE_ID = b.CONCURRENT_QUEUE_ID
and a.CONCURRENT_PROCESS_ID = c.controlling_manager
and c.request_id = '&requistno';

TO KNOW THE REQUEST SINCE HOW LONG ITS RUNNING:

select user_concurrent_program_name,request_id,status_code,phase_code,to_char(actual_start_date,'DD-MON-YY HH24:MI:SS'),to_char(actual_completion_date,'DD-MON-YY HH24:MI:SS') from apps.fnd_conc_req_summary_v where request_id='&Requstno';

To terminate the all concurrent requests using by Module wise:

select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate;' from gv$session where MODULE like 'GLPREV';

USAGE REPORT FOR TODAY:

SET PAGES 900
SELECT fcr.cnt "Conc Reqs"
, icxs.self_serv_user_COUNT "SelfServ Users"
, icxs.self_serv_session_COUNT "SelfServ Sessions"
, fl.forms_user_COUNT "Forms Users"
, fl.forms_session_COUNT "Forms Sessions"
FROM (SELECT COUNT(distinct user_id) self_serv_user_COUNT
, COUNT(*) self_serv_session_COUNT
FROM icx.icx_sessions
WHERE TRUNC(creation_date) = TRUNC(SYSDATE-1)) icxs,
(SELECT COUNT(distinct user_id) forms_user_COUNT
, COUNT(*) forms_session_COUNT
FROM applsys.fnd_logins
WHERE TRUNC(start_time) = TRUNC(SYSDATE-1)) fl,
(SELECT COUNT(*) cnt
FROM apps.fnd_concurrent_requests
WHERE TRUNC(actual_start_date) = TRUNC(SYSDATE-1) ) fcr
/

wait events details related with Concurrent programs:

SELECT s.saddr, s.SID, s.serial#, s.audsid, s.paddr, s.user#, s.username,
s.command, s.ownerid, s.taddr, s.lockwait, s.status, s.server,
s.schema#, s.schemaname, s.osuser, s.process, s.machine, s.terminal,
UPPER (s.program) program, s.TYPE, s.sql_address, s.sql_hash_value,
s.sql_id, s.sql_child_number, s.sql_exec_start, s.sql_exec_id,
s.prev_sql_addr, s.prev_hash_value, s.prev_sql_id,
s.prev_child_number, s.prev_exec_start, s.prev_exec_id,
s.plsql_entry_object_id, s.plsql_entry_subprogram_id,
s.plsql_object_id, s.plsql_subprogram_id, s.module, s.module_hash,
s.action, s.action_hash, s.client_info, s.fixed_table_sequence,
s.row_wait_obj#, s.row_wait_file#, s.row_wait_block#,
s.row_wait_row#, s.logon_time, s.last_call_et, s.pdml_enabled,
s.failover_type, s.failover_method, s.failed_over,
s.resource_consumer_group, s.pdml_status, s.pddl_status, s.pq_status,
s.current_queue_duration, s.client_identifier,
s.blocking_session_status, s.blocking_instance, s.blocking_session,
s.seq#, s.event#, s.event, s.p1text, s.p1, s.p1raw, s.p2text, s.p2,
s.p2raw, s.p3text, s.p3, s.p3raw, s.wait_class_id, s.wait_class#,
s.wait_class, s.wait_time, s.seconds_in_wait, s.state,
s.wait_time_micro, s.time_remaining_micro,
s.time_since_last_wait_micro, s.service_name, s.sql_trace,
s.sql_trace_waits, s.sql_trace_binds, s.sql_trace_plan_stats,
s.session_edition_id, s.creator_addr, s.creator_serial#
FROM v$session s
WHERE ( (s.username IS NOT NULL)
AND (NVL (s.osuser, 'x') <> 'SYSTEM')
AND (s.TYPE <> 'BACKGROUND') AND STATUS='ACTIVE'
)
ORDER BY "PROGRAM";

Which Manager Ran a Specific Concurrent Request:

 col USER_CONCURRENT_QUEUE_NAME for a100
select b.USER_CONCURRENT_QUEUE_NAME from fnd_concurrent_processes a,
fnd_concurrent_queues_vl b, fnd_concurrent_requests c
where a.CONCURRENT_QUEUE_ID = b.CONCURRENT_QUEUE_ID
and a.CONCURRENT_PROCESS_ID = c.controlling_manager
and c.request_id = '&conc_reqid';

SQL TO FIND OUT CONCURRENT REQUESTS CURRENTLY RUNNING:

set lines 180
set pages 1000
set verify off
undef spid
column req_id format 99999999999
column OPID format a10
column PPID format a8
column SPID format a8
column ST_CD format a1
column ph_cd format a1
column CNAME format a30
column event format a15
column user_name format a10
column program format a8
column serial# format 999999
column sid format 9999
column username format a8
select a.request_id "REQ_ID",a.oracle_process_id "OPID",a.os_process_id "PPID",
e.user_concurrent_program_name "CNAME",
f.user_name,a.status_code "ST_CD",a.phase_code "PH_CD", b.username,b.sid,
b.serial#,b.program,g.event,
to_char(a.ACTUAL_START_DATE,'MON-DD-HH-MI-SS') START_DATE,
to_char(a.ACTUAL_COMPLETION_DATE,'MON-DD-HH-MI-SS') COMPL_DATE
from apps.fnd_concurrent_requests a,(select c.username,c.sid,c.serial#,
                        c.program,d.spid from v$session c, v$process d
                        where c.paddr=d.addr) b,
                        apps.fnd_concurrent_programs_tl e,
                        apps.fnd_user f,
                        v$session_wait g
                        where a.oracle_process_id=b.spid
                        and a.concurrent_program_id=e.concurrent_program_id
                        and e.language='US'
                        and a.requested_by=f.user_id
                        and b.sid=g.sid
            and a.status_code='R'
            and a.phase_code='R';

SQL TO FIND CONCURRENT REQUEST SID,OS PROCESS DETAILS BY REQUEST ID:

select a.argument_text, a.phase_code, a.status_code, a.oracle_process_id "DB_PROCESS", a.OS_PROCESS_ID "MT_PROCESS", f.user_name
from apps.fnd_concurrent_requests a, apps.fnd_user f where request_id='&REQUEST_ID' and a.requested_by=f.user_id;
OR 
==
SELECT C.SID, C.SERIAL#, A.PID
FROM   GV$PROCESS A, FND_CONCURRENT_REQUESTS B, GV$SESSION C
WHERE  B.ORACLE_PROCESS_ID = A.SPID
-- AND    B.REQUEST_ID like '%'
AND    B.REQUEST_ID ='&x'
AND    A.ADDR=C.PADDR;

SQL TO FIND THE CONCURRENT REQUEST TRACE FILE DETAILS (Input Request ID):

SELECT 'Request id: '||request_id ,
'Trace id: '||oracle_Process_id,
'Trace Flag: '||req.enable_trace,
'Trace Name: '||dest.value||'/'||lower(dbnm.value)||'_ora_'||oracle_process_id|
|'.trc',
--'Prog. Name: '||prog.user_concurrent_program_name,
'File Name: '||execname.execution_file_name|| execname.subroutine_name ,
'Status : '||decode(phase_code,'R','Running') ||'-'||decode(status_code,'R','Normal'),
'SID Serial: '||ses.sid||','|| ses.serial#, 'Module : '||ses.module
from
fnd_concurrent_requests req,
v$session ses,
v$process proc,
v$parameter dest,
v$parameter dbnm,
fnd_concurrent_programs_vl prog,
fnd_executables execname where req.request_id = &request
and req.oracle_process_id=proc.spid(+)
and proc.addr = ses.paddr(+)
and dest.name='user_dump_dest'
and dbnm.name='db_name'
and req.concurrent_program_id = prog.concurrent_program_id
and req.program_application_id = prog.application_id
and prog.application_id = execname.application_id
and prog.executable_id=execname.executable_id ;
Concurrent Manager_request-SID & Serial# find script:

SELECT ses.sid, ses.serial# 
FROM v$session ses, 
v$process pro 
WHERE ses.paddr = pro.addr 
AND pro.spid IN (SELECT oracle_process_id 
FROM FND_CONCURRENT_REQUESTS 
WHERE request_id ='&request_id'); 
SELECT a.request_id, d.sid, d.serial# ,d.osuser,d.process , c.SPID
FROM apps.fnd_concurrent_requests a,
apps.fnd_concurrent_processes b,
v$process c,
v$session d
WHERE a.controlling_manager = b.concurrent_process_id
AND c.pid = b.oracle_process_id
AND b.session_id=d.audsid
AND a.request_id = '&Request_ID'
AND a.phase_code = 'R';

Find out  OSPID:

select os_process_id from fnd_concurrent_requests where request_id ='&request_id';
select request_id, phase_code, status_code, oracle_process_id from fnd_concurrent_requests where request_id ='&request_id';

SQL> ALTER SYSTEM KILL SESSION ' 1114, 8017' IMMEDIATE;
System altered.

Issue: Request is in pending from long time,
Action:
#First Terminate the Request as follows
update fnd_concurrent_requests
   set status_code='X', phase_code='C'
   where request_id="";
commit;

#Then change the status with Completed-Error as follows.
update fnd_concurrent_requests
   set status_code='E', phase_code='C'
   where request_id=31783706;
commit;

This will change the status of any request.
Status Code
E -  Error
X -  Terminate
G -  Warning

update applsys.fnd_concurrent_requests
set phase_code = 'C',
STATUS_CODE = 'X'
where request_id = '&Req_id';
Commit;

 Query to find concurrent program:

    select frt.responsibility_name, frg.request_group_name,
    frgu.request_unit_type,frgu.request_unit_id,
    fcpt.user_concurrent_program_name
    From fnd_Responsibility fr, fnd_responsibility_tl frt,
    fnd_request_groups frg, fnd_request_group_units frgu,
    fnd_concurrent_programs_tl fcpt
    where frt.responsibility_id = fr.responsibility_id
    and frg.request_group_id = fr.request_group_id
    and frgu.request_group_id = frg.request_group_id
    and fcpt.concurrent_program_id = frgu.request_unit_id
    and frt.language = USERENV('LANG')
    and fcpt.language = USERENV('LANG')
    and fcpt.user_concurrent_program_name = :conc_prg_name
    order by 1,2,3,4

 Query to find Request Set:

    select frt.responsibility_name, frg.request_group_name,
    frgu.request_unit_type,frgu.request_unit_id,
    fcpt.user_request_set_name
    From apps.fnd_Responsibility fr, apps.fnd_responsibility_tl frt,
    apps.fnd_request_groups frg, apps.fnd_request_group_units frgu,
    apps.fnd_request_Sets_tl fcpt
    where frt.responsibility_id = fr.responsibility_id
    and frg.request_group_id = fr.request_group_id
    and frgu.request_group_id = frg.request_group_id
    and fcpt.request_set_id = frgu.request_unit_id
    and frt.language = USERENV('LANG')
    and fcpt.language = USERENV('LANG')
    and fcpt.user_request_set_name = :request_set_name
    order by 1,2,3,4
Concurrent Request Error Script:

SELECT a.request_id "Req Id"
,a.phase_code,a.status_code
, actual_start_date
, actual_completion_date
,c.concurrent_program_name || ': ' || ctl.user_concurrent_program_name "program"
FROM APPLSYS.fnd_Concurrent_requests a,APPLSYS.fnd_concurrent_processes b
,applsys.fnd_concurrent_queues q
,APPLSYS.fnd_concurrent_programs c
,APPLSYS.fnd_concurrent_programs_tl ctl
WHERE a.controlling_manager = b.concurrent_process_id
AND a.concurrent_program_id = c.concurrent_program_id
AND a.program_application_id = c.application_id
AND a.status_code = 'E'
AND a.phase_code = 'C'
AND actual_start_date > sysdate - 7
AND b.queue_application_id = q.application_id
AND b.concurrent_queue_id = q.concurrent_queue_id
AND ctl.concurrent_program_id = c.concurrent_program_id
AND CTL.LANGUAGE = 'US'
ORDER BY 5 DESC;

History of concurrent requests which are error out :

SELECT a.request_id "Req Id"
,a.phase_code,a.status_code
, actual_start_date
, actual_completion_date
,c.concurrent_program_name || ': ' || ctl.user_concurrent_program_name "program"
FROM APPLSYS.fnd_Concurrent_requests a,APPLSYS.fnd_concurrent_processes b
,applsys.fnd_concurrent_queues q
,APPLSYS.fnd_concurrent_programs c
,APPLSYS.fnd_concurrent_programs_tl ctl
WHERE a.controlling_manager = b.concurrent_process_id
AND a.concurrent_program_id = c.concurrent_program_id
AND a.program_application_id = c.application_id
AND a.status_code = 'E'
AND a.phase_code = 'C'
AND actual_start_date > sysdate - 2
AND b.queue_application_id = q.application_id
AND b.concurrent_queue_id = q.concurrent_queue_id
AND ctl.concurrent_program_id = c.concurrent_program_id
AND ctl.LANGUAGE = 'US'
ORDER BY 5 DESC; 

SQL to find out the Raw trace name and location for the concurrent program:

SELECT 
req.request_id
,req.logfile_node_name node
,req.oracle_Process_id
,req.enable_trace
,dest.VALUE||'/'||LOWER(dbnm.VALUE)||'_ora_'||oracle_process_id||'.trc' trace_filename
,prog.user_concurrent_program_name
,execname.execution_file_name
,execname.subroutine_name 
,phase_code 
,status_code
,ses.SID
,ses.serial#
,ses.module
,ses.machine
FROM 
fnd_concurrent_requests req
,v$session ses
,v$process proc
,v$parameter dest
,v$parameter dbnm
,fnd_concurrent_programs_vl prog
,fnd_executables execname
WHERE 1=1
AND req.request_id = &request
AND req.oracle_process_id=proc.spid(+)
AND proc.addr = ses.paddr(+)
AND dest.NAME='user_dump_dest'
AND dbnm.NAME='db_name'
AND req.concurrent_program_id = prog.concurrent_program_id
AND req.program_application_id = prog.application_id
AND PROG.APPLICATION_ID = EXECNAME.APPLICATION_ID
AND prog.executable_id=execname.executable_id;

Trace file Including SID:

SELECT 'Request id: '||request_id ,  'Trace id: '||oracle_Process_id,  'Trace Flag: '||req.enable_trace,  
'Trace Name:  '||dest.value||'/'||lower(dbnm.value)||'_ora_'||oracle_process_id||'.trc',  'Prog. Name: '
||prog.user_concurrent_program_name,  'File Name: '||execname.execution_file_name|| execname.subroutine_name , 
'Status : '||decode(phase_code,'R','Running')  ||'-'||decode(status_code,'R','Normal'), 
'SID Serial: '||ses.sid||','|| ses.serial#,  'Module : '||ses.module  from fnd_concurrent_requests req,
v$session ses, v$process proc,  v$parameter dest, v$parameter dbnm, fnd_concurrent_programs_vl prog,  
fnd_executables execname  where req.request_id = &request  
and req.oracle_process_id=proc.spid(+)  
and proc.addr = ses.paddr(+)  and dest.name='user_dump_dest'  and dbnm.name='db_name'  
and req.concurrent_program_id = prog.concurrent_program_id  and req.program_application_id = prog.application_id  
and prog.application_id = execname.application_id  and prog.executable_id=execname.executable_id; 

To check the timeline of the request :

SELECT request_id, TO_CHAR( request_date, 'DD-MON-YYYY HH24:MI:SS' ) 
request_date, TO_CHAR( requested_start_date,'DD-MON-YYYY HH24:MI:SS' ) 
requested_start_date, TO_CHAR( actual_start_date, 'DD-MON-YYYY HH24:MI:SS' ) 
actual_start_date, TO_CHAR( actual_completion_date, 'DD-MON-YYYY HH24:MI:SS' ) 
actual_completion_date, TO_CHAR( sysdate, 'DD-MON-YYYY HH24:MI:SS' ) 
current_date, ROUND( ( NVL( actual_completion_date, sysdate ) - actual_start_date ) * 24, 2 ) duration 
FROM FND_CONCURRENT_REQUESTS 
WHERE request_id = TO_NUMBER('&p_request_id');

 Find out Concurrent Program which enable with trace:

col User_Program_Name for a40
col Last_Updated_By for a30
col DESCRIPTION for a30
SELECT A.CONCURRENT_PROGRAM_NAME "Program_Name",
SUBSTR(A.USER_CONCURRENT_PROGRAM_NAME,1,40) "User_Program_Name",
SUBSTR(B.USER_NAME,1,15) "Last_Updated_By",
SUBSTR(B.DESCRIPTION,1,25) DESCRIPTION
FROM APPS.FND_CONCURRENT_PROGRAMS_VL A, APPLSYS.FND_USER B
WHERE A.ENABLE_TRACE='Y'
AND A.LAST_UPDATED_BY=B.USER_ID;

Scheduled Concurrent Requests SQL query:

SELECT fl.meaning
     , fu.user_name
     , fu.description requestor
     , fu.end_date
     , NVL(fu.email_address, 'n/a') email_address
     , fcr.request_id
     , fcr.number_of_copies
     , fcr.printer
     , fcr.request_date
     , fcr.requested_start_date
     , fcp.description
     , fcr.argument_text
     , frt.responsibility_name
  FROM apps.fnd_concurrent_requests fcr
     , apps.fnd_user fu
     , apps.fnd_lookups fl
     , apps.fnd_concurrent_programs_vl fcp
     , apps.fnd_responsibility_tl frt
 WHERE fcr.requested_by = fu.user_id
   AND fl.lookup_type = 'CP_STATUS_CODE'
   AND fcr.status_code = fl.lookup_code
   AND fcr.program_application_id = fcp.application_id
   AND fcr.concurrent_program_id = fcp.concurrent_program_id
   AND fcr.responsibility_id = frt.responsibility_id
   AND fcr.phase_code = 'P'

Status Code:
select lookup_code,meaning from fnd_lookups where lookup_type = 'CP_STATUS_CODE'order by lookup_code;

Phase Code:
Select lookup_code,meaning from fnd_lookups where lookup_type = 'CP_PHASE_CODE';

To find concurrent program name,phase code,status code for a given request id?

SELECT request_id, user_concurrent_program_name, DECODE(phase_code,'C','Completed',phase_code) phase_code, DECODE(status_code,'D', 'Cancelled' ,
'E', 'Error' , 'G', 'Warning', 'H','On Hold' , 'T', 'Terminating', 'M', 'No Manager' , 'X', 'Terminated',  'C', 'Normal', status_code) status_code,
 to_char(actual_start_date,'dd-mon-yy:hh24:mi:ss') Start_Date, to_char(actual_completion_date,'dd-mon-yy:hh24:mi:ss'), completion_text 
 FROM apps.fnd_conc_req_summary_v WHERE request_id = '&req_id' ORDER BY 6 DESC;
 Concurrent Manager Actual Target Process finding script :

SELECT DECODE(CONCURRENT_QUEUE_NAME,'FNDICM','Internal Manager','FNDCRM','Conflict Resolution Manager','AMSDMIN',
 'Marketing Data Mining Manager','C_AQCT_SVC','C AQCART Service','FFTM','FastFormula Transaction Manager',
 'FNDCPOPP','Output Post Processor','FNDSCH','Scheduler/Prereleaser Manager',
 'FNDSM_AQHERP','Service Manager: AQHERP','FTE_TXN_MANAGER','Transportation Manager',
 'IEU_SH_CS','Session History Cleanup','IEU_WL_CS','UWQ Worklist Items Release for Crashed session',
 'INVMGR','Inventory Manager','INVTMRPM','INV Remote Procedure Manager','OAMCOLMGR','OAM Metrics Collection Manager',
 'PASMGR','PA Streamline Manager','PODAMGR','PO Document Approval Manager','RCVOLTM','Receiving Transaction Manager',
 'STANDARD','Standard Manager','WFALSNRSVC','Workflow Agent Listener Service','WFMLRSVC','Workflow Mailer Service',
 'WFWSSVC','Workflow Document Web Services Service','WMSTAMGR','WMS Task Archiving Manager','XDP_APPL_SVC','SFM Application Monitoring Service',
 'XDP_CTRL_SVC','SFM Controller Service','XDP_Q_EVENT_SVC','SFM Event Manager Queue Service',
 'XDP_Q_FA_SVC','SFM Fulfillment Actions Queue Service','XDP_Q_FE_READY_SVC','SFM Fulfillment Element Ready Queue Service',
 'XDP_Q_IN_MSG_SVC','SFM Inbound Messages Queue Service','XDP_Q_ORDER_SVC','SFM Order Queue Service',
 'XDP_Q_TIMER_SVC','SFM Timer Queue Service','XDP_Q_WI_SVC','SFM Work Item Queue Service','XDP_SMIT_SVC','SFM SM Interface Test Service') 
 AS "Concurrent Manager's Name", MAX_PROCESSES AS "TARGET Processes", RUNNING_PROCESSES AS "ACTUAL Processes" 
 FROM APPS.FND_CONCURRENT_QUEUES WHERE CONCURRENT_QUEUE_NAME IN ('FNDICM','FNDCRM','AMSDMIN','C_AQCT_SVC','FFTM','FNDCPOPP','FNDSCH',
 'FNDSM_AQHERP','FTE_TXN_MANAGER','IEU_SH_CS','IEU_WL_CS','INVMGR','INVTMRPM','OAMCOLMGR','PASMGR','PODAMGR','RCVOLTM','STANDARD',
 'WFALSNRSVC','WFMLRSVC','WFWSSVC','WMSTAMGR','XDP_APPL_SVC','XDP_CTRL_SVC','XDP_Q_EVENT_SVC','XDP_Q_FA_SVC','XDP_Q_FE_READY_SVC',
 'XDP_Q_IN_MSG_SVC','XDP_Q_ORDER_SVC','XDP_Q_TIMER_SVC','XDP_Q_WI_SVC','XDP_SMIT_SVC');

 This script will list running concurrent requests:

SELECT SUBSTR(LTRIM(req.request_id),1,15) concreq,
       SUBSTR(proc.os_process_id,1,15) clproc,
       SUBSTR(LTRIM(proc.oracle_process_id),1,15) opid,
       SUBSTR(look.meaning,1,10) reqph,
       SUBSTR(look1.meaning,1,10) reqst,
       SUBSTR(vsess.username,1,10) dbuser,
       SUBSTR(vproc.spid,1,10) svrproc,
       vsess.sid sid,
       vsess.serial# serial#
FROM   fnd_concurrent_requests req,
       fnd_concurrent_processes proc,
       fnd_lookups look,
       fnd_lookups look1,
       v$process vproc,
       v$session vsess
WHERE  req.controlling_manager = proc.concurrent_process_id(+)
AND    req.status_code = look.lookup_code
AND    look.lookup_type = 'CP_STATUS_CODE'
AND    req.phase_code = look1.lookup_code
AND    look1.lookup_type = 'CP_PHASE_CODE'
AND    look1.meaning = 'Running'
AND    PROC.ORACLE_PROCESS_ID = VPROC.PID(+)
AND    vproc.addr = vsess.paddr(+);

This script will map concurrent request information about a specific request id:

SELECT SUBSTR(LTRIM(req.request_id),1,15) concreq,
       SUBSTR(proc.os_process_id,1,15) clproc,
       SUBSTR(LTRIM(proc.oracle_process_id),1,15) opid,
       SUBSTR(look.meaning,1,10) reqph,
       SUBSTR(look1.meaning,1,10) reqst,
       SUBSTR(vsess.username,1,10) dbuser,
       SUBSTR(vproc.spid,1,10) svrproc
  FROM fnd_concurrent_requests req,
       fnd_concurrent_processes proc,
       fnd_lookups look,
       fnd_lookups look1,
       v$process vproc,
       v$session vsess
 WHERE req.controlling_manager = proc.concurrent_process_id(+)
   AND req.status_code = look.lookup_code
   AND look.lookup_type = 'CP_STATUS_CODE'
   AND req.phase_code = look1.lookup_code
   AND look1.lookup_type = 'CP_PHASE_CODE'
   AND req.request_id = &&reqid
   AND proc.oracle_process_id = vproc.pid(+)
   AND vproc.addr = vsess.paddr(+);
  
   
Query to display session information:

 SELECT a.username usr,
       a.sid sid,
       a.status status,
       a.server server,
       a.schemaname schema,
       b.username sosusr,
       b.spid spid,
       a.osuser cosusr,
       a.process process,
       a.machine machine,
       a.terminal terminal,
       a.program program
  FROM v$session a,
       v$process b
 WHERE a.type != 'BACKGROUND'
   AND a.paddr = b.addr
 ORDER BY a.status DESC
/

To Get Long Running Concurrent Programs:

SELECT   fcr.oracle_session_id
        ,fcr.request_id rqst_id
        ,fcr.requested_by rqst_by
        ,fu.user_name
        ,fr.responsibility_name
        ,fcr.concurrent_program_id cp_id
        ,fcp.user_concurrent_program_name cp_name
        ,TO_CHAR (fcr.actual_start_date, 'DD-MON-YYYY HH24:MI:SS')act_start_datetime
        ,DECODE (fcr.status_code, 'R', 'R:Running', fcr.status_code) status
        ,ROUND (((SYSDATE - fcr.actual_start_date) * 60 * 24), 2) runtime_min
        ,ROUND (((SYSDATE - fcr.actual_start_date) * 60 * 60 * 24), 2)runtime_sec
        ,fcr.oracle_process_id "oracle_pid/SPID"
        ,fcr.os_process_id os_pid
        ,fcr.argument_text
        ,fcr.outfile_name
        ,fcr.logfile_name
        ,fcr.enable_trace
    FROM apps.fnd_concurrent_requests fcr
        ,apps.fnd_user fu
        ,apps.fnd_responsibility_tl fr
        ,apps.fnd_concurrent_programs_tl fcp
   WHERE fcr.status_code LIKE 'R'
     AND fu.user_id = fcr.requested_by
     AND fr.responsibility_id = fcr.responsibility_id
     AND fcr.concurrent_program_id = fcp.concurrent_program_id
     AND fcr.program_application_id = fcp.application_id
     AND ROUND (((SYSDATE - fcr.actual_start_date) * 60 * 24), 2) > 60
ORDER BY fcr.concurrent_program_id
        ,request_id DESC;
 
To Get SID, Serial# & SPID:

SELECT s.sid , s.serial# ,p.spid FROM apps.fnd_concurrent_requests f,v$session s , v$process p
WHERE f.request_id = 150332400
AND f.oracle_process_id = p.spid
AND p.addr = s.paddr;
--EXEC DBMS_SYSTEM.SET_EV(1033 , 19376 ,10046, 12 ,'');
/*To Get Current Running SQL*/
SELECT t.sql_text FROM v$sqltext t , v$session s , v$process p 
WHERE p.spid = 8072
AND p.addr = s.paddr
AND t.hash_value = s.sql_hash_value
ORDER BY piece;

To Know The Current Wait Event:

SELECT * FROM v$session_wait WHERE sid=1322;
/*To Get The Overall Wait Event Statistics*/
SELECT event ,ROUND(time_waited/6000,2) Time_Wait ,total_waits
FROM v$session_event
WHERE sid =678
ORDER BY time_waited/6000 DESC;

 To Get The Running History Of A Concurrent Program:

SELECT FCR.Oracle_Session_Id , FCR.request_id RQST_ID, FCR.requested_by RQST_BY, FU.user_name, FR.responsibility_name,
       FCR.concurrent_program_id CP_ID, FCP.user_concurrent_program_name CP_NAME,
       TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS') Act_Start_DateTime,
    SYSDATE,
       DECODE(FCR.status_code,'C','C:Completed',
                              'G','G:Warning',
                              'E','E:Error',FCR.status_code) Status,
       TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') Act_End_DateTime,
       ROUND(((FCR.actual_completion_date - FCR.actual_start_date)*60*24),2) Runtime_Min,
       ROUND(((FCR.actual_completion_date - FCR.actual_start_date)*60*60*24),2) Runtime_Sec,
       FCR.oracle_process_id "oracle_pid/SPID", FCR.os_process_id os_pid, FCR.argument_text,
       FCR.OUTFILE_NAME,FCR.LOGFILE_NAME,FCR.ENABLE_TRACE    
 FROM apps.fnd_concurrent_requests FCR, apps.fnd_user FU,
     apps.fnd_responsibility_tl FR, apps.fnd_concurrent_programs_tl FCP
  WHERE --fcr.request_id = 150336946
        fcp.user_concurrent_program_name LIKE 'Unisys A/P Standard VAT Audit Trail Report'
  AND FU.user_id = FCR.requested_by
  AND FR.responsibility_id = FCR.responsibility_id
  AND FCR.concurrent_program_id = FCP.concurrent_program_id
  AND FCR.program_application_id = FCP.application_id
ORDER BY FCR.concurrent_program_id,request_id DESC;
SELECT * FROM fnd_concurrent_requests WHERE request_id = 150331168;

To Get The Running History Of A Concurrent Program--modified:

SELECT   fcr.oracle_session_id o_sid
        ,ROUND ((  (  NVL (fcr.actual_completion_date, SYSDATE)- fcr.actual_start_date)* 60* 24),2) runtime_min
        ,fcr.request_id rqst_id
--        ,fcr.requested_by rqst_by
        ,fu.user_name usern
        ,fr.responsibility_name
--        ,fcr.concurrent_program_id cp_id
        ,fcp.user_concurrent_program_name cp_name
        ,TO_CHAR (fcr.actual_start_date, 'DD-MON-YYYY HH24:MI:SS') start_time
        ,DECODE (fcr.status_code ,'C', 'C:Completed','G', 'G:Warning','E', 'E:Error','Q','Q:Queued',fcr.status_code) status
        ,TO_CHAR (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS')end_time
        ,ROUND ((  (  NVL (fcr.actual_completion_date, SYSDATE)- fcr.actual_start_date)* 60* 60* 24),2) runtime_sec
        ,fcr.oracle_process_id "oracle_pid/SPID"
        ,fcr.os_process_id os_pid
        ,fcr.argument_text
        ,fcr.outfile_name
        ,fcr.logfile_name
        ,fcr.enable_trace
    FROM apps.fnd_concurrent_requests fcr
        ,apps.fnd_user fu
        ,apps.fnd_responsibility_tl fr
        ,apps.fnd_concurrent_programs_tl fcp
   WHERE --fcr.request_id = 150336946
        fcp.user_concurrent_program_name LIKE 'Unisys Customer Re-Tiering Open Orders Report'
       --AND TO_CHAR (fcr.actual_start_date, 'DD-MON-YYYY') IN ('04-MAR-2008','05-MAR-2008','06-MAR-2008')
     --AND ROUND (((fcr.actual_completion_date - fcr.actual_start_date) * 60 * 24),2) > 60
     AND fr.responsibility_id = fcr.responsibility_id
     AND fcr.concurrent_program_id = fcp.concurrent_program_id
     AND fcr.program_application_id = fcp.application_id
     AND fu.user_id = fcr.requested_by
     --AND (fcr.status_code IN ('R','Q'))
ORDER BY fcr.concurrent_program_id
        ,request_id DESC
--ORDER BY runtime_min DESC,fcr.actual_start_date DESC
--ORDER BY runtime_min DESC;

SELECT TO_CHAR(SYSDATE,'dd-MON-RR HH:MM:SS') FROM dual;

 To Get Number Of Times A Concurrent Program  Is Run:

SELECT TRUNC(apps.fnd_concurrent_requests.actual_start_date) DATE_run , COUNT(*)COUNT
FROM apps.fnd_concurrent_requests
 WHERE concurrent_program_id =40856
GROUP BY TRUNC(apps.fnd_concurrent_requests.actual_start_date);

 TO GET THE FAMILY PATCH LEVEL:

SELECT patch_level FROM FND_PRODUCT_INSTALLATIONS WHERE patch_level LIKE '%CSI%';

 To Get Number Of Times A Concurrent Program  Is Run:

SELECT p.user_concurrent_program_name
      ,e.execution_file_name
      , (SELECT meaning
           FROM apps.fnd_lookups l
          WHERE lookup_type = 'CP_EXECUTION_METHOD_CODE'
            AND l.lookup_code = e.execution_method_code) TYPE
      ,e.executable_name
  FROM apps.fnd_concurrent_programs_vl p
      ,apps.fnd_executables e
 WHERE p.user_concurrent_program_name =:User_Control_Program_Name
   AND p.executable_id = e.executable_id
   AND p.executable_application_id = e.application_id;
  
  To Get The Details About Concurrent Program, Executable , Execution Method :

SELECT *
  FROM apps.fnd_concurrent_programs_tl
 WHERE user_concurrent_program_name LIKE 'Trans%';
SELECT *
  FROM apps.fnd_executables_tl
 WHERE application_id = 20006
   AND description LIKE 'Unisys AP Invoice Import Interface';
SELECT *
  FROM apps.fnd_executables
 WHERE executable_id = 7157;

To Get details On A Table:

SELECT * FROM apps.fnd_tables ORDER BY table_name;
/*To Get Details On An Object*/
SELECT * FROM all_objects WHERE object_name LIKE 'V$%';
/*To Enable Trace From Back End*/
EXEC DBMS_SYSTEM.SET_EV(818 , 22295 ,10046, 12 ,'');

No of sec elapsed since the last call made to the database:

SELECT s.last_call_et  
      --,q.sql_text
      ,q.users_opening
      ,q.executions
      ,q.fetches
      ,q.rows_processed
      ,TO_CHAR (s.logon_time, 'DD-MON-RR HH:MI:SS AM') session_logon
      ,TO_CHAR (TO_DATE (q.first_load_time, 'RRRR-MM-DD/HH24:MI:SS'),'DD-MON-RR HH:MI:SS AM') sql_load
  FROM v$session s
      ,v$sql q
 WHERE s.process = (SELECT os_process_id FROM fnd_concurrent_requests WHERE request_id = 18855640)                    
   AND s.sql_hash_value = q.hash_value;
  
No of physical GETs: 

SELECT sess_io.sid,
       sess_io.block_gets,
       sess_io.consistent_gets,
       sess_io.physical_reads,
       sess_io.block_changes,
       sess_io.consistent_changes
  FROM v$sess_io sess_io, v$session sesion
 WHERE sesion.sid = sess_io.sid
   AND sesion.username IS NOT NULL
   AND sesion.sid = 678
   ;
TOP_SQL by different parameters:

SELECT v$session.sid,
   v$session.serial#,
   (cpu_time / 1000000) "CPU_Seconds",
   disk_reads "Disk_Reads",
   buffer_gets "Buffer_Gets",
   executions "Executions",
   CASE
WHEN rows_processed = 0 THEN
   NULL
ELSE
   (buffer_gets / NVL(REPLACE(rows_processed,    0,    1),    1))
END "Buffer_gets/rows_proc",
   (buffer_gets / NVL(REPLACE(executions,    0,    1),    1)) "Buffer_gets/executions",
   (elapsed_time / 1000000) "Elapsed_Seconds",
   v$sql.MODULE "Module",
   SUBSTR(sql_text,    1,    500) "SQL"
FROM v$sql,
   v$session
WHERE v$sql.hash_value = v$session.sql_hash_value
ORDER BY cpu_time DESC ,
(buffer_gets/NVL(REPLACE(rows_processed,0,1),1)) DESC ,
buffer_gets DESC ,
disk_reads DESC ,
executions DESC nulls last;

SELECT * FROM fnd_concurrent_programs WHERE CONCURRENT_PROGRAM_ID = 36034;
/*Script to get the trace file name from request_id*/
SELECT 'Request id: ' || request_id, 'Trace id: ' || oracle_process_id,
       'Trace Flag: ' || req.enable_trace,
          'Trace Name:
'
       || dest.VALUE
       || '/'
       || LOWER (dbnm.VALUE)
       || '_ora_'
       || oracle_process_id
       || '.trc
',
       'Prog. Name: ' || prog.user_concurrent_program_name,
       'File Name: ' || execname.execution_file_name
       || execname.subroutine_name,
          'Status : '
       || DECODE (phase_code, 'R', 'Running')
       || '-'
       || DECODE (status_code, 'R', 'Normal'),
       'SID Serial: ' || ses.SID || ',' || ses.serial#,
       'Module : ' || ses.module
  FROM fnd_concurrent_requests req,
       v$session ses,
       v$process proc,
       v$parameter dest,
       v$parameter dbnm,
       fnd_concurrent_programs_vl prog,
       fnd_executables execname
 WHERE req.request_id = '&request'
   AND req.oracle_process_id = proc.spid(+)
   AND proc.addr = ses.paddr(+)
   AND dest.NAME = 'user_dump_dest'
   AND dbnm.NAME = 'db_name'
   AND req.concurrent_program_id = prog.concurrent_program_id
   AND req.program_application_id = prog.application_id
   AND prog.application_id = execname.application_id
   AND prog.executable_id = execname.executable_id
                                  
SELECT * FROM apps.hr_organization_information hoi2
WHERE hoi2.org_information3 = '29';

SID for completed request:

SELECT DISTINCT b.request_id request,
               DECODE (b.parent_request_id,
                       -1, '-------',
                       b.parent_request_id
                      ) PARENT,
               b.requestor, b.program, d.meaning phase,
               TRIM (c.meaning) status,
               TO_CHAR (a.request_date, 'DD-MM-YY-HH24:mi') rdate,
               decode(os_process_id,null,'-----',os_process_id) fndpid, e.SID SID, f.spid spid,
               e.inst_id  server
          FROM fnd_conc_req_summary_v b,
               fnd_lookups c,
               (SELECT lookup_code, meaning, lookup_type
                  FROM fnd_lookups
                 WHERE lookup_type = 'CP_PHASE_CODE') d,
               fnd_concurrent_requests a,
               gv$session e,
               gv$process f
         WHERE
       b.request_id='&REQUEST_ID'
   AND c.lookup_type = 'CP_STATUS_CODE'
           AND b.status_code = c.lookup_code
           AND d.lookup_type = 'CP_PHASE_CODE'
           AND b.phase_code = d.lookup_code
           AND b.request_id = a.request_id
           AND f.spid(+) = a.oracle_process_id
           AND e.paddr(+) = f.addr
           ORDER BY b.request_id DESC;

CCM-completed-With-Error:

SELECT   fcr.oracle_session_id 
        ,fcr.request_id rqst_id 
        ,fcr.phase_code 
        ,fcr.status_code 
        ,fcr.requested_by rqst_by 
        ,fu.user_name 
        ,fr.responsibility_name 
        ,fcr.concurrent_program_id cp_id 
        ,fcp.user_concurrent_program_name cp_name 
        ,fcr.description request_set_name 
        ,TO_CHAR (fcr.actual_start_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_start_datetime 
        ,TO_CHAR (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_completion_datetime 
        ,DECODE (fcr.status_code, 'R', 'R:Running', fcr.status_code) status 
        ,ROUND (((SYSDATE - fcr.actual_start_date) * 60 * 24), 2) runtime_min 
        ,fcr.oracle_process_id "oracle_pid/SPID" 
        ,fcr.os_process_id os_pid 
        ,fcr.argument_text 
        ,fcr.outfile_name 
        ,fcr.logfile_name 
        ,fcr.enable_trace 
    FROM apps.fnd_concurrent_requests fcr 
        ,apps.fnd_user fu 
        ,apps.fnd_responsibility_tl fr 
        ,apps.fnd_concurrent_programs_tl fcp 
   WHERE fcr.phase_code ='C' 
     AND fcr.status_code not in ('C','G') 
     AND fu.user_id = fcr.requested_by 
     AND fr.responsibility_id = fcr.responsibility_id 
     AND fcr.concurrent_program_id = fcp.concurrent_program_id 
     AND fcr.program_application_id = fcp.application_id 
     AND to_char (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS')  > '27-FEB-2012 03:25:42' 
ORDER BY fcr.actual_completion_date DESC;

CCM-completed-With-Warning:


SELECT   fcr.oracle_session_id 
        ,fcr.request_id rqst_id 
        ,fcr.phase_code 
        ,fcr.status_code 
        ,fcr.requested_by rqst_by 
        ,fu.user_name 
        ,fr.responsibility_name 
        ,fcr.concurrent_program_id cp_id 
        ,fcp.user_concurrent_program_name cp_name 
        ,fcr.description request_set_name 
        ,TO_CHAR (fcr.actual_start_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_start_datetime 
        ,TO_CHAR (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_completion_datetime 
        ,DECODE (fcr.status_code, 'R', 'R:Running', fcr.status_code) status 
        ,ROUND (((SYSDATE - fcr.actual_start_date) * 60 * 24), 2) runtime_min 
        ,fcr.oracle_process_id "oracle_pid/SPID"
        ,fcr.os_process_id os_pid 
        ,fcr.argument_text 
        ,fcr.outfile_name 
        ,fcr.logfile_name 
        ,fcr.enable_trace 
    FROM apps.fnd_concurrent_requests fcr 
        ,apps.fnd_user fu 
        ,apps.fnd_responsibility_tl fr 
        ,apps.fnd_concurrent_programs_tl fcp 
   WHERE fcr.phase_code ='C' 
     AND fcr.status_code in ('G') 
     AND fu.user_id = fcr.requested_by 
     AND fr.responsibility_id = fcr.responsibility_id 
     AND fcr.concurrent_program_id = fcp.concurrent_program_id 
     AND fcr.program_application_id = fcp.application_id 
     AND to_char (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS')  > '27-FEB-2012 03:25:42' 
ORDER BY fcr.actual_completion_date DESC;

Concurrent request status for a given sid:

col MODULE for a20
col OSUSER for a10
col USERNAME for a10
set num 10
col MACHINE for a20
set lines 200
col SCHEMANAME for a10
select s.INST_ID,s.sid,s.serial#,p.spid os_pid,s.status, s.osuser,s.username, s.MACHINE,s.MODULE, s.SCHEMANAME,
s.action from gv$session s, gv$process p WHERE s.paddr = p.addr and s.sid = '&oracle_sid';

Find out request id from Oracle_Process Id:

select REQUEST_ID,ORACLE_PROCESS_ID,OS_PROCESS_Id from apps.fnd_concurrent_requests where ORACLE_PROCESS_ID='&a';

To find the sql query for a given concurrent request sid:

select sid,sql_text from gv$session ses, gv$sqlarea sql where 
ses.sql_hash_value = sql.hash_value(+) and ses.sql_address = sql.address(+) and ses.sid='&oracle_sid'
/
To find child requests for Parent request id:

set lines 200
col USER_CONCURRENT_PROGRAM_NAME for a40
col PHASE_CODE for a10
col STATUS_CODE for a10
col COMPLETION_TEXT for a20
SELECT sum.request_id,req.PARENT_REQUEST_ID,sum.user_concurrent_program_name, DECODE(sum.phase_code,'C','Completed',sum.phase_code) 
phase_code, DECODE(sum.status_code,'D', 'Cancelled' , 'E', 'Error' , 'G', 'Warning', 'H','On Hold' , 'T', 'Terminating', 'M', 'No Manager' , 
'X', 'Terminated',  'C', 'Normal', sum.status_code) status_code, sum.actual_start_date, sum.actual_completion_date, sum.completion_text 
FROM apps.fnd_conc_req_summary_v sum, apps.fnd_concurrent_requests req where  req.request_id=sum.request_id 
and req.PARENT_REQUEST_ID = '&parent_concurrent_request_id';

set col os_process_id for 99
select HAS_SUB_REQUEST, is_SUB_REQUEST, parent_request_id, ORACLE_PROCESS_ID, ORACLE_SESSION_ID, OS_PROCESS_ID 
from fnd_concurrent_requests where request_id= '&Req_ID' ;


To terminate the all concurrent requests using by Module wise:

select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate;' from gv$session where MODULE like 'GLPREV';



Concurrent QUEUE Details:

set echo off
set linesize 130
set serveroutput on size 50000
set feed off
set veri off
DECLARE
running_count NUMBER := 0;
pending_count NUMBER := 0;
crm_pend_count NUMBER := 0;
--get the list of all conc managers and max worker and running workers
CURSOR conc_que IS
SELECT concurrent_queue_id,
concurrent_queue_name,
user_concurrent_queue_name, 
max_processes,
running_processes
FROM apps.fnd_concurrent_queues_vl
WHERE enabled_flag='Y' and 
concurrent_queue_name not like 'XDP%' and 
concurrent_queue_name not like 'IEU%' and 
concurrent_queue_name not in ('ARTAXMGR','PASMGR') ;
BEGIN
DBMS_OUTPUT.PUT_LINE('====================================================================================================');
DBMS_OUTPUT.PUT_LINE('QueueID'||' '||'Queue          '||
'Concurrent Queue Name               '||' '||'MAX '||' '||'RUN '||' '||
'Running '||' '||'Pending   '||' '||'In CRM');
DBMS_OUTPUT.PUT_LINE('====================================================================================================');
FOR i IN conc_que 
LOOP
--for each manager get the number of pending and running requests in each queue
SELECT /*+ RULE */ nvl(sum(decode(phase_code, 'R', 1, 0)), 0), 
nvl(sum(decode(phase_code, 'P', 1, 0)), 0)
INTO running_count, pending_count
FROM fnd_concurrent_worker_requests
WHERE
requested_start_date <= sysdate
and concurrent_queue_id = i.concurrent_queue_id
AND hold_flag != 'Y'; 
--for each manager get the list of requests pending due to conflicts in each manager
SELECT /*+ RULE */ count(1)
INTO crm_pend_count
FROM apps.fnd_concurrent_worker_requests a
WHERE concurrent_queue_id = 4
AND hold_flag != 'Y'
AND requested_start_date <= sysdate
AND exists (
SELECT 'x' 
FROM apps.fnd_concurrent_worker_requests b
WHERE a.request_id=b.request_id
and concurrent_queue_id = i.concurrent_queue_id
AND hold_flag != 'Y'
AND requested_start_date <= sysdate);
--print the output by joining the outputs of manager counts,  
DBMS_OUTPUT.PUT_LINE(
rpad(i.concurrent_queue_id,8,'_')||
rpad(i.concurrent_queue_name,15, ' ')||
rpad(i.user_concurrent_queue_name,40,' ')||
rpad(i.max_processes,6,' ')||
rpad(i.running_processes,6,' ')||
rpad(running_count,10,' ')||
rpad(pending_count,10,' ')||
rpad(crm_pend_count,10,' '));
--DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------------------');
END LOOP;
DBMS_OUTPUT.PUT_LINE('====================================================================================================');
END;
/
set verify on
set echo on

CCM Failed jobs:

select
  fcr.request_id,
  fcr.parent_request_id,
  fu.user_name requestor,
  to_char(fcr.last_update_date, 'MON-DD-YYYY HH24:MM:SS') LAST_UPDATE,
  fr.responsibility_key responsibility,
  fcp.concurrent_program_name,
  fcpt.user_concurrent_program_name,
  fcr.argument_text,
  decode(fcr.status_code,
    'A', 'Waiting',
    'B', 'Resuming',
    'C', 'Normal',
    'D', 'Cancelled',
    'E', 'Error',
    'F', 'Scheduled',
    'G', 'Warning',
    'H', 'On Hold',
    'I', 'Normal',
    'M', 'No Manager',
    'Q', 'Standby',
    'R', 'Normal',
    'S', 'Suspended',
    'T', 'Terminating',
    'U', 'Disabled',
    'W', 'Paused',
    'X', 'Terminated',
    'Z', 'Waiting') status,
  decode(fcr.phase_code,
    'C', 'Completed',
    'I', 'Inactive',
    'P', 'Pending',
    'R', 'Running') phase,
  fcr.completion_text
from
  fnd_concurrent_requests fcr,
  fnd_concurrent_programs fcp,
  fnd_concurrent_programs_tl fcpt,
  fnd_user fu,
  fnd_responsibility fr
where
  fcr.status_code in ('D', 'E', 'S', 'T', 'X') and
  fcr.phase_code = 'C' and
  fcr.last_update_date > sysdate - 1 and
  fu.user_id = fcr.requested_by and
  fcr.concurrent_program_id = fcp.concurrent_program_id and
  fcr.concurrent_program_id = fcpt.concurrent_program_id and
  fcr.responsibility_id = fr.responsibility_id
order by
  fcr.last_update_date,
  fcr.request_id;

Show the concurrent manager job status:

SELECT
    a.request_id
  , to_char(a.REQUEST_DATE,'DD-MON-YYYY HH24:MI:SS') Req_Date
  , b.user_name
  , a.phase_code
  , a.status_code
  , c.os_process_id
  , a.oracle_id
  , a.requested_by
  , a.completion_text
FROM
    applsys.fnd_concurrent_requests a
  , applsys.fnd_user b
  , applsys.fnd_concurrent_processes c
WHERE
      a.requested_by = b.user_id
  AND c.concurrent_process_id = a.controlling_manager
  AND a.phase_code in ('R', 'T')
ORDER BY
  a.request_id, c.os_process_id
/

Output file find script :

SELECT OUTFILE_NODE_NAME,OUTFILE_NAME
FROM FND_CONCURRENT_REQUESTS
WHERE REQUEST_ID in ('247321000','247320592','247319626','247319556','247319378');

SELECT OUTFILE_NODE_NAME,OUTFILE_NAME, logfile_node_name, logfile_name
FROM FND_CONCURRENT_REQUESTS
WHERE REQUEST_ID in ('41261937','41234458','41234160');

ORACLE SPID find from Conc Request_ID:

SELECT a.request_id, c.spid
FROM   apps.fnd_concurrent_requests a,
       apps.fnd_concurrent_processes b,
       v$process c
WHERE  c.spid IN ( SELECT c.spid
                   FROM   apps.fnd_concurrent_requests a,
                          apps.fnd_concurrent_processes b,
                          v$process c
                   WHERE  a.controlling_manager = b.concurrent_process_id
                   AND    c.pid = b.oracle_process_id
                   AND    a.request_id = &req_id
                 )
AND   a.controlling_manager = b.concurrent_process_id
AND   c.pid = b.oracle_process_id
AND   A.PHASE_CODE = UPPER('&phase');

Change The PHASE CODE..To Find oracle SID,SPID:

SELECT a.request_id, d.sid, d.serial#
FROM   apps.fnd_concurrent_requests a,
       apps.fnd_concurrent_processes b,
       v$process c,
       v$session d
WHERE  a.controlling_manager = b.concurrent_process_id
AND    c.pid = b.oracle_process_id
AND    c.serial# = d.serial#
AND    a.request_id = &req_id
AND    A.PHASE_CODE = 'C';

CCM-PLSQL-Find:

SELECT request_id,
       requested_by,
       phase_code,
       status_code,
       program_application_id,
       concurrent_program_id,
       controlling_manager,
       oracle_process_id,
       oracle_session_id,
       os_process_id,
       enable_trace
  FROM FND_CONCURRENT_REQUESTS
 WHERE REQUEST_ID = TO_NUMBER('&p_request_id');


 Find PLSQL from request_id:

 select cp.plsql_dir, cp.plsql_out, cp.plsql_log
 FROM FND_CONCURRENT_REQUESTS CR, FND_CONCURRENT_PROCESSES CP
 WHERE CR.REQUEST_ID = '&REQUEST_ID'
 and cp.concurrent_process_id = cr.controlling_manager;

  USER-ID find Script:

Input: Requestor Name

 SELECT user_id,
        user_name,
        description
   FROM FND_USER
 WHERE USER_name = '&P_REQUESTED_BY';

Find the Responsibility name from which a concurrent program can be run:

select distinct
a.application_id,
a.concurrent_program_id,
a.user_concurrent_program_name,
a.description,
b.request_group_id,
request_group_name,
e.responsibility_name
from fnd_concurrent_programs_tl a,
fnd_request_groups b,
fnd_request_group_units c,
fnd_responsibility d,
fnd_responsibility_tl e
where a.concurrent_program_id = c.request_unit_id
and b.request_group_id = c.request_group_id
and b.request_group_id = d.request_group_id
and d.responsibility_id = e.responsibility_id
and a.application_id = b.application_id
and b.application_id = c.application_id
and d.application_id = e.application_id
-- and a.user_concurrent_program_name like 'XX%'
and a.concurrent_program_id = '45220';

Query can be executed to identify requests based on the number of minutes the request ran:

SELECT
fcr.request_id request_id,
TRUNC(((fcr.actual_completion_date-fcr.actual_start_date)/(1/24))*60) exec_time,
fcr.actual_start_date start_date,
fcp.concurrent_program_name conc_prog,
fcpt.user_concurrent_program_name user_conc_prog
FROM
fnd_concurrent_programs fcp,
fnd_concurrent_programs_tl fcpt,
fnd_concurrent_requests fcr
WHERE
TRUNC(((fcr.actual_completion_date-fcr.actual_start_date)/(1/24))*60) > NVL('&min',45)
and
fcr.concurrent_program_id = fcp.concurrent_program_id
and
fcr.program_application_id = fcp.application_id
and
fcr.concurrent_program_id = fcpt.concurrent_program_id
and
fcr.program_application_id = fcpt.application_id
and
fcpt.language = USERENV('Lang')
ORDER BY
TRUNC(((fcr.actual_completion_date-fcr.actual_start_date)/(1/24))*60) desc;

Request Status Listing: 

Purpose:  To calculate request time 
Description : This query will shows report processing time

SELECT f.request_id , pt.user_concurrent_program_name user_concurrent_program_name ,
f.actual_start_date       actual_start_date ,
f.actual_completion_date  actual_completion_date, 
floor(((f.actual_completion_date-f.actual_start_date)*24*60*60)/3600) AUG, 2011 
       || ' HOURS ' || 
       floor((((f.actual_completion_date-f.actual_start_date)*24*60*60) - 
       floor(((f.actual_completion_date-f.actual_start_date)*24*60*60)/3600)*3600)/60) 
       || ' MINUTES ' || 
       round((((f.actual_completion_date-f.actual_start_date)*24*60*60) - 
       floor(((f.actual_completion_date-f.actual_start_date)*24*60*60)/3600)*3600 - 
       (floor((((f.actual_completion_date-f.actual_start_date)*24*60*60) - 
       floor(((f.actual_completion_date-f.actual_start_date)*24*60*60)/3600)*3600)/60)*60) )) 
       || ' SECS ' time_difference, DECODE(p.concurrent_program_name,'ALECDC',p.concurrent_program_name||'['||f.description||']',
       p.concurrent_program_name)  concurrent_program_name,
       decode(f.phase_code,'R','Running','C','Complete',f.phase_code) Phase,
       f.status_code 
FROM apps.fnd_concurrent_programs p,
apps.fnd_concurrent_programs_tl pt,
 apps.fnd_concurrent_requests f 
WHERE  f.concurrent_program_id = p.concurrent_program_id 
and    f.program_application_id = p.application_id 
and    f.concurrent_program_id = pt.concurrent_program_id 
and    f.program_application_id = pt.application_id 
AND    pt.language = USERENV('Lang') 
and    f.actual_start_date is not null 
 ORDER by f.actual_completion_date-f.actual_start_date desc; 

GET THE CURRENT SQL STATEMENT RUNNING FOR A CONCURRENT REQUEST:

 SELECT A.REQUEST_ID, D.SID, D.SERIAL#, D.OSUSER, D.PROCESS, C.SPID,
       E.SQL_TEXT
  FROM APPS.FND_CONCURRENT_REQUESTS A,
       APPS.FND_CONCURRENT_PROCESSES B,
       V$PROCESS C,
       V$SESSION D,
       V$SQL E
 WHERE A.CONTROLLING_MANAGER = B.CONCURRENT_PROCESS_ID
   AND C.PID = B.ORACLE_PROCESS_ID
   AND B.SESSION_ID = D.AUDSID
   AND D.SQL_ADDRESS = E.ADDRESS
   AND A.REQUEST_ID = '&REQUEST_ID';


SQL STATEMENTS RUNNING BY A USER:
  
SELECT A.SID, A.SERIAL#, B.SQL_TEXT
  FROM V$SESSION A, V$SQLAREA B
 WHERE A.SQL_ADDRESS = B.ADDRESS AND A.USERNAME = 'APPS';

 GET THE BLOCKING SESSIONS:

SELECT   BLOCKING_SESSION, SID, SERIAL#, WAIT_CLASS, SECONDS_IN_WAIT
    FROM V$SESSION
   WHERE BLOCKING_SESSION IS NOT NULL
ORDER BY BLOCKING_SESSION;

Determine which manager ran a specific concurrent request:

SELECT
b.user_concurrent_queue_name 
FROM 
fnd_concurrent_processes a
,fnd_concurrent_queues_vl b
,fnd_concurrent_requests c
WHERE 1=1
AND a.concurrent_queue_id = b.concurrent_queue_id
AND a.concurrent_process_id = c.controlling_manager
AND c.request_id = &request_id
/

Find from which responsibility user has ran the concurrent program:

select distinct 
user_concurrent_program_name,
 responsibility_name,
 user_name,  request_date, argument_text, request_id, requested_by, phase_code, status_code,
 a.concurrent_program_id, a.responsibility_id, logfile_name, outfile_name from fnd_concurrent_requests a,
 fnd_concurrent_programs_tl b,fnd_responsibility_tl c,fnd_user d 
where a.CONCURRENT_PROGRAM_ID = b.concurrent_program_id
and a.responsibility_id = c.responsibility_id
and a.requested_by = d.user_id 
and user_name like 'PRUDHVIA';

Display status of all the Concurrent Managers:
      
      Select distinct Concurrent_Process_Id CpId, PID Opid, 
      Os_Process_ID Osid, 
      Q.Concurrent_Queue_Name Manager, 
      P.process_status_code Status, 
      To_Char(P.Process_Start_Date, 'MM-DD-YYYY HH:MI:SSAM') Started_At 
      from  Fnd_Concurrent_Processes P, Fnd_Concurrent_Queues Q, FND_V$Process 
      where  Q.Application_Id = Queue_Application_ID 
      And (Q.Concurrent_Queue_ID = P.Concurrent_Queue_ID) 
      And ( Spid = Os_Process_ID ) 
      And  Process_Status_Code not in ('K','S') 
      Order by Concurrent_Process_ID, Os_Process_Id, Q.Concurrent_Queue_Name ;

Error Request Details:

SELECT   fcr.oracle_session_id 
        ,fcr.request_id rqst_id 
        ,fcr.phase_code 
        ,fcr.status_code 
        ,fcr.requested_by rqst_by 
        ,fu.user_name 
        ,fr.responsibility_name 
        ,fcr.concurrent_program_id cp_id 
        ,fcp.user_concurrent_program_name cp_name 
        ,fcr.description request_set_name 
        ,TO_CHAR (fcr.actual_start_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_start_datetime 
        ,TO_CHAR (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_completion_datetime 
        ,DECODE (fcr.status_code, 'R', 'R:Running', fcr.status_code) status 
        ,ROUND (((SYSDATE - fcr.actual_start_date) * 60 * 24), 2) runtime_min 
        ,fcr.oracle_process_id ""oracle_pid/SPID"" 
        ,fcr.os_process_id os_pid 
        ,fcr.argument_text 
        ,fcr.outfile_name 
        ,fcr.logfile_name 
        ,fcr.enable_trace 
    FROM apps.fnd_concurrent_requests fcr 
        ,apps.fnd_user fu 
        ,apps.fnd_responsibility_tl fr 
        ,apps.fnd_concurrent_programs_tl fcp 
   WHERE fcr.phase_code ='C' 
     AND fcr.status_code not in ('C','G') 
     AND fu.user_id = fcr.requested_by 
     AND fr.responsibility_id = fcr.responsibility_id 
     AND fcr.concurrent_program_id = fcp.concurrent_program_id 
     AND fcr.program_application_id = fcp.application_id 
     AND to_char (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS')  > '27-FEB-2012 03:25:42' 
ORDER BY fcr.actual_completion_date DESC;

Warning Request Details:

SELECT   fcr.oracle_session_id 
        ,fcr.request_id rqst_id 
        ,fcr.phase_code 
        ,fcr.status_code 
        ,fcr.requested_by rqst_by 
        ,fu.user_name 
        ,fr.responsibility_name 
        ,fcr.concurrent_program_id cp_id 
        ,fcp.user_concurrent_program_name cp_name 
        ,fcr.description request_set_name 
        ,TO_CHAR (fcr.actual_start_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_start_datetime 
        ,TO_CHAR (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_completion_datetime 
        ,DECODE (fcr.status_code, 'R', 'R:Running', fcr.status_code) status 
        ,ROUND (((SYSDATE - fcr.actual_start_date) * 60 * 24), 2) runtime_min 
        ,fcr.oracle_process_id ""oracle_pid/SPID"" 
        ,fcr.os_process_id os_pid 
        ,fcr.argument_text 
        ,fcr.outfile_name 
        ,fcr.logfile_name 
        ,fcr.enable_trace 
    FROM apps.fnd_concurrent_requests fcr 
        ,apps.fnd_user fu 
        ,apps.fnd_responsibility_tl fr 
        ,apps.fnd_concurrent_programs_tl fcp 
   WHERE fcr.phase_code ='C' 
     AND fcr.status_code in ('G') 
     AND fu.user_id = fcr.requested_by 
     AND fr.responsibility_id = fcr.responsibility_id 
     AND fcr.concurrent_program_id = fcp.concurrent_program_id 
     AND fcr.program_application_id = fcp.application_id 
     AND to_char (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS')  > '27-FEB-2012 03:25:42' 
ORDER BY fcr.actual_completion_date DESC;

Script to get all the Concurrent Program Request details:

select 
request_id, 
parent_request_id, 
fcpt.user_concurrent_program_name Request_Name, 
fcpt.user_concurrent_program_name program_name, 
DECODE(fcr.phase_code,
            'C','Completed',
            'I','Incactive',
            'P','Pending',
            'R','Running') phase,
    DECODE(fcr.status_code,
 'D','Cancelled', 
  'U','Disabled', 
  'E','Error', 
  'M','No Manager', 
  'R','Normal', 
  'I','Normal', 
  'C','Normal', 
  'H','On Hold',
 'W','Paused', 
  'B','Resuming', 'P','Scheduled', 'Q','Standby', 'S','Suspended', 'X','Terminated', 'T','Terminating', 
 'A','Waiting', 'Z','Waiting', 'G','Warning','N/A') status,
 round((fcr.actual_completion_date - fcr.actual_start_date),3) * 1440 as Run_Time, 
 round(avg(round(to_number(actual_start_date - fcr.requested_start_date),3) * 1440),2) wait_time, 
 fu.User_Name Requestor,
 fcr.argument_text parameters, 
 to_char (fcr.requested_start_date, 'MM/DD HH24:mi:SS') requested_start, 
 to_char(actual_start_date, 'MM/DD/YY HH24:mi:SS') ACT_START, 
 to_char(actual_completion_date, 'MM/DD/YY HH24:mi:SS') ACT_COMP, 
 fcr.completion_text 
 From apps.fnd_concurrent_requests fcr, apps.fnd_concurrent_programs fcp, 
 apps.fnd_concurrent_programs_tl fcpt, apps.fnd_user fu
 Where 1=1 
 -- and fu.user_name = 'DJKOCH' ' 
 -- and fcr.request_id = 1565261 
 -- and fcpt.user_concurrent_program_name = 'Payables Open Interface Import'' 
 and fcr.concurrent_program_id = fcp.concurrent_program_id 
 and fcp.concurrent_program_id = fcpt.concurrent_program_id 
 and fcr.program_application_id = fcp.application_id 
 and fcp.application_id = fcpt.application_id 
 and fcr.requested_by = fu.user_id 
 and fcpt.language = 'US' 
 and fcr.actual_start_date like sysdate 
 -- and fcr.phase_code = 'C' 
 -- and hold_flag = 'Y' 
 -- and fcr.status_code = 'C'
 GROUP BY request_id, parent_request_id, fcpt.user_concurrent_program_name, fcr.requested_start_date, 
 fu.User_Name, fcr.argument_text, fcr.actual_completion_date, fcr.actual_start_date, fcr.phase_code, 
 fcr.status_code, fcr.resubmit_interval, fcr.completion_text, fcr.resubmit_interval, fcr.resubmit_interval_unit_code, 
 fcr.description 
 Order by 1 desc;

Find out Error jobs:

SELECT   fcr.oracle_session_id 
        ,fcr.request_id rqst_id 
        ,fcr.phase_code 
        ,fcr.status_code 
        ,fcr.requested_by rqst_by 
        ,fu.user_name 
        ,fr.responsibility_name 
        ,fcr.concurrent_program_id cp_id 
        ,fcp.user_concurrent_program_name cp_name 
        ,fcr.description request_set_name 
        ,TO_CHAR (fcr.actual_start_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_start_datetime 
        ,TO_CHAR (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS') 
                                                             act_completion_datetime 
        ,DECODE (fcr.status_code, 'R', 'R:Running', fcr.status_code) status 
        ,ROUND (((SYSDATE - fcr.actual_start_date) * 60 * 24), 2) runtime_min 
        ,fcr.oracle_process_id "oracle_pid/SPID" 
        ,fcr.os_process_id os_pid 
        ,fcr.argument_text 
        ,fcr.outfile_name 
        ,fcr.logfile_name 
        ,fcr.enable_trace 
    FROM apps.fnd_concurrent_requests fcr 
        ,apps.fnd_user fu 
        ,apps.fnd_responsibility_tl fr 
        ,apps.fnd_concurrent_programs_tl fcp 
   WHERE fcr.phase_code ='C' 
     AND fcr.status_code not in ('C','G') 
     AND fu.user_id = fcr.requested_by 
     AND fr.responsibility_id = fcr.responsibility_id 
     AND fcr.concurrent_program_id = fcp.concurrent_program_id 
     AND fcr.program_application_id = fcp.application_id 
     AND to_char (fcr.actual_completion_date, 'DD-MON-YYYY HH24:MI:SS')  > '25-SEP-2012 04:00:00' 
ORDER BY fcr.actual_completion_date DESC;


Start And End Dates of a Parent Concurrent Request and all Child Processes:

SELECT creq_run.request_id,
            cprog.concurrent_program_name,
            creq_run.argument_text,
            to_char(creq_run.actual_start_date, 'DD-MON-RR HH24:MI:SS') actual_start_date_run,
            to_char(creq_run.actual_completion_date, 'DD-MON-RR HH24:MI:SS') actual_completion_date_run,
            to_char(creq_base.actual_start_date, 'DD-MON-RR HH24:MI:SS') actual_start_date_run,
            to_char(creq_base.actual_completion_date, 'DD-MON-RR HH24:MI:SS') actual_completion_date_run
FROM  fnd_concurrent_requests creq_run,
           fnd_concurrent_programs cprog,
           fnd_concurrent_requests creq_base
WHERE (    (creq_run.program_application_id = cprog.application_id)
AND (creq_run.concurrent_program_id = cprog.concurrent_program_id)
AND (nvl(creq_base.actual_completion_date,sysdate) >= creq_run.actual_start_date) 
AND (creq_base.actual_start_date <= nvl(creq_run.actual_completion_date,sysdate))
AND (creq_base.request_id = &REQUEST_NUMBER));

Query to find subrequests for a submitted request set:

SELECT req.*
FROM 
(SELECT con.user_concurrent_program_name
,req.request_id
,req.phase_code
,req.status_code
,parent_request_id
FROM fnd_concurrent_requests req
,fnd_concurrent_programs_vl con
WHERE 1 = 1 
AND con.concurrent_program_id = req.concurrent_program_id
) req_set,
(SELECT con.user_concurrent_program_name
,req.request_id
,req.phase_code
,req.request_date
,req.requested_start_date
,req.actual_completion_date
,req.status_code, parent_request_id
FROM fnd_concurrent_requests req
,fnd_concurrent_programs_vl con
WHERE 1 = 1 
AND con.concurrent_program_id = req.concurrent_program_id
) req
WHERE req_set.parent_request_id = 88564179 -- Request id of the submitted request set.
AND req.parent_request_id = req_set.request_id
order by requested_start_date desc;

Find the Scheduled Requests:

select request_id
from   fnd_concurrent_requests
where  status_code in ('Q','I')
and    requested_start_date > SYSDATE
and    hold_flag = 'N';

HISTORY OF CONCURRENT REQUEST - SCRIPT (PROGRAM WISE) :

set pagesize 200
set linesize 200
col "Who submitted" for a25
col "Status" for a10
col "Parameters" for a20
col USER_CONCURRENT_PROGRAM_NAME for a42
SELECT distinct t.user_concurrent_program_name,
r.REQUEST_ID,
to_char(r.ACTUAL_START_DATE,'dd-mm-yy hh24:mi:ss') "Started at",
to_char(r.ACTUAL_COMPLETION_DATE,'dd-mm-yy hh24:mi:ss') "Completed at",
decode(r.PHASE_CODE,'C','Completed','I','Inactive','P ','Pending','R','Running','NA') phasecode,
decode(r.STATUS_CODE, 'A','Waiting', 'B','Resuming', 'C','Normal', 'D','Cancelled', 'E','Error', 'F','Scheduled', 'G','Warning', 'H','On Hold', 'I','Normal', 'M',
'No Manager', 'Q','Standby', 'R','Normal', 'S','Suspended', 'T','Terminating', 'U','Disabled', 'W','Paused', 'X','Terminated', 'Z','Waiting') "Status",r.argument_text "Parameters",substr(u.description,1,25) "Who submitted",round(((nvl(v.actual_completion_date,sysdate)-v.actual_start_date)*24*60)) Etime
FROM
apps.fnd_concurrent_requests r ,
apps.fnd_concurrent_programs p ,
apps.fnd_concurrent_programs_tl t,
apps.fnd_user u, apps.fnd_conc_req_summary_v v
WHERE 
r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID
AND r.actual_start_date >= (sysdate-30)
--AND r.requested_by=22378
AND   r.PROGRAM_APPLICATION_ID = p.APPLICATION_ID
AND t.concurrent_program_id=r.concurrent_program_id
AND r.REQUESTED_BY=u.user_id
AND v.request_id=r.request_id
--AND r.request_id ='2260046' in ('13829387','13850423')
and t.user_concurrent_program_name like '%%'
order by to_char(r.ACTUAL_COMPLETION_DATE,'dd-mm-yy hh24:mi:ss');

Find log file & out file for request:

SELECT logfile_name, logfile_node_name, outfile_name, outfile_node_name,
       controlling_manager
  FROM fnd_concurrent_requests
 WHERE request_id = &&request_id;

Determine the Internal Concurrent Manager log file and node name:

SELECT logfile_name "Filename", node_name "Nodename"
  FROM (SELECT   *
 FROM fnd_concurrent_processes
    WHERE queue_application_id = 0 AND concurrent_queue_id = 1
    ORDER BY concurrent_process_id DESC)
 WHERE ROWNUM = 1;
How to Determine Which Manager Ran a Specific Concurrent Request:

col USER_CONCURRENT_QUEUE_NAME for a100
select b.USER_CONCURRENT_QUEUE_NAME from fnd_concurrent_processes a,
fnd_concurrent_queues_vl b, fnd_concurrent_requests c
where a.CONCURRENT_QUEUE_ID = b.CONCURRENT_QUEUE_ID
and a.CONCURRENT_PROCESS_ID = c.controlling_manager
and c.request_id = '&conc_reqid';

Pending requests count:

select COUNT (distinct cwr.request_id) Peding_Requests FROM apps.fnd_concurrent_worker_requests cwr, apps.fnd_concurrent_queues_tl cq, apps.fnd_user fu WHERE (cwr.phase_code = 'P' OR cwr.phase_code = 'R') AND cwr.hold_flag != 'Y' AND cwr.requested_start_date <= SYSDATE AND cwr.concurrent_queue_id = cq.concurrent_queue_id AND cwr.queue_application_id = cq.application_id and cq.LANGUAGE='US'
 AND cwr.requested_by = fu.user_id and cq.user_concurrent_queue_name
 in ( select unique user_concurrent_queue_name from apps.fnd_concurrent_queues_tl);

Pending requests:

SELECT DISTINCT far.request_id, SUBSTR (program, 1,30), far.user_name,
                far.phase_code, far.status_code, phase, status,
                (CASE
                    WHEN far.phase_code = 'P' AND far.hold_flag = 'Y'
                       THEN 'Job is on Hold by user'
                    WHEN far.phase_code = 'P'
                    AND (far.status_code = 'I' OR far.status_code = 'Q')
                    AND far.requested_start_date > SYSDATE
                       THEN    'Job is scheduled to run at '
                            || TO_CHAR (far.requested_start_date,
                                        'DD-MON-RR HH24:MI:SS'
                                       )
                    WHEN far.phase_code = 'P'
                    AND (far.status_code = 'I' OR far.status_code = 'Q')
                    AND fcp.queue_control_flag = 'Y'
                       THEN 'ICM will run ths request on its next sleep cycle'
                    WHEN far.phase_code = 'P' AND far.status_code = 'P'
                       THEN 'Scheduled to be run by the Advanced Scheduler'
                    WHEN far.queue_method_code NOT IN ('I', 'B')
                       THEN    'Bad queue_method_code of: '
                            || far.queue_method_code
                    WHEN far.run_alone_flag = 'Y'
                       THEN 'Waiting on a run alone request'
                    WHEN far.queue_method_code = 'B'
                    AND far.status_code = 'Q'
                    AND EXISTS (
                           SELECT 1
                             FROM fnd_amp_requests_v farv
                            WHERE phase_code = 'P'
                              AND program_application_id =
                                                    fcps.to_run_application_id
                              AND concurrent_program_id =
                                             fcps.to_run_concurrent_program_id)
              THEN    'Incompatible request '
                  || (SELECT DISTINCT    farv.request_id
                                || ': '
                                || farv.program
                                || ' is Ruuning by : '
                                || farv.user_name
                      FROM fnd_amp_requests_v farv,fnd_concurrent_program_serial fcps1
                      WHERE phase_code = 'R'
                      AND program_application_id =fcps1.running_application_id
                      AND concurrent_program_id =fcps1.running_concurrent_program_id
                      AND fcps.to_run_application_id=fcps1.to_run_application_id
                      AND fcps.to_run_concurrent_program_id=fcps1.to_run_concurrent_program_id)
                    WHEN fcp.enabled_flag = 'N'
                       THEN 'Concurrent program is disabled'
                    WHEN far.queue_method_code = 'I' AND far.status_code = 'Q'
                       THEN 'This Standby request might not run'
                    WHEN far.queue_method_code = 'I' AND far.status_code = 'I'
                       THEN    'Waiting for next available '
                            || fcqt.user_concurrent_queue_name
                            || ' process to run the job. Estimate Wait time '
                            || fcq.sleep_seconds
                            || ' Seconds'
                    WHEN far.queue_method_code = 'I'
                    AND far.status_code IN ('A', 'Z')
                       THEN    'Waiting for Parent Request: '
                            || NVL (far.parent_request_id,
                                    'Could not locate Parent Request ID'
                                   )
                    WHEN far.queue_method_code = 'B' AND far.status_code = 'Q'
                       THEN 'Waiting on the Conflict Resolution Manager'
                    WHEN far.queue_method_code = 'B' AND far.status_code = 'I'
                       THEN    'Waiting for next available '
                            || fcqt.user_concurrent_queue_name
                            || ' process to run the job. Estimate Wait time '
                            || fcq.sleep_seconds
                            || ' Seconds'
                    WHEN far.phase_code = 'P' AND far.single_thread_flag = 'Y'
                       THEN 'Single-threaded request. Waiting on other requests for this user.'
                    WHEN far.phase_code = 'P' AND far.request_limit = 'Y'
                       THEN 'Concurrent: Active Request Limit is set. Waiting on other requests for this user.'
                 END
                ) reason
           FROM fnd_amp_requests_v far,
                fnd_concurrent_programs fcp,
                fnd_conflicts_domain fcd,
                fnd_concurrent_program_serial fcps,
                fnd_concurrent_queues fcq,
                fnd_concurrent_queue_content fcqc,
                fnd_concurrent_queues_tl fcqt
          WHERE far.phase_code = 'P'
            AND far.concurrent_program_id = fcp.concurrent_program_id
            AND fcd.cd_id = far.cd_id
            AND fcps.running_application_id(+) = far.program_application_id
            AND fcps.running_concurrent_program_id(+) = far.concurrent_program_id
            AND far.program_application_id = fcps.to_run_application_id(+)
            AND far.concurrent_program_id = fcps.to_run_concurrent_program_id(+)
            AND far.concurrent_program_id = fcqc.type_id(+)
            AND far.program_application_id = fcqc.type_application_id(+)
            AND fcq.concurrent_queue_id(+) = fcqc.concurrent_queue_id
            AND fcq.application_id(+) = fcqc.queue_application_id
            AND fcqt.concurrent_queue_id(+) = fcq.concurrent_queue_id
            AND fcqt.application_id(+) = fcq.application_id
       ORDER BY far.request_id DESC;
   
  Pending Request In Managers:

    SELECT v.user_concurrent_queue_name, COUNT(phase_code) pending
   FROM  apps.fnd_concurrent_queues_vl v,
         apps.fnd_concurrent_worker_requests r
   WHERE r.queue_application_id = 0
     AND r.phase_code = 'P'                -- Pending
     AND r.hold_flag != 'Y'                -- not on hold
     AND r.requested_start_date <= SYSDATE -- No Future jobs
     AND r.concurrent_queue_id=v.concurrent_queue_id
   GROUP BY v.user_concurrent_queue_name
   HAVING COUNT (phase_code) >= 1;
  
Concurrent Program count under QUEUE:

col  "program name" format a55;
col "name" format  a17;
col "queue name" format a15
col "statuscode" format a3
select user_CONCURRENT_PROGRAM_NAME "PROGRAM NAME",concurrent_queue_name "QUEUE NAME", priority,decode(phase_code,'P','Pending') "PHASE", 
decode(status_code,'A','Waiting','B','Resuming','C','Normal','D','Cancelled','E','Error','F',
'Scheduled','G','Warning','H','On Hold','I','Normal','M','No Manager','Q','Standby','R','Normal','S',
'Suspended','T','Terminating','U','Disabled','W','Paused','X','Terminated','Z','Waiting') " 
NAME", status_code,count(*) from 
fnd_concurrent_worker_requests 
where  phase_code='P' and hold_flag!='Y' 
and requested_start_date<=sysdate
and concurrent_queue_name<> 'FNDCRM'
and concurrent_queue_name<> 'GEMSPS'
group by 
user_CONCURRENT_PROGRAM_NAME,
concurrent_queue_name,priority,phase_code,status_code
order by count(*) desc;
/

Lists the Manager Names with the No. of Requests in Pending/Running:

col "USER_CONCURRENT_QUEUE_NAME" format a40;
SELECT a.USER_CONCURRENT_QUEUE_NAME,a.MAX_PROCESSES,
sum(decode(b.PHASE_CODE,'P',decode(b.STATUS_CODE,'Q',1,0),0)) Pending_Standby,
sum(decode(b.PHASE_CODE,'P',decode(b.STATUS_CODE,'I',1,0),0)) Pending_Normal,
sum(decode(b.PHASE_CODE,'R',decode(b.STATUS_CODE,'R',1,0),0)) Running_Normal
FROM FND_CONCURRENT_QUEUES_VL a, FND_CONCURRENT_WORKER_REQUESTS b
where a.concurrent_queue_id = b.concurrent_queue_id
AND b.Requested_Start_Date<=SYSDATE
GROUP BY a.USER_CONCURRENT_QUEUE_NAME,a.MAX_PROCESSES;

Find the scheduled concurrent requests:

SELECT cr.request_id,
DECODE (cp.user_concurrent_program_name,
'Report Set', 'Report Set:' || cr.description,
cp.user_concurrent_program_name
) NAME,
argument_text, cr.resubmit_interval,
NVL2 (cr.resubmit_interval,
'PERIODICALLY',
NVL2 (cr.release_class_id, 'ON SPECIFIC DAYS', 'ONCE')
) schedule_type,
DECODE (NVL2 (cr.resubmit_interval,
'PERIODICALLY',
NVL2 (cr.release_class_id, 'ON SPECIFIC DAYS', 'ONCE')
),
'PERIODICALLY', 'EVERY '
|| cr.resubmit_interval
|| ' '
|| cr.resubmit_interval_unit_code
|| ' FROM '
|| cr.resubmit_interval_type_code
|| ' OF PREV RUN',
'ONCE', 'AT :'
|| TO_CHAR (cr.requested_start_date, 'DD-MON-RR HH24:MI'),
'EVERY: ' || fcr.class_info
) schedule,
fu.user_name, requested_start_date
FROM apps.fnd_concurrent_programs_tl cp,
apps.fnd_concurrent_requests cr,
apps.fnd_user fu,
apps.fnd_conc_release_classes fcr
WHERE cp.application_id = cr.program_application_id
AND cp.concurrent_program_id = cr.concurrent_program_id
AND cr.requested_by = fu.user_id
AND cr.phase_code = 'P'
AND cr.requested_start_date > SYSDATE
AND cp.LANGUAGE = 'US'
AND fcr.release_class_id(+) = cr.release_class_id
AND fcr.application_id(+) = cr.release_class_app_id;

Checking which manager is going to execute a program:

SELECT user_concurrent_program_name, user_concurrent_queue_name 
FROM apps.fnd_concurrent_programs_tl cp, 
apps.fnd_concurrent_queue_content cqc, 
apps.fnd_concurrent_queues_tl cq 
WHERE cqc.type_application_id(+) = cp.application_id 
AND cqc.type_id(+) = cp.concurrent_program_id 
AND cqc.type_code(+) = 'P' 
AND cqc.include_flag(+) = 'I' 
AND cp.LANGUAGE = 'US' 
AND cp.user_concurrent_program_name = '&USER_CONCURRENT_PROGRAM_NAME' AND NVL (cqc.concurrent_queue_id, 0) = cq.concurrent_queue_id 
AND NVL (cqc.queue_application_id, 0) = cq.application_id 
AND cq.LANGUAGE = 'US';
--To see all the pending / Running requests per each manager wise
SELECT request_id, phase_code, status_code, user_name, 
user_concurrent_queue_name 
FROM apps.fnd_concurrent_worker_requests cwr, 
apps.fnd_concurrent_queues_tl cq, 
apps.fnd_user fu 
WHERE (cwr.phase_code = 'P' OR cwr.phase_code = 'R') 
AND cwr.hold_flag != 'Y' 
AND cwr.requested_start_date <= SYSDATE 
AND cwr.concurrent_queue_id = cq.concurrent_queue_id 
AND cwr.queue_application_id = cq.application_id 
AND cq.LANGUAGE = 'US' 
AND cwr.requested_by = fu.user_id 
ORDER BY 5;

Checking the incompatibilities between the programs:
The below query can be used to find all incompatibilities in an application instance. 

SELECT a2.application_name, a1.user_concurrent_program_name, 
DECODE (running_type, 
'P', 'Program', 
'S', 'Request set', 
'UNKNOWN' 
) "Type", 
b2.application_name "Incompatible App", 
b1.user_concurrent_program_name "Incompatible_Prog", 
DECODE (to_run_type, 
'P', 'Program', 
'S', 'Request set', 
'UNKNOWN' 
) incompatible_type 
FROM apps.fnd_concurrent_program_serial cps, 
apps.fnd_concurrent_programs_tl a1, 
apps.fnd_concurrent_programs_tl b1, 
apps.fnd_application_tl a2, 
apps.fnd_application_tl b2 
WHERE a1.application_id = cps.running_application_id 
AND a1.concurrent_program_id = cps.running_concurrent_program_id 
AND a2.application_id = cps.running_application_id 
AND b1.application_id = cps.to_run_application_id 
AND b1.concurrent_program_id = cps.to_run_concurrent_program_id 
AND b2.application_id = cps.to_run_application_id 
AND a1.language = 'US' 
AND a2.language = 'US' 
AND b1.language = 'US' 
AND b2.language = 'US' ;

Script to trace Concuurent request:

select s.sid , s.serial# ,p.spid from fnd_concurrent_requests f,v$session s , v$process p
where f.request_id = 
and f.oracle_process_id = p.spid
and p.addr = s.paddr
EXEC DBMS_SYSTEM.SET_EV(&sid , &serial,10046, 12 ,'');

Log on to the DB Tier ….
   Check for the trace file <instance name>_ora_<SPID>.trc

Terminated concurrent  Request-Details:

SELECT fu.user_name, fcpt.USER_CONCURRENT_PROGRAM_NAME, fcpt.description, fcp.CONCURRENT_PROGRAM_NAME, fcr.REQUEST_ID,
round((fcr.actual_completion_date – 
decode (trunc(fcr.request_date),fcr.requested_start_date,fcr.request_date,fcr.requested_start_date))*60*24) WaitTimeMIN,
DECODE(fcr.PHASE_CODE,'C','Completed','R','Running',fcr.PHASE_CODE) PHASE_CODE,
DECODE(fcr.STATUS_CODE,'C','Completed','R','Running','W','Paused','E','Error','G','Warning', fcr.STATUS_CODE) STATUS_CODE,
to_char(fcr.request_date,'DD/MM/YYYY HH24:MI:SS') request_date,
to_char(fcr.requested_start_date,'DD/MM/YYYY HH24:MI:SS') start_time,
to_char(fcr.actual_completion_date,'DD/MM/YYYY HH24:MI:SS') complete_time
FROM
fnd_concurrent_requests fcr,
fnd_concurrent_programs fcp,
fnd_concurrent_programs_tl fcpt,
fnd_user fu
WHERE  1=1
AND    fcp.CONCURRENT_PROGRAM_ID=fcr.CONCURRENT_PROGRAM_ID
AND    fcpt.CONCURRENT_PROGRAM_ID=fcp.CONCURRENT_PROGRAM_ID
AND    fcr.requested_by = fu.user_id
AND    trunc(fcr.request_date) BETWEEN sysdate – 1 AND sysdate
AND    fcr.status_code IN ('E','G')
ORDER BY fcr.status_code, fcp.CONCURRENT_PROGRAM_NAME, fcr.REQUEST_ID;

To find the terminated requests by users use this query:

SELECT actual_completion_date TERMINATED,
       request_id,
       SUBSTR(program,1,53) PROGRAM,
       SUBSTR(requestor,1,15) REQUESTOR, 
       parent_request_id PARENT,
       completion_text MESSAGE
FROM   apps.FND_CONC_REQ_SUMMARY_V 
WHERE  STATUS_CODE = 'E' 
AND    actual_completion_date > SYSDATE - 2
--AND    requestor LIKE ('%AR_BTOGUSER%')
ORDER BY REQUEST_ID DESC;

Not only users terminate request, errors too,to get error terminated requests:

SELECT actual_completion_date FAILED,
       request_id, program_short_name,
       SUBSTR(program,1,53) PROGRAM,
       SUBSTR(requestor,1,15) REQUESTOR, 
       parent_request_id PARENT,
       completion_text MESSAGE
FROM   apps.FND_CONC_REQ_SUMMARY_V 
WHERE  STATUS_CODE = 'E' 
AND    ((DECODE(IMPLICIT_CODE, 'N', STATUS_CODE,'E', 'E', 'W', 'G') = STATUS_CODE 
OR     DECODE(IMPLICIT_CODE, 'W', 'E') = STATUS_CODE)) 
AND    actual_completion_date > SYSDATE - 2
--AND    requestor LIKE ('%KOSDIM%')
--AND    program_short_name = 'XXACC_OTEDUNN_PARALLEL'
ORDER BY REQUEST_ID DESC;
