select   *
from     (
         select   osuser
         ,        count(*) user_cnt
         from     v$session
         group by osuser
         )
order by user_cnt desc;