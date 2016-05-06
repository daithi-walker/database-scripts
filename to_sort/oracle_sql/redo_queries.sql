http://damir-vadas.blogspot.co.uk/2011/02/how-to-redo-logs-generation.html
http://appcrawler.com/wordpress/2009/04/15/who-is-generating-all-the-redo/
http://ulfet.blogspot.co.uk/2012/12/which-sessions-generate-lot-of-redo-logs.html
https://community.oracle.com/thread/1107767?tstart=0

select b.inst_id, 
       lpad((b.SID || ',' || lpad(b.serial#,5)),11) sid_serial, 
       b.username, 
       machine, 
       b.osuser, 
       b.status, 
       a.redo_mb  
from (select n.inst_id, sid, 
             round(value/1024/1024) redo_mb
        from gv$statname n, gv$sesstat s
        where n.inst_id=s.inst_id
              and n.name = 'redo size'
              and s.statistic# = n.statistic#
        order by value desc
     ) a,
     gv$session b
where b.inst_id=a.inst_id
  and a.sid = b.sid
and   rownum <= 30
;

SELECT P.SPID, S.SID, S.SERIAL#
FROM V$PROCESS P, V$SESSION S
WHERE P.ADDR = S.PADDR
AND S.SID in (353,321,385);

select * from v$parameter where 1=1 and 
(name like 'db_wr%'
or
name like 'cpu%'
)
;

select * from dba_hist_system_event;
select * from v$sysstat where name like 'DBWR%';

SELECT * FROM (
SELECT * FROM (
SELECT   TO_CHAR(FIRST_TIME, 'DD/MM') AS "DAY"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '00', 1, 0)), '999') "00:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '01', 1, 0)), '999') "01:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '02', 1, 0)), '999') "02:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '03', 1, 0)), '999') "03:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '04', 1, 0)), '999') "04:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '05', 1, 0)), '999') "05:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '06', 1, 0)), '999') "06:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '07', 1, 0)), '999') "07:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '08', 1, 0)), '999') "08:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '09', 1, 0)), '999') "09:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '10', 1, 0)), '999') "10:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '11', 1, 0)), '999') "11:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '12', 1, 0)), '999') "12:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '13', 1, 0)), '999') "13:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '14', 1, 0)), '999') "14:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '15', 1, 0)), '999') "15:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '16', 1, 0)), '999') "16:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '17', 1, 0)), '999') "17:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '18', 1, 0)), '999') "18:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '19', 1, 0)), '999') "19:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '20', 1, 0)), '999') "20:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '21', 1, 0)), '999') "21:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '22', 1, 0)), '999') "22:00"
       , TO_NUMBER(SUM(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '23', 1, 0)), '999') "23:00"
    FROM V$LOG_HISTORY
    WHERE extract(year FROM FIRST_TIME) = extract(year FROM sysdate)
GROUP BY TO_CHAR(FIRST_TIME, 'DD/MM')
) ORDER BY TO_DATE(extract(year FROM sysdate) || DAY, 'YYYY DD/MM') DESC
) WHERE ROWNUM < 8;

select * from v$log order by first_time; --> look at the bytes and make your calculation.

select trunc(completion_time)
,      round(sum(blocks*block_size/(1024*1024*1024))) GBs
from   v$archived_log 
group by trunc(completion_time)
order by trunc(completion_time);



SELECT  s.sid, s.serial#, s.username, s.program, i.block_changes
FROM v$session s, v$sess_io i
WHERE s.sid = i.sid AND i.block_changes > 0
ORDER BY 5 DESC, 1;

SELECT s.sid, s.serial#, s.username, s.program, s.machine, t.used_ublk, t.used_urec
FROM v$session s, v$transaction t
WHERE s.taddr = t.addr
ORDER BY 6, 7 desc;

SELECT dhso.object_name
     , object_type, SUM (db_block_changes_delta)
FROM dba_hist_seg_stat dhss, dba_hist_seg_stat_obj dhso, dba_hist_snapshot dhs
WHERE     dhs.snap_id = dhss.snap_id 
AND dhs.instance_number = dhss.instance_number
AND dhss.obj# = dhso.obj#
AND dhss.dataobj# = dhso.dataobj#
AND begin_interval_time BETWEEN trunc(sysdate) and trunc(sysdate)+1
GROUP BY dhso.object_name, object_type
HAVING SUM (db_block_changes_delta) > 0
ORDER BY 2, SUM (db_block_changes_delta) DESC;

select a.*
, SUM(db_block_changes_delta) over (partition by object_name) cnt_total
from (
SELECT to_char(begin_interval_time,'YYYY_MM_DD HH24:MI') snap_time,
        dhsso.object_name,
        dhsso.object_type,
        row_number() over (partition by dhsso.object_name order by dhsso.object_name) rn,
        SUM(db_block_changes_delta) db_block_changes_delta
  FROM dba_hist_seg_stat dhss,
         dba_hist_seg_stat_obj dhsso,
         dba_hist_snapshot dhs
  WHERE dhs.snap_id = dhss.snap_id
    AND dhs.instance_number = dhss.instance_number
    AND dhss.obj# = dhsso.obj#
    AND dhss.dataobj# = dhsso.dataobj#
    AND begin_interval_time  BETWEEN trunc(sysdate) and trunc(sysdate)+1
  GROUP BY to_char(begin_interval_time,'YYYY_MM_DD HH24:MI'),
           dhsso.object_name,
           dhsso.object_type
 order by dhsso.object_name, to_char(begin_interval_time,'YYYY_MM_DD HH24:MI')
            ) a
where 1=1
order by cnt_total desc, object_name, snap_time desc;

SELECT to_char(begin_interval_time,'YYYY_MM_DD HH24:MI') snap_time,
        SUM(db_block_changes_delta)
  FROM dba_hist_seg_stat dhss,
         dba_hist_seg_stat_obj dhsso,
         dba_hist_snapshot dhs
  WHERE dhs.snap_id = dhss.snap_id
    AND dhs.instance_number = dhss.instance_number
    AND dhss.obj# = dhsso.obj#
    AND dhss.dataobj# = dhsso.dataobj#
    AND dhsso.object_name = 'TMP_PERFORMANCE_LAG_LITE'
  GROUP BY to_char(begin_interval_time,'YYYY_MM_DD HH24:MI')
  order by to_char(begin_interval_time,'YYYY_MM_DD HH24:MI') desc;
  
  SELECT to_char(begin_interval_time,'YYYY_MM_DD HH24:MI'),
         dbms_lob.substr(sql_text,4000,1),
         dhss.instance_number,
         dhss.sql_id,executions_delta,rows_processed_delta
  FROM dba_hist_sqlstat dhss,
         dba_hist_snapshot dhs,
         sys.dba_hist_sqltext dhst
  WHERE 1=1
  --AND UPPER(dhst.sql_text) LIKE '%TMP_PERFORMANCE_LAG_LITE%'
    AND dhss.snap_id=dhs.snap_id
    AND dhss.instance_Number=dhs.instance_number
    AND dhss.sql_id = dhst.sql_id
    order by to_char(begin_interval_time,'YYYY_MM_DD HH24:MI') desc;

