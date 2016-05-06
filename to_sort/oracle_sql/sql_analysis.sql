--if we know how to identify the session, then we can identify the long running sql_ids for that session to analyse.
select  *
from    v$session_longops
where   1=1
and     sid = :sid
and     serial# = :serial
order by sql_exec_start;

-- identify child_number using value_string
select  *
from    v$sql_bind_capture
where   1=1
and     sql_id = :sql_id;
-- value_string for 6txuup7bbjckv is '2016-03-08 16:13:09'

-- can identify plan_hash_value for sql_id
select  *
from    v$sql
where   1=1
and     sql_id =:sql_id
and     child_number = :child_number
;


select  *
from    v$sql_plan
where   1=1
and     sql_id = :sql_id
and     plan_hash_value = :plan_hash_value
and     child_number = :child_number  --can get from v$sql_bind_capture if we know what was run with.
order by id
;

select  *
from    v$sql_plan_statistics_all
where   1=1
and     sql_id = :sql_id
and     plan_hash_value = :plan_hash_value
and     child_number = :child_number
order by id
;

--wait events
  --db file sequential read 36  688726
  SELECT tablespace_name, file_name FROM dba_data_files WHERE file_id = 36;
  SELECT owner , segment_name , segment_type FROM dba_extents WHERE file_id = 36 AND 688726 BETWEEN block_id AND block_id + blocks -1;