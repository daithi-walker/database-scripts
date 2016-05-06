http://psoug.org/snippet/LOCKS-View-Locked-Objects_866.htm

SELECT s.username, l.sid, s.blocking_session blocker, s.event, l.type, l.lmode, l.request, o.object_name, o.object_type 
FROM v$lock l, dba_objects o, v$session s 
WHERE 1=1
AND o.object_name <> 'ORA$BASE'
AND o.object_name not like '%$%'
AND o.object_type <> 'EDITION'
--AND l.sid = 487
AND s.username = 'OLIVE'
AND l.id1 = o.object_id (+) 
AND l.sid = s.sid 
ORDER BY sid, type;

-- view all currently locked objects:
SELECT username U_NAME, owner OBJ_OWNER,
object_name, object_type, s.osuser,
DECODE(l.block,
  0, 'Not Blocking',
  1, 'Blocking',
  2, 'Global') STATUS,
  DECODE(v.locked_mode,
    0, 'None',
    1, 'Null',
    2, 'Row-S (SS)',
    3, 'Row-X (SX)',
    4, 'Share',
    5, 'S/Row-X (SSX)',
    6, 'Exclusive', TO_CHAR(lmode)
  ) MODE_HELD
FROM gv$locked_object v, dba_objects d,
gv$lock l, gv$session s
WHERE v.object_id = d.object_id
AND (v.object_id = l.id1)
AND v.session_id = s.sid
--and d.object_name = 'MIS_ARCHIVE_DT_ARCHIVE'
ORDER BY username, session_id;
 
 
-- list current locks
 
SELECT session_id,lock_type, 
mode_held, 
mode_requested, 
blocking_others, 
lock_id1
FROM dba_lock l
WHERE lock_type 
NOT IN ('Media Recovery', 'Redo Thread');
 
 
-- list objects that have been 
-- locked for 60 seconds or more: 
 
SELECT SUBSTR(TO_CHAR(w.session_id),1,5) WSID, p1.spid WPID,
SUBSTR(s1.username,1,12) "WAITING User",
SUBSTR(s1.osuser,1,8) "OS User",
SUBSTR(s1.program,1,20) "WAITING Program",
s1.client_info "WAITING Client",
SUBSTR(TO_CHAR(h.session_id),1,5) HSID, p2.spid HPID,
SUBSTR(s2.username,1,12) "HOLDING User",
SUBSTR(s2.osuser,1,8) "OS User",
SUBSTR(s2.program,1,20) "HOLDING Program",
s2.client_info "HOLDING Client",
o.object_name "HOLDING Object"
FROM gv$process p1, gv$process p2, gv$session s1,
gv$session s2, dba_locks w, dba_locks h, dba_objects o
WHERE w.last_convert > 60
AND h.mode_held != 'None'
AND h.mode_held != 'Null'
AND w.mode_requested != 'None'
AND s1.row_wait_obj# = o.object_id
AND w.lock_type(+) = h.lock_type
AND w.lock_id1(+) = h.lock_id1
AND w.lock_id2 (+) = h.lock_id2
AND w.session_id = s1.sid (+)
AND h.session_id = s2.sid (+)
AND s1.paddr = p1.addr (+)
AND s2.paddr = p2.addr (+)
ORDER BY w.last_convert DESC;
 
 
-- alternate example:
 
