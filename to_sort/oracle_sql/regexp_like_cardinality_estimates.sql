ALTER TABLE arc_pcampaignid_woodstock DROP COLUMN is_mktg_code CASCADE CONSTRAINTS;

ALTER TABLE arc_pcampaignid_woodstock ADD is_mktg_code VARCHAR2(1) AS (CASE WHEN REGEXP_LIKE(pcampaign_id, '(pid_[0-9]+-cid_[0-9]+-aid_[0-9]+)') THEN'Y' ELSE'N' END) CHECK (is_mktg_code IS NOT NULL);

EXEC  dbms_stats.gather_table_stats('OLIVE','arc_pcampaignid_woodstock', method_opt => 'FOR COLUMNS IS_MKTG_CODE SIZE 2');

SET LINESIZE 130
SET AUTOTRACE TRACEONLY;

SELECT  pcampaign_id
FROM    arc_pcampaignid_woodstock
WHERE   1=1
AND     NOT REGEXP_LIKE(pcampaign_id, '(pid_[0-9]+-cid_[0-9]+-aid_[0-9]+)');

SELECT  pcampaign_id
FROM    arc_pcampaignid_woodstock
WHERE   1=1
AND     is_mktg_code = 'N';


SQL> ALTER TABLE arc_pcampaignid_woodstock DROP COLUMN is_mktg_code CASCADE CONSTRAINTS;

Table altered.

SQL> ALTER TABLE arc_pcampaignid_woodstock ADD is_mktg_code VARCHAR2(1) AS (CASE WHEN REGEXP_LIKE(pcampaign_id, '(pid_[0-9]+-cid_[0-9]+-aid_[0-9]+)') THEN'Y' ELSE'N' END) CHECK (is_mktg_code IS NOT NULL);


Table altered.

SQL> EXEC  dbms_stats.gather_table_stats('OLIVE','arc_pcampaignid_woodstock', method_opt => 'FOR COLUMNS IS_MKTG_CODE SIZE 2');

PL/SQL procedure successfully completed.


SQL> SET LINESIZE 130;

SQL> select   num_rows
,        sample_size
,        round(num_rows * .05) est_regexp_like
from     all_tab_statistics where table_name = 'ARC_PCAMPAIGNID_WOODSTOCK';  2    3    4  

  NUM_ROWS SAMPLE_SIZE EST_REGEXP_LIKE
---------- ----------- ---------------
    582841  582841       29142


SET AUTOTRACE TRACEONLY;
SQL> SQL> #
SQL> SELECT  pcampaign_id
FROM    arc_pcampaignid_woodstock
WHERE   1=1
AND     REGEXP_LIKE(pcampaign_id, '(pid_[0-9]+-cid_[0-9]+-aid_[0-9]+)');  2    3    4  

72078 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1580646172

-----------------------------------------------------------------------------------------------
| Id  | Operation     | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |               | 29142 |  4894K|  4750   (1)| 00:00:58 |
|*  1 |  TABLE ACCESS FULL| ARC_PCAMPAIGNID_WOODSTOCK | 29142 |  4894K|  4750   (1)| 00:00:58 |
-----------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter( REGEXP_LIKE ("PCAMPAIGN_ID",U'(pid_[0-9]+-cid_[0-9]+-aid_[0-9]+)'))


Statistics
----------------------------------------------------------
     15  recursive calls
      0  db block gets
      21936  consistent gets
      0  physical reads
      0  redo size
   14943672  bytes sent via SQL*Net to client
      53379  bytes received via SQL*Net from client
       4807  SQL*Net roundtrips to/from client
      0  sorts (memory)
      0  sorts (disk)
      72078  rows processed

SQL> SELECT  pcampaign_id
FROM    arc_pcampaignid_woodstock
WHERE   1=1
AND     is_mktg_code = 'Y';
  2    3    4  

72078 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1580646172

-----------------------------------------------------------------------------------------------
| Id  | Operation     | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |               | 74463 |    12M|  4756   (1)| 00:00:58 |
|*  1 |  TABLE ACCESS FULL| ARC_PCAMPAIGNID_WOODSTOCK | 74463 |    12M|  4756   (1)| 00:00:58 |
-----------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("IS_MKTG_CODE"='Y')


Statistics
----------------------------------------------------------
     15  recursive calls
      0  db block gets
      21936  consistent gets
      0  physical reads
      0  redo size
   14943672  bytes sent via SQL*Net to client
      53379  bytes received via SQL*Net from client
       4807  SQL*Net roundtrips to/from client
      0  sorts (memory)
      0  sorts (disk)
      72078  rows processed

