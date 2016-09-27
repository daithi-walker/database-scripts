--Source: http://stackoverflow.com/questions/14555062/display-default-access-privileges-for-relations-sequences-and-functions-in-post
-- https://www.postgresql.org/docs/9.0/static/sql-alterdefaultprivileges.html

--psql
--\ddp - command to obtain information about existing assignments of default privileges. The meaning of the privilege values is the same as explained for \dp under GRANT.

--SQL
SELECT  pg_catalog.pg_get_userbyid(d.defaclrole) AS "Owner"
,       n.nspname AS "Schema"
,       CASE d.defaclobjtype WHEN 'r' THEN 'table' WHEN 'S' THEN 'sequence' WHEN 'f' THEN 'function' WHEN 'T' THEN 'type' END AS "Type"
,       pg_catalog.array_to_string(d.defaclacl, E'\n') AS "Access privileges"
FROM    pg_catalog.pg_default_acl d
LEFT JOIN pg_catalog.pg_namespace n ON (n.oid = d.defaclnamespace)
ORDER BY 1, 2, 3;