SELECT s.username, s.sid, s.serial#, s.osuser, k.ctime, o.object_name
object, k.kaddr, DECODE(l.locked_mode,
  1, 'No Lock',
  2, 'Row Share',
  3, 'Row Exclusive',
  4, 'Shared Table',
  5, 'Shared Row Exclusive',
  6, 'Exclusive') locked_mode,
  DECODE(k.TYPE,
    'BL','Buffer Cache Management (PCM lock)',
  'CF','Controlfile Transaction',
  'CI','Cross Instance Call',
  'CU','Bind Enqueue',
  'DF','Data File',
  'DL','Direct Loader',
  'DM','Database Mount',
  'DR','Distributed Recovery',
  'DX','Distributed Transaction',
  'FS','File Set',
  'IN','Instance Number',
  'IR','Instance Recovery',
  'IS','Instance State',
  'IV','Library Cache Invalidation',
  'JQ','Job Queue',
  'KK','Redo Log Kick',
  'LA','Library Cache Lock',
  'LB','Library Cache Lock',
  'LC','Library Cache Lock',
  'LD','Library Cache Lock',
  'LE','Library Cache Lock',
  'LF','Library Cache Lock',
  'LG','Library Cache Lock',
  'LH','Library Cache Lock',
  'LI','Library Cache Lock',
  'LJ','Library Cache Lock',
  'LK','Library Cache Lock',
  'LL','Library Cache Lock',
  'LM','Library Cache Lock',
  'LN','Library Cache Lock',
  'LO','Library Cache Lock',
  'LP','Library Cache Lock',
  'MM','Mount Definition',
  'MR','Media Recovery',
  'NA','Library Cache Pin',
  'NB','Library Cache Pin',
  'NC','Library Cache Pin',
  'ND','Library Cache Pin',
  'NE','Library Cache Pin',
  'NF','Library Cache Pin',
  'NG','Library Cache Pin',
  'NH','Library Cache Pin',
  'NI','Library Cache Pin',
  'NJ','Library Cache Pin',
  'NK','Library Cache Pin',
  'NL','Library Cache Pin',
  'NM','Library Cache Pin',
  'NN','Library Cache Pin',
  'NO','Library Cache Pin',
  'NP','Library Cache Pin',
  'NQ','Library Cache Pin',
  'NR','Library Cache Pin',
  'NS','Library Cache Pin',
  'NT','Library Cache Pin',
  'NU','Library Cache Pin',
  'NV','Library Cache Pin',
  'NW','Library Cache Pin',
  'NX','Library Cache Pin',
  'NY','Library Cache Pin',
  'NZ','Library Cache Pin',
  'PF','Password File',
  'PI','Parallel Slaves',
  'PR','Process Startup',
  'PS','Parallel Slave Synchronization',
  'QA','Row Cache Lock',
  'QB','Row Cache Lock',
  'QC','Row Cache Lock',
  'QD','Row Cache Lock',
  'QE','Row Cache Lock',
  'QF','Row Cache Lock',
  'QG','Row Cache Lock',
  'QH','Row Cache Lock',
  'QI','Row Cache Lock',
  'QJ','Row Cache Lock',
  'QK','Row Cache Lock',
  'QL','Row Cache Lock',
  'QM','Row Cache Lock',
  'QN','Row Cache Lock',
  'QO','Row Cache Lock',
  'QP','Row Cache Lock',
  'QQ','Row Cache Lock',
  'QR','Row Cache Lock',
  'QS','Row Cache Lock',
  'QT','Row Cache Lock',
  'QU','Row Cache Lock',
  'QV','Row Cache Lock',
  'QW','Row Cache Lock',
  'QX','Row Cache Lock',
  'QY','Row Cache Lock',
  'QZ','Row Cache Lock',
  'RT','Redo Thread',
  'SC','System Commit number',
  'SM','SMON synchronization',
  'SN','Sequence Number',
  'SQ','Sequence Enqueue',
  'SR','Synchronous Replication',
  'SS','Sort Segment',
  'ST','Space Management Transaction',
  'SV','Sequence Number Value',
  'TA','Transaction Recovery',
  'TM','DML Enqueue',
  'TS','Table Space (or Temporary Segment)',
  'TT','Temporary Table',
  'TX','Transaction',
  'UL','User-defined Locks',
  'UN','User Name',
  'US','Undo segment Serialization',
  'WL','Writing redo Log',
  'XA','Instance Attribute Lock',
  'XI','Instance Registration Lock') TYPE
FROM gv$session s, sys.gv$lock c, sys.gv$locked_object l,
     dba_objects o, sys.gv$lock k, gv$lock v
WHERE o.object_id = l.object_id
AND l.session_id = s.sid
AND k.sid = s.sid
AND s.saddr = c.saddr
AND k.kaddr = c.kaddr
AND k.kaddr = v.kaddr
AND v.saddr = s.saddr
AND k.lmode = l.locked_mode
AND k.lmode = c.lmode
AND k.request = c.request
ORDER BY object;




select  vp.spid unix_process_id
,       vs.sid
,       vs.serial#
,       lo.oracle_username
,       lo.os_user_name
,       do.owner             OBJECT_OWNER
,       do.object_name
,       do.object_type
,       lo.locked_mode
,       vs.blocking_session 
,       vs.seconds_in_wait
from    v$locked_object lo
,       dba_objects do
,       v$process vp
,       v$session vs
where   1=1
and     lo.object_id = do.object_id
and     vp.addr = vs.paddr
and     vs.sid = lo.session_id
--and     do.object_name = 'MKTG_CODE_REFERENCE'
;

select  o.object_name
,       o.object_type
,       l.*
from    v$lock l
,       dba_objects o
where   1=1
and     l.id1 = o.object_id
and     o.owner = 'OLIVE'
and     o.object_name like '%CMO%';

select *
from
(
select sql_text,
    sql_id,
    round(elapsed_time/1000000/60/60,2) elapsed_time_hours,
    elapsed_time,
    cpu_time,
    user_io_wait_time
from sys.v_$sqlarea
where upper(sql_text) like '%YANDEX%'
order by user_io_wait_time desc
)
where rownum < 10
;

SELECT  * --sid, total_waits, round(time_waited/100/60/60,2) time_waited
FROM    v$session_event
WHERE   1=1
AND     event='db file sequential read'
AND     sid = :sid
AND     total_waits > 0
ORDER BY 3,2;

select s.username, s.sid, s.serial#, t.xidusn, t.xidslot, t.xidsqn
from v$session s, v$transaction t
where s.taddr=t.addr