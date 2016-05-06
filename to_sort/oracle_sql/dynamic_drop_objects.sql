select * from all_objects where objecT_name like 'DWTEST%';

select 'drop '||object_type||' '||object_name||';' vsql from all_objects where objecT_name like 'DWTEST%' and object_type in ('TABLE','PROCEDURE','PACKAGE');