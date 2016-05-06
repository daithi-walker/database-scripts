-- to return only one row per object...
SELECT 	grantee
, 		table_schema
, 		table_name
, 		string_agg(privilege_type, ', ') AS privileges
FROM   	information_schema.role_table_grants 
WHERE  	1=1
and    	table_schema = 'ds3'
--AND     table_name = 'planline_report'
AND    	grantee = 'datasystems'
GROUP BY grantee
, 		table_schema
, 		table_name;

-- one row per privilege
SELECT grantee
, 		table_name
, 		privilege_type 
FROM   information_schema.role_table_grants 
WHERE  1=1
and    table_schema = 'ds3'
--AND    table_name = 'planline_report'
AND    grantee = 'datasystems'
;
