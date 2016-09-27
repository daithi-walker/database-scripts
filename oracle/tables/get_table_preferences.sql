SELECT  owner
,       table_name
,       DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'INCREMENTAL') incremental
,       DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'GRANULARITY') granularity
,       DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'STALE_PERCENT') stale_percent
,       DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'ESTIMATE_PERCENT') estimate_percent
,       DBMS_STATS.get_prefs(ownname=>USER,tabname=>table_name,pname=>'CASCADE') cascade
,       DBMS_STATS.get_prefs(pname=>'METHOD_OPT') method_opt
FROM    dba_tables
WHERE   1=1
AND     table_owner = 'OLIVE'
AND     table_name = 'GLOBAL_SEARCH_GOO'
ORDER BY owner
,        table_name;
