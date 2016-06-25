select   fmev.description menu_description
,        frt.responsibility_name
from     fnd_menu_entries_vl fmev
,        fnd_responsibility_vl frv
,        fnd_responsibility_tl frt
where    1=1
and      fmev.description like '%Define Banks%'
and      fmev.menu_id = frv.menu_id
and      frt.responsibility_id = frv.responsibility_id
;