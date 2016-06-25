select   ses_addr
,        addr
,        used_ublk
,        used_urec
,        case
            when bitand(t.flag,power(2,7)) > 0 then
               'RB in Progress'
            else
               'Not Rolling Back'
         end as "F Status"
from     v$transaction t;