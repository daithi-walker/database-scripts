/* LISTS SECURITY RULE DEFINITIONS AND GL ACCOUNT RANGES */
select   fat.application_name
,        fifs.segment_name
,        ffvs.flex_value_set_name
,        ffvr.flex_value_rule_name
--,        ffvr.parent_flex_value_low
--,        ffvr.parent_flex_value_high
,        ffvrl.include_exclude_indicator
,        ffvrl.flex_value_low
,        ffvrl.flex_value_high
from     fnd_flex_value_rules ffvr
,        fnd_flex_value_sets ffvs
,        fnd_flex_value_rule_lines ffvrl
,        fnd_id_flex_segments fifs
,        fnd_application_tl fat
where    1=1
and      lower(fat.application_name) like '%ledger%'
and      ffvr.flex_value_set_id = ffvs.flex_value_set_id
and      ffvr.flex_value_rule_id = ffvrl.flex_value_rule_id
and      fifs.flex_value_set_id = ffvs.flex_value_set_id
and      fifs.application_id = fat.application_id
order by fat.application_name
,        fifs.segment_name
,        ffvs.flex_value_set_name
,        ffvr.flex_value_rule_name
,        ffvrl.include_exclude_indicator desc
,        ffvr.parent_flex_value_low
,        ffvr.parent_flex_value_high
,        ffvrl.flex_value_low
,        ffvrl.flex_value_high
;