--Source: https://oracle-base.com/articles/10g/index-monitoring

--ALTER INDEX GLOBAL_SEARCH_GOO_LCD_IX MONITORING USAGE;
--ALTER INDEX GLOBAL_SEARCH_GOO_LCD_IX NOMONITORING USAGE;

SELECT index_name,
       table_name,
       monitoring,
       used,
       start_monitoring,
       end_monitoring
FROM   v$object_usage
WHERE  1=1
--AND    index_name = 'GLOBAL_SEARCH_GOO_LCD_IX'
ORDER BY index_name;
