######Request Set#####
SELECT   frt.responsibility_name
,        frg.request_group_name
,        frgu.request_unit_type
,        frgu.request_unit_id
,        fcpt.user_request_set_name
FROM     apps.fnd_responsibility fr
,        apps.fnd_responsibility_tl frt
,        apps.fnd_request_groups frg
,        apps.fnd_request_group_units frgu
,        apps.fnd_request_sets_tl fcpt
WHERE    1=1
AND      frt.responsibility_id = fr.responsibility_id
AND      frg.request_group_id = fr.request_group_id
AND      frgu.request_group_id = frg.request_group_id
AND      fcpt.request_set_id = frgu.request_unit_id
AND      frt.language = USERENV('LANG')
AND      fcpt.language = USERENV('LANG')
--AND      fcpt.user_request_set_name LIKE '%%'
ORDER BY frt.responsibility_name
,        frg.request_group_name
,        frgu.request_unit_type
,        frgu.request_unit_id;