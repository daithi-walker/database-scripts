select  nsp.nspname
,       cls.*
from    pg_class cls
,       pg_namespace nsp
where   1=1
and     nsp.oid = cls.relnamespace
--and     cls.relname = 'pg_toast_11776_index'
and     relfilenode is not null
and     relfilenode <> 0
and     nsp.nspname in
        ('pg_toast'
        ,'pg_catalog'
        ,'public'
        ,'information_schema'
        ,'utils'
        )
;
