SELECT  'GRANT ' || lv_privilege || ' ON ' || LOWER(lv_owner) || '.' || LOWER(lv_table_name) || ' TO ' || LOWER(lv_grantee) || lv_option vsql
FROM    (
        SELECT  ur$.name
        ,       uo$.name lv_owner
        ,       o$.name  lv_grantee
        ,       ue$.name lv_table_name
        ,       m$.name lv_privilege
        ,       t$.sequence# seq
        ,       decode(NVL(t$.option$,0), 1, ' WITH GRANT OPTION;',';') lv_option
        FROM    sys.objauth$ t$
        ,       sys.obj$ o$
        ,       sys.user$ ur$
        ,       sys.table_privilege_map m$
        ,       sys.user$ ue$
        ,       sys.user$ uo$
        WHERE   1=1
        AND     o$.obj# = t$.obj# AND t$.privilege# = m$.privilege
        AND     t$.col# IS NULL AND t$.grantor# = ur$.user#
        AND     t$.grantee# = ue$.user#
        AND     o$.owner#=uo$.user#
        AND     t$.grantor# != 0
        AND     o$.name = 'DDL_AUDIT'
        )
ORDER BY seq;