************************************************************************
** SCRIPT
************************************************************************

SET LINESIZE 140;
SET PAGESIZE 100;

SELECT  /*+ GATHER_PLAN_STATISTICS */
        COUNT(*)
FROM    mis_performance_lag_lite perf
WHERE   1=1
AND    mpl_date = '30-JUN-2016';

SELECT  *
FROM    TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'ALLSTATS LAST'));

SELECT  /*+ GATHER_PLAN_STATISTICS */
        COUNT(*)
FROM    mis_performance_lag_lite perf
WHERE   1=1
AND     mpl_date BETWEEN to_date('30-JUN-2016 00:00:00','DD-MON-YYYY HH24:MI:SS') AND to_date('30-JUN-2016 23:59:59','DD-MON-YYYY HH24:MI:SS')
;

SELECT  *
FROM    TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'ALLSTATS LAST'));

SELECT  /*+ GATHER_PLAN_STATISTICS */
        dts.num_rows
,       dtcs.num_distinct
,       round(dts.num_rows/dtcs.num_distinct) row_est
FROM    dba_tab_statistics dts
,       dba_tab_col_statistics dtcs
WHERE   1=1
AND     dtcs.owner = dts.owner
AND     dtcs.table_name = dts.table_name
AND     dts.owner = 'OLIVE'
AND     dts.table_name = 'MIS_PERFORMANCE_LAG_LITE'
AND     dtcs.column_name = 'MPL_DATE';

SELECT  endpoint_number,
        (endpoint_number - nvl(prev_endpoint,0))  frequency,
        (endpoint_number - nvl(prev_endpoint,0)) / max_endpoint_number  perc,
        ROUND(6077793*(endpoint_number - NVL(prev_endpoint,0)) / max_endpoint_number)  hist_estimate,
        TO_DATE(endpoint_value,'J') endpoint_value
FROM    (
        SELECT  endpoint_number,
                MAX(endpoint_number) OVER (PARTITION BY 1) max_endpoint_number,
                lag(endpoint_number,1) OVER(ORDER BY endpoint_number) prev_endpoint,
                endpoint_value
        FROM
                dba_tab_histograms dth
        WHERE owner = 'OLIVE'
        AND table_name = 'MIS_PERFORMANCE_LAG_LITE' 
        AND column_name = 'MPL_DATE'
        )
WHERE   TO_DATE(endpoint_value,'J') BETWEEN '30-JUN-2016' AND '30-JUN-2016'
ORDER BY endpoint_number;


************************************************************************
** SCRIPT OUTPUT
************************************************************************

OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk> SET LINESIZE 140;
SET PAGESIZE 100;

SELECT  /*+ GATHER_PLAN_STATISTICS */
        COUNT(*)
FROM    mis_performance_lag_lite perf
WHERE   1=1
AND    mpl_date = '30-JUN-2016';

SELECT  *
FROM    TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'ALLSTATS LAST'));

SELECT  /*+ GATHER_PLAN_STATISTICS */
        COUNT(*)
FROM    mis_performance_lag_lite perf
WHERE   1=1
AND     mpl_date BETWEEN to_date('30-JUN-2016 00:00:00','DD-MON-YYYY HH24:MI:SS') AND to_date('30-JUN-2016 23:59:59','DD-MON-YYYY HH24:MI:SS')
;

SELECT  *
FROM    TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT=>'ALLSTATS LAST'));
OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk> OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk> OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk>   2    3    4    5  
  COUNT(*)
----------
     20623

OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk> OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk>   2  
PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  du8w7su51v0d0, child number 0
-------------------------------------
SELECT  /*+ GATHER_PLAN_STATISTICS */         COUNT(*) FROM
mis_performance_lag_lite perf WHERE   1=1 AND    mpl_date =
'30-JUN-2016'

Plan hash value: 3131247872

