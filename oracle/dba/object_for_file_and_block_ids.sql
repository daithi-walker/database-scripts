WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;
WHENEVER OSERROR EXIT 9;

SET LINESIZE 160
SET PAGESIZE 100

PROMPT ***********************************************************
PROMPT ** object_for_file_and_block_ids.sql
PROMPT ***********************************************************
PROMPT ** The following returns the object that is stored in a 
PROMPT ** specific file/block.
PROMPT ***********************************************************

------------------------------------------------------------------
-- SAMPLE USE:
-- sqllsys @ ~/git/database-scripts/oracle/dba/object_for_file_and_block_ids.sql 5 128
--
-- RELATIVE_FNO OWNER      SEGMENT_NAME         SEGMENT_TYPE
-- ------------ ---------- -------------------- ------------
--            5 OLIVE      ML_RELEASE           TABLE
--
------------------------------------------------------------------

SET TERMOUT OFF;

VAR file_id NUMBER;
EXEC :file_id := &1;

VAR block_id NUMBER;
EXEC :block_id := &2;

COL relative_fno FOR 9999;
COL owner        FOR A10;
COL segment_name FOR A20;
COL segment_type FOR A12;

SET TERMOUT ON;

SELECT  relative_fno
,       owner
,       segment_name
,       segment_type
FROM    dba_extents
WHERE   1=1
AND     file_id = :file_id
AND     :block_id BETWEEN block_id AND block_id + blocks - 1
;

EXIT;