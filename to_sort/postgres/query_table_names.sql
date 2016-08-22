select  --distinct
        nsp.nspname
,       cls.*
from    pg_class cls
,       pg_namespace nsp
where   1=1
and     nsp.oid = cls.relnamespace
--and     cls.relname = 'pg_toast_11776_index'
and     cls.relfilenode is not null
and     cls.relfilenode <> 0
--and     cls.relkind not in ('p','i')
--and     cls.relname like 'import%'
and     cls.relkind in ('r')  --table
and     nsp.nspname not in
        ('pg_toast'
        ,'pg_catalog'
        ,'public'
        ,'information_schema'
        ,'utils'
        ,'repack'
        )
order by
        nsp.nspname
,       cls.relname
;
