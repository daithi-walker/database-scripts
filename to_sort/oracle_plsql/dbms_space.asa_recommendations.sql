SELECT  tablespace_name
,       segment_owner
,       segment_name
,       segment_type
,       round (allocated_space/1024/1024,2) "Allocated, Mb"
,       round (used_space/1024/1024,2) "Used, Mb"
,       round (reclaimable_space/1024/1024,2) "Reclaimable, Mb"
,       recommendations
,       c1
,       c2
,       c3
from    table(dbms_space.asa_recommendations ())
order by 7 desc
;

SELECT  rec.tablespace_name
,       rec.segment_owner
,       rec.segment_name
,       rec.segment_type
,       round(rec.allocated_space/1024/1024,1) alloc_mb
,       round(rec.used_space/1024/1024, 1 ) used_mb
,       round(rec.reclaimable_space/1024/1024) reclaim_mb
,       round(rec.reclaimable_space/allocated_space*100,0) pctsave
,       rec.recommendations
,       rec.task_id
,       task.execution_end
--FROM    TABLE(dbms_space.asa_recommendations('FALSE','FALSE','FALSE')) rec
FROM    TABLE(dbms_space.asa_recommendations()) rec
,       dba_advisor_tasks task
WHERE   task.task_id = rec.task_id
ORDER BY 7 DESC
;

--you can also manually invoke the run of advisor by submitting of DB job (under a SYSDBA account
-- DOESN'T WORK
DECLARE
    v_job INTEGER;
BEGIN
    DBMS_JOB.SUBMIT(v_job
                   ,'BEGIN DBMS_SCHEDULER.RUN_JOB("AUTO_SPACE_ADVISOR_JOB"); END;'
                   );
    COMMIT;
END;