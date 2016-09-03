--Source:
--http://blog.2ndquadrant.com/auditing-users-and-roles-in-postgresql/

--CREATE VIEW priv_membership AS
WITH    RECURSIVE membership_tree(grpid, userid)
AS      (
        SELECT  DISTINCT
                pg_roles.oid
        ,       pg_roles.oid
        FROM    pg_roles
        UNION ALL
        SELECT  m.roleid
        ,       t.userid
        FROM    pg_auth_members m
        JOIN    membership_tree t
        ON      m.member = t.grpid
        )
SELECT  DISTINCT
        t.userid
,       r.rolname AS usrname
,       t.grpid
,       m.rolname AS grpname
FROM    membership_tree t
JOIN    pg_roles r ON r.oid = t.userid
JOIN    pg_roles m ON m.oid = t.grpid
ORDER BY r.rolname
,        m.rolname;