ALTER SESSION SET nls_language='american';

SELECT   fst.id_flex_structure_name
,        r.flex_validation_rule_name
,        r.enabled_flag
,        r.error_segment_column_name
,        tl.description 
,        tl.error_message_text
,        l.enabled_flag
,        l.include_exclude_indicator
,        l.concatenated_segments_low
,        l.concatenated_segments_high
,        l.last_updated_by
,        l.last_update_date 
FROM     fnd_flex_validation_rules r
,        fnd_flex_vdation_rules_tl tl
,        fnd_flex_validation_rule_lines l
,        fnd_id_flex_structures_vl fst
WHERE    1=1
AND      r.application_id = tl.application_id
AND      fst.id_flex_num = r.id_flex_num
AND      r.id_flex_code = tl.id_flex_code
AND      r.id_flex_num = tl.id_flex_num 
AND      r.flex_validation_rule_name = tl.flex_validation_rule_name
AND      r.application_id = l.application_id
AND      r.id_flex_code = l.id_flex_code
AND      r.id_flex_num = l.id_flex_num 
AND      r.flex_validation_rule_name = l.flex_validation_rule_name
AND      r.flex_validation_rule_name = l.flex_validation_rule_name
AND      r.application_id = 101 --    optional filters below to limit query to specific cvr or lines
--AND    r.error_segment_column_name = 'SEGMENT5'
--AND    tl.error_message_text LIKE '%PLEASE USE A VALID R%'
--AND    r.flex_validation_rule_name LIKE 'BE GROUP ERROR%'
--AND    tl.error_message_text LIKE '%94005%'
--AND    l.include_exclude_indicator = 'E'
ORDER BY 1
,        r.flex_validation_rule_name
,        l.include_exclude_indicator DESC
,        l.concatenated_segments_low