WITH meta AS (
    SELECT  'MIS_PERFORMANCE_LAG_LITE' AS "TABLE_NAME"
    ,       'MPL_DATE'                 AS "COLUMN_NAME"
    FROM    dual
    )
,   hist1 AS (
    SELECT  dh.endpoint_number  AS "EP"
    ,       dh.endpoint_value   AS "VALUE"
    FROM    dba_histograms dh
    ,       meta m
    WHERE   1=1
    AND     dh.table_name  = m.table_name
    AND     dh.column_name = m.column_name
    )
,   hist2 AS (
    SELECT  ep
    ,       value
    ,       LAG(ep) OVER (ORDER BY ep) AS "PREV_EP"
    ,       MAX(ep) OVER ()            AS "MAX_EP"
    FROM    hist1
    )
,   hist3 AS (
    SELECT  value
    ,       ep
    ,       ep - NVL(prev_ep,0) AS "BKT"
    ,       DECODE(ep - NVL(prev_ep,0),0,0,1,0,1) AS "POPULARITY"
    FROM    hist2
    )
,   stats AS (
    SELECT  MAX(ep) AS BktCnt -- should be equal to sum(bkt)
    ,       SUM(CASE WHEN popularity = 1 THEN bkt ELSE 0 END) AS PopBktCnt
    ,       SUM(CASE WHEN popularity = 1 THEN 1   ELSE 0 END) AS popvalcnt
    ,       MAX((SELECT num_distinct AS ndv FROM dba_tab_cols dtc WHERE dtc.table_name = m.table_name AND dtc.column_name = m.column_name)) AS ndv
    ,       MAX((SELECT density      FROM dba_tab_cols dtc WHERE dtc.table_name = m.table_name AND dtc.column_name = m.column_name)) AS density
    FROM    hist3
    ,       meta m
    )
,   fin AS (
    SELECT  s.*
    ,       ROUND(((1/(s.ndv-s.popvalcnt))*((s.bktcnt-s.popbktcnt)/s.bktcnt)),6) NewDensity
    FROM    stats s
    )
SELECT  m.table_name
,       m.column_name
,       ROUND(dts.num_rows*f.newdensity) Selectivity
,       dts.num_rows
,       f.*
FROM    fin f
,       dba_tab_statistics dts
,       meta m
WHERE   1=1
AND     dts.table_name = m.table_name
;