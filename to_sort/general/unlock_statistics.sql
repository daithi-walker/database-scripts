exec dbms_stats.unlock_table_stats('{owner}','{table name}');

select   owner
,        table_name
,        stattype_locked
from     dba_tab_statistics
where    1=1
and      stattype_locked is not null
and      owner not in ('SYS','SYSTEM');

select   'exec dbms_stats.unlock_table_stats('''||owner||''','''||table_name||''');' runsql
from     dba_tab_statistics
where    1=1
and      stattype_locked is not null
and      owner not in ('SYS','SYSTEM');