select   substr(o.owner,1,20)
,        substr(o.object_name,1,30)
,        substr(o.object_type,1,20) 
,        substr(o.status,1,10) Stat
,        o.last_ddl_time
--,        substr(s.text,1,80) Description 
from     all_objects o
--,        all_source s
WHERE    1=1
and      o.object_type = 'PACKAGE BODY'
and      o.object_name like '%API%'
--and      o.owner = 'APPS'
--and      o.object_type = 'TABLE'
--and      o.object_name like '%AP_EXPENSE%'
--and      o.owner = 'AP'
and      s.name = o.object_name
and      s.type = o.object_type
and      s.text like '%Header%'
--and      UPPER(s.text) like '%AP_EXPENSE_REPORT_HEADERS_ALL%'
order by o.owner
,        o.object_name
,        o.object_type
;