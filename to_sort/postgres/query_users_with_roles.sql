select  pg_user.usename
from    pg_user
where   1=1
and     not exists
        (
        select  pu.usename
        from    pg_user pu
        ,       pg_auth_members pam
        ,       pg_roles pr
        where   1=1
        and     pam.member = pu.usesysid
        and     pr.oid = pam.roleid
        and     pr.rolname = 'ds_readonly'
        );