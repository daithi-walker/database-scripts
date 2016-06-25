SELECT   ffv.descriptive_flexfield_name "DFF Name"
,        ffv.application_table_name "Table Name"
,        ap.application_name "Application"
,        ffv.title "Title"
,        ffv.freeze_flex_definition_flag "Freeze Flexfield Definition"
,        ffv.concatenated_segment_delimiter "Segment Separator"
,        ffv.form_context_prompt "Prompt"
,        ffv.default_context_value "Default Value"
,        ffv.default_context_field_name "Reference Field"
,        ffv.context_user_override_flag "Override Allowed"
,        ffv.context_required_flag "Value required"
,        ffc.descriptive_flex_context_code "Context Code"
,        ffc.descriptive_flex_context_name "Context Name"
,        ffc.description "Context Desc"
,        ffc.enabled_flag "Context Enable Flag"
,        att.column_seq_num "Segment Number"
,        att.form_left_prompt "Segment Name"
,        att.application_column_name "Column"
,        fvs.flex_value_set_name "Value Set"
,        att.display_flag "Displayed"
,        att.enabled_flag "Enabled"
,        att.required_flag "Required"
,        att.end_user_column_name "Segment Name"
,        att.description "Segment Description"
,        att.application_column_name "Segment Column"
,        att.column_seq_num "Segment Number"
,        att.display_flag "Segment Displayed"
,        att.enabled_flag "Segment Enabled"
,        fvs.flex_value_set_name "SegementValue Set"
,        DECODE(att.default_type,'C','Constant',att.default_type) "Segment Default Type"
,        att.default_value "Segment Default Value"
,        att.required_flag "Segment Required"
,        att.security_enabled_flag "Segment Security Enable"
,        att.range_code "Segment range_code"
,        att.display_size "Segment Display Size"
,        att.maximum_description_len "Segment Desc Size"
,        att.concatenation_description_len "Segment Conc Desc Size"
FROM     apps.fnd_descriptive_flexs_vl ffv
,        apps.fnd_application_vl ap
,        apps.fnd_descr_flex_contexts_vl ffc
,        apps.fnd_descr_flex_col_usage_vl att
,        apps.fnd_flex_value_sets fvs
WHERE    1=1
AND      ap.application_id = ffv.application_id
AND      ffc.descriptive_flexfield_name = ffv.descriptive_flexfield_name
AND      ffc.application_id = ffv.application_id
AND      att.descriptive_flexfield_name = ffv.descriptive_flexfield_name
AND      att.descriptive_flex_context_code = ffc.descriptive_flex_context_code
AND      fvs.flex_value_set_id (+) = att.flex_value_set_id
AND      ffv.title NOT LIKE '%$SRS$%' -- report parameters
--AND      ffv.title = 'Account Combination Information'
--AND      ffc.descriptive_flex_context_code <> 'Global Data Elements'
AND      ffv.application_table_name = 'RCV_TRANSACTIONS'
ORDER BY ap.application_name
,        ffv.title
,        ffc.descriptive_flex_context_code
,        att.column_seq_num
;