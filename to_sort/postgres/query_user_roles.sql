select  pu.usename
,       pr.rolname
from    pg_user pu
,       pg_auth_members pam
,       pg_roles pr
where   1=1
and     pu.usesysid = pam.member
and     pr.oid = pam.roleid
and     pu.usename = 'david.walker'
--and     pr.rolname = 'datasystems'
;