/* LISTS SECURITY RULES BY RESPONSIBILITY */
select   fat.application_name
,        fifs.segment_name
,        ffvs.flex_value_set_name
,        ffvr.flex_value_rule_name
,        frv.responsibility_name
from     fnd_flex_value_rules ffvr
,        fnd_flex_value_sets ffvs
,        fnd_id_flex_segments fifs
,        fnd_application_tl fat
,        fnd_flex_value_rule_usages ffvru
,        fnd_responsibility_vl frv
where    1=1
--and      ffvr.flex_value_rule_name = 'SCL Accounts restriction'
and      ffvru.flex_value_rule_id = ffvr.flex_value_rule_id
and      ffvs.flex_value_set_id = ffvr.flex_value_set_id
--and      ffvs.flex_value_set_name = ''
and      fifs.flex_value_set_id = ffvs.flex_value_set_id
--and      fifs.segment_name = 'ACCOUNT'
and      fat.application_id = fifs.application_id
--and      lower(fat.application_name) like '%ledger%'
and      frv.responsibility_id = ffvru.responsibility_id
--and 	 frv.responsibility_name like 'PO%RW (Property) BuyRec'
order by fat.application_name
,        fifs.segment_name
,        ffvs.flex_value_set_name
,        ffvr.flex_value_rule_name
,        frv.responsibility_name
;