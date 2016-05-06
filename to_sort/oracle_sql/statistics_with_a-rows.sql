--select * from table(dbms_xplan.display_cursor(null,null,'allstats  +peeked_binds'));


select * from v$parameter where name = 'statistics_level';

alter session set statistics_level='ALL';

begin
    dbms_stats.gather_table_stats('olive','MKTG_BOOKINGS'); end;
    dbms_stats.gather_index_stats('olive','FK_MKTG_BOOKINGS_MKTG_CAMPAIG');
end;

select bks_id from mktg_bookings WHERE bks_cam_id = 4847;

select * from table(dbms_xplan.display_cursor(null,null, 'ALLSTATS LAST'));


SQL_ID  5pckpgvh6yj6b, child number 1
-------------------------------------
select bks_id from mktg_bookings WHERE bks_cam_id = 4847
 
Plan hash value: 749188997
 
-----------------------------------------------------------------------------------------------------------------------
| Id  | Operation                   | Name                          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-----------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |                               |      1 |        |     18 |00:00:00.01 |       8 |
|   1 |  TABLE ACCESS BY INDEX ROWID| MKTG_BOOKINGS                 |      1 |     13 |     18 |00:00:00.01 |       8 |
|*  2 |   INDEX RANGE SCAN          | FK_MKTG_BOOKINGS_MKTG_CAMPAIG |      1 |     13 |     18 |00:00:00.01 |       2 |
-----------------------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("BKS_CAM_ID"=4847)
 

 SELECT  leaf_blocks
 ,       num_rows
 ,       clustering_factor
 ,       distinct_keys
 ,       avg_leaf_blocks_per_key
 ,       last_analyzed
FROM     all_indexes
WHERE    1=1
AND      index_name = 'FK_MKTG_BOOKINGS_MKTG_CAMPAIG';

"LEAF_BLOCKS","NUM_ROWS","CLUSTERING_FACTOR","DISTINCT_KEYS","AVG_LEAF_BLOCKS_PER_KEY","LAST_ANALYZED"
128,59374,14030,4437,1,17-FEB-16 07.30.37

SELECT  COUNT(*) as num_rows
,       COUNT(DISTINCT bks_cam_id) as distinct_keys
,       COUNT(NULLIF(bks_cam_id,4847)) AS rows_per_key_4847
FROM    mktg_bookings;


select /*+ dynamic_sampling (mktg_bookings 2) */ bks_id from mktg_bookings WHERE bks_cam_id = 4847;

SQL_ID  94vmdzvgcd8n8, child number 1
-------------------------------------
select /*+ dynamic_sampling (mktg_bookings 2) */ bks_id from 
mktg_bookings WHERE bks_cam_id = 4847
 
Plan hash value: 749188997
 
-----------------------------------------------------------------------------------------------------------------------
| Id  | Operation                   | Name                          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-----------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |                               |      1 |        |     18 |00:00:00.01 |       8 |
|   1 |  TABLE ACCESS BY INDEX ROWID| MKTG_BOOKINGS                 |      1 |     25 |     18 |00:00:00.01 |       8 |
|*  2 |   INDEX RANGE SCAN          | FK_MKTG_BOOKINGS_MKTG_CAMPAIG |      1 |     13 |     18 |00:00:00.01 |       2 |
-----------------------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("BKS_CAM_ID"=4847)
 
Note
-----
   - dynamic sampling used for this statement (level=2)


select /*+ dynamic_sampling (mktg_bookings 7) */ bks_id from mktg_bookings WHERE bks_cam_id = 4847;

SQL_ID  917d8jxg0hq92, child number 0
-------------------------------------
select /*+ dynamic_sampling (mktg_bookings 7) */ bks_id from 
mktg_bookings WHERE bks_cam_id = 4847
 
Plan hash value: 749188997
 
-----------------------------------------------------------------------------------------------------------------------
| Id  | Operation                   | Name                          | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-----------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |                               |      1 |        |     18 |00:00:00.01 |       8 |
|   1 |  TABLE ACCESS BY INDEX ROWID| MKTG_BOOKINGS                 |      1 |     18 |     18 |00:00:00.01 |       8 |
|*  2 |   INDEX RANGE SCAN          | FK_MKTG_BOOKINGS_MKTG_CAMPAIG |      1 |     13 |     18 |00:00:00.01 |       2 |
-----------------------------------------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
   2 - access("BKS_CAM_ID"=4847)
 
Note
-----
   - dynamic sampling used for this statement (level=2)
 
 