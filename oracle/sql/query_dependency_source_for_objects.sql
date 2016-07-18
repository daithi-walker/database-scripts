select  s.owner
,       s.name
,       s.type
,       s.line
,       s.text
from    all_dependencies d
,       all_source s
where   1=1
and     d.referenced_name in
        (UPPER('mis_archive_dt_delivery_ess')
        ,UPPER('mis_archive_dt_delivery_ess')
        )
and     d.referenced_owner = UPPER('olive')
and     s.owner = d.owner
and     s.name = d.name
and     s.type = d.type
and     upper(s.text) like upper('%source_date%')
order by s.owner
,        s.name
,        s.line;
