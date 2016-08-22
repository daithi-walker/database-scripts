
select  *
from    all_objects
where   1=1
and     object_type = 'PACKAGE'
and     owner = 'SYS'
and     object_name like 'DBMS%'
order by object_name;

exit;