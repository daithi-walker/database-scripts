select  pu.usename
,       pr.rolname
from    pg_user pu
,       pg_auth_members pam
,       pg_roles pr
where   1=1
and     pam.member = pu.usesysid
and     pr.oid = pam.roleid
--and     pr.rolname = 'ds_readonly'
--and pu.usename = 'matthew.midgley'
;