-------------------------------------------------------------------------------------------------------
| Id  | Operation     | Name            | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |             |      1 |        |      1 |00:00:00.01 |     215 |
|   1 |  SORT AGGREGATE   |             |      1 |      1 |      1 |00:00:00.01 |     215 |
|*  2 |   INDEX RANGE SCAN| PERFORMANCE_LAG_LITE_PK |      1 |   4740 |  20623 |00:00:00.01 |     215 |
-------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("MPL_DATE"=TO_DATE(' 2016-06-30 00:00:00', 'syyyy-mm-dd hh24:mi:ss'))


21 rows selected.

OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk> OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk>   2    3    4    5    6  
  COUNT(*)
----------
     20623

OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk> OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk>   2  
PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  7u4yv01kny5vs, child number 0
-------------------------------------
SELECT  /*+ GATHER_PLAN_STATISTICS */         COUNT(*) FROM
mis_performance_lag_lite perf WHERE   1=1 AND     mpl_date BETWEEN
to_date('30-JUN-2016 00:00:00','DD-MON-YYYY HH24:MI:SS') AND
to_date('30-JUN-2016 23:59:59','DD-MON-YYYY HH24:MI:SS')

Plan hash value: 3131247872

-------------------------------------------------------------------------------------------------------
| Id  | Operation     | Name            | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |             |      1 |        |      1 |00:00:00.01 |     215 |
|   1 |  SORT AGGREGATE   |             |      1 |      1 |      1 |00:00:00.01 |     215 |
|*  2 |   INDEX RANGE SCAN| PERFORMANCE_LAG_LITE_PK |      1 |  23928 |  20623 |00:00:00.02 |     215 |
-------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("MPL_DATE">=TO_DATE(' 2016-06-30 00:00:00', 'syyyy-mm-dd hh24:mi:ss') AND
          "MPL_DATE"<=TO_DATE(' 2016-06-30 23:59:59', 'syyyy-mm-dd hh24:mi:ss'))


23 rows selected.

OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk> SELECT  /*+ GATHER_PLAN_STATISTICS */
        dts.num_rows
,       dtcs.num_distinct
,       round(dts.num_rows/dtcs.num_distinct) row_est
FROM    dba_tab_statistics dts
,       dba_tab_col_statistics dtcs
WHERE   1=1
AND     dtcs.owner = dts.owner
AND     dtcs.table_name = dts.table_name
AND     dts.owner = 'OLIVE'
AND     dts.table_name = 'MIS_PERFORMANCE_LAG_LITE'
AND     dtcs.column_name = 'MPL_DATE';  2    3    4    5    6    7    8    9   10   11   12  

  NUM_ROWS NUM_DISTINCT    ROW_EST
---------- ------------ ----------
   6077793     1264       4808


OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk> SELECT  endpoint_number,
        (endpoint_number - nvl(prev_endpoint,0))  frequency,
        (endpoint_number - nvl(prev_endpoint,0)) / max_endpoint_number  perc,
        ROUND(6077793*(endpoint_number - NVL(prev_endpoint,0)) / max_endpoint_number)  hist_estimate,
        TO_DATE(endpoint_value,'J') endpoint_value
FROM    (
        SELECT  endpoint_number,
                MAX(endpoint_number) OVER (PARTITION BY 1) max_endpoint_number,
                lag(endpoint_number,1) OVER(ORDER BY endpoint_number) prev_endpoint,
                endpoint_value
        FROM
                dba_tab_histograms dth
        WHERE owner = 'OLIVE'
        AND table_name = 'MIS_PERFORMANCE_LAG_LITE' 
        AND column_name = 'MPL_DATE'
          2  )
WHERE   TO_DATE(endpoint_value,'J') BETWEEN '30-JUN-2016' AND '30-JUN-2016'
ORDER BY endpoint_number;  3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18  

ENDPOINT_NUMBER  FREQUENCY   PERC HIST_ESTIMATE ENDPOINT_
--------------- ---------- ---------- ------------- ---------
        248      1 .003937008         23928 30-JUN-16

OLIVE@ess-lon-ora-001:1521/ffmis.essence.co.uk> 