SQL> SQL> SELECT  pcampaign_id
FROM    arc_pcampaignid_woodstock
WHERE   1=1
AND     NOT REGEXP_LIKE(pcampaign_id, '(pid_[0-9]+-cid_[0-9]+-aid_[0-9]+)');
  2    3    4  

510763 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1580646172

-----------------------------------------------------------------------------------------------
| Id  | Operation     | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |               | 29142 |  4894K|  4750   (1)| 00:00:58 |
|*  1 |  TABLE ACCESS FULL| ARC_PCAMPAIGNID_WOODSTOCK | 29142 |  4894K|  4750   (1)| 00:00:58 |
-----------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter( NOT REGEXP_LIKE ("PCAMPAIGN_ID",U'(pid_[0-9]+-cid_[0-9]+-aid_[0-9]+)'))


Statistics
----------------------------------------------------------
     15  recursive calls
      0  db block gets
      50322  consistent gets
      0  physical reads
      0  redo size
   92552905  bytes sent via SQL*Net to client
     375074  bytes received via SQL*Net from client
      34052  SQL*Net roundtrips to/from client
      0  sorts (memory)
      0  sorts (disk)
     510763  rows processed

SQL> SQL> SELECT  pcampaign_id
FROM    arc_pcampaignid_woodstock
WHERE   1=1
AND     is_mktg_code = 'N';
  2    3    4  

510763 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1580646172

-----------------------------------------------------------------------------------------------
| Id  | Operation     | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |               |   508K|    84M|  4756   (1)| 00:00:58 |
|*  1 |  TABLE ACCESS FULL| ARC_PCAMPAIGNID_WOODSTOCK |   508K|    84M|  4756   (1)| 00:00:58 |
-----------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("IS_MKTG_CODE"='N')


Statistics
----------------------------------------------------------
     15  recursive calls
      0  db block gets
      50322  consistent gets
      0  physical reads
      0  redo size
   92552905  bytes sent via SQL*Net to client
     375074  bytes received via SQL*Net from client
      34052  SQL*Net roundtrips to/from client
      0  sorts (memory)
      0  sorts (disk)
     510763  rows processed

SQL> SQL>


SQL> SET AUTOTRACE OFF; 
SQL> COL endpoint_number FORMAT 999,999,999; 
COL frequency FORMAT  999,999,999; 
COL perc FORMAT 99.99; 
COL rough_opt_est FORMAT 999,999,999; 
COL val FORMAT a10; 
COL endpoint_actual_value FORMAT a10; 

SELECT  endpoint_number
,       (endpoint_number - NVL(prev_endpoint,0))  frequency
,       (endpoint_number - NVL(prev_endpoint,0)) / max_endpoint_number  perc
,       ROUND(582841*((endpoint_number - NVL(prev_endpoint,0)) / max_endpoint_number)) rough_opt_est
,       CHR(TO_NUMBER(SUBSTR(hex_val, 2,2),'XX')) ||
        CHR(TO_NUMBER(SUBSTR(hex_val, 4,2),'XX')) ||
        CHR(TO_NUMBER(SUBSTR(hex_val, 6,2),'XX')) ||
        CHR(TO_NUMBER(SUBSTR(hex_val, 8,2),'XX')) ||
        CHR(TO_NUMBER(SUBSTR(hex_val,10,2),'XX')) ||
        CHR(TO_NUMBER(SUBSTR(hex_val,12,2),'XX')) val,
        endpoint_actual_value
FROM    (
        SELECT  endpoint_number,
                MAX(endpoint_number) OVER (PARTITION BY 1) max_endpoint_number,
                LAG(endpoint_number,1) OVER(ORDER BY endpoint_number) prev_endpoint,
                TO_CHAR(endpoint_value,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')hex_val,
                endpoint_actual_value
        FROM    dba_tab_histograms
        WHERE   1=1
        AND     owner = 'OLIVE'
        AND     table_name = 'ARC_PCAMPAIGNID_WOODSTOCK' and column_name = 'IS_MKTG_CODE'
        )
ORDER BY endpoint_number;
SQL> SQL> SQL> SQL> SQL> SQL> SQL>   2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23  
ENDPOINT_NUMBER    FREQUENCY   PERC ROUGH_OPT_EST VAL        ENDPOINT_A
--------------- ------------ ------ ------------- ---------- ----------
      4,782        4,782    .87   508,325 N
      5,483      701    .13    74,516 Y

SQL> 
