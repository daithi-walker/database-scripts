--need gather_plan_statistics hint or statistics_level set to all to use allstats.
alter session set statistics_level = all;

select * from v$sql where sql_text like '%gather_plan_statistics%';

select   t.*
from     table(dbms_xplan.display_cursor('270uvh1n6ut69' --sql_id
                                        ,0               --cursor_child_no
                                        ,'ALLSTATS LAST' --format
                                        )) t;
