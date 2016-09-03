select  pu.usename
,       pr.rolname
from    pg_user pu
,       pg_auth_members pam
,       pg_roles pr
where   1=1
and     pam.member = pu.usesysid
and     pr.oid = pam.roleid
--and     pr.rolname = 'ds_readonly'
--and     pu.usename = 'dorota.wymyslowska'
;


-- Source:
-- http://dba.stackexchange.com/questions/145739/postgres-list-role-grants-for-all-users/145786
SELECT  r.rolname
,       r.rolsuper
,       r.rolinherit
,       r.rolcreaterole
,       r.rolcreatedb
,       r.rolcanlogin
,       r.rolconnlimit
,       r.rolvaliduntil
,       ARRAY(
        SELECT  b.rolname
        FROM    pg_catalog.pg_auth_members m
        JOIN    pg_catalog.pg_roles b ON (m.roleid = b.oid)
        WHERE   m.member = r.oid
        ) AS memberof
,       r.rolreplication
--,       r.rolbypassrls
FROM    pg_catalog.pg_roles r
ORDER BY r.rolname;