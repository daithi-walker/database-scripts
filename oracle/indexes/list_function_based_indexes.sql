--Source: https://oracle-base.com/articles/10g/index-monitoring

SELECT  owner
,       table_name
,       index_name
FROM    dba_indexes
WHERE   1=1
AND     index_type = 'FUNCTION-BASED NORMAL'
AND     owner = 'OLIVE'
AND     table_name = 'GLOBAL_SEARCH_GOO'
;


--Source: http://orana.info/2013/04/03/dbms_stats-causes-ora-00600-15851/
-- Oracle 11.2.0.1.0 database.
-- DBMS_STATS failed with an ORA-00600 and the first argument was [15851]. On investigation, it seemed to have something to do with the fact that the table had a function based index:


-- with function-based index on date columns and auto-sample size...
EXEC DBMS_STATS.SET_TABLE_PREFS('OLIVE','GLOBAL_SEARCH_GOO','ESTIMATE_PERCENT',DBMS_STATS.AUTO_SAMPLE_SIZE);
--ORA-00600: internal error code, arguments: [15851]--ORA-0600
EXEC DBMS_STATS.GATHER_TABLE_STATS ('OLIVE','GLOBAL_SEARCH_GOO');
-- Set sample size to 100%
EXEC DBMS_STATS.SET_TABLE_PREFS('OLIVE','GLOBAL_SEARCH_GOO','ESTIMATE_PERCENT',100);
-- No error
EXEC DBMS_STATS.GATHER_TABLE_STATS ('OLIVE','GLOBAL_SEARCH_GOO');
