-- excluded menus
SELECT   frv.responsibility_id
,        frv.responsibility_name
,        DECODE(frv.end_date, NULL, 'Y', 'N') active
,        fmt.user_menu_name
,        fmt.description menu_desc
FROM     fnd_resp_functions frf
,        fnd_responsibility_vl frv
,        fnd_menus_tl fmt
WHERE    1=1
AND      frv.responsibility_id = frf.responsibility_id
AND      frf.action_id = fmt.menu_id
AND      frf.rule_type = 'M'
;

-- excluded functions
SELECT   frv.responsibility_id
,        frv.responsibility_name
,        DECODE(frv.end_date, NULL, 'Y', 'N') active
,        fffv.function_id
,        fffv.function_name
,        fffv.user_function_name
FROM     fnd_resp_functions frf
,        fnd_responsibility_vl frv
,        fnd_form_functions_vl fffv
WHERE    1=1
AND      frv.responsibility_id = frf.responsibility_id
AND      frf.action_id = fffv.function_id
AND      frf.rule_type = 'F'
and      frv.responsibility_name = 'Payables - Inquiry - MRPI ROI - Primary';

-- initial menu for responsibility
select   frv.responsibility_id
,        frv.responsibility_name
,        DECODE(frv.end_date, NULL, 'Y', 'N') active
,        fmt.user_menu_name
,        fmt.description menu_desc
,        fme.menu_id
,        fme.entry_sequence
,        fme.sub_menu_id
,        fme.function_id
from     fnd_menus_tl fmt
,        fnd_menu_entries fme
,        fnd_responsibility_vl frv
where    1=1
and      fmt.menu_id = frv.menu_id
and      fme.menu_id = fmt.menu_id
and      frv.responsibility_name = 'Payables - Inquiry - MRPI ROI - Primary';

-- next menu for responsibility
select   fmt.user_menu_name
,        fmt.description menu_desc
,        fme.menu_id
,        fme.entry_sequence
,        fme.sub_menu_id
,        fme.function_id
,        fffv.function_id
,        fffv.function_name
,        fffv.user_function_name
from     fnd_menus_tl fmt
,        fnd_menu_entries fme
,        fnd_form_functions_vl fffv
where    1=1
and      fffv.function_id = fme.function_id
and      fme.menu_id = fmt.menu_id
and      fme.menu_id = 68010
order by fme.entry_sequence;