SELECT  owner
,       object_name
,       object_type
,       DECODE(object_type
              ,'PACKAGE', 1
              ,'PACKAGE BODY', 2
              ,2) AS recompile_order
,       'DROP ' || object_type ||  ' ' || owner || '.' || object_name || ';' drop_sql
--,       dbms_metadata.get_ddl(object_type,object_name,owner) DDL
FROM    dba_objects
WHERE   1=1
--AND     object_type IN ('VIEW','PROCEDURE')
--AND     object_type IN ('PACKAGE', 'PACKAGE BODY')
AND     status != 'VALID'
AND     owner IN ('OLIVE','SANFRAN')
ORDER BY 4, 3, 1, 2;
