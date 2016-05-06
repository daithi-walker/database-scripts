select vp.spid
,      vs.sid
,      vs.event
,      vs.state
,      vs.sql_id
,      vs.prev_sql_id
,      vs.seconds_in_wait
,      vs.p1
,      vs.p1raw
,      vs.p1text
,      vs.p2
,      vs.p2text
,      vs.p3
,      vs.p3text
,      vs.row_wait_obj#
,      vs.plsql_object_id
,      vs.plsql_subprogram_id
from   v$session vs
,      v$process vp
where  1=1
and    vs.paddr = vp.addr
--and    vp.spid = :PID
and    vs.sid = :SID
;

select latch# from v$latch where name = 'cache buffers chains';
select count(1) cnt from v$latch_children where latch# = 150;
--same as 
select count(*) from v$latch_children where name = 'cache buffers chains'

show parameter db_block_buffers --0

--0000000270ABAB68
select addr, gets, misses, sleeps from  v$latch_children  where name = 'cache buffers chains' and misses > 100 and addr = '00000002708B7168';

SELECT file#, dbarfil, dbablk, class, state, tch
FROM X$BH
WHERE HLADDR='0000000270ABAB68';

MKTG_CODE_REFERENCE_CD_PL

SELECT file_id, block_id, owner, segment_name
FROM DBA_EXTENTS
WHERE 1=1
--and   file_id = :file_id  AND :block_id between block_id AND block_id + blocks - 1
and (
    (file_id = 41 AND 1574842 between block_id AND block_id + blocks - 1) OR
    (file_id = 72 AND 3212619 between block_id AND block_id + blocks - 1) OR
    (file_id = 36 AND 199607 between block_id AND block_id + blocks - 1) OR
    (file_id = 58 AND 3934248 between block_id AND block_id + blocks - 1) OR
    (file_id = 54 AND 2173541 between block_id AND block_id + blocks - 1) OR
    (file_id = 39 AND 943968 between block_id AND block_id + blocks - 1) OR
    (file_id = 11 AND 2133292 between block_id AND block_id + blocks - 1) OR
    (file_id = 53 AND 2537090 between block_id AND block_id + blocks - 1) OR
    (file_id = 11 AND 3928559 between block_id AND block_id + blocks - 1) or
    (file_id = 15 AND 2028858 between block_id AND block_id + blocks - 1)
    );


select o.name, bh.dbarfil, bh.dbablk, bh.tch
from x$bh bh, sys.obj$ o
where tch > 0
and hladdr = '0000000270ABAB68'
and o.obj#=bh.obj
order by tch;
