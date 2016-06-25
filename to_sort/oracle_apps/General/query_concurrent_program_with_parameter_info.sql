SELECT cp.user_concurrent_program_name "Program Name",
cp.concurrent_program_name "Short Name",
ap.application_name "Application",
cp.description "Description",
cp.enabled_flag "Enabled",
cp.output_file_type "Output Format",
cx.executable_name "Executable Short Name",
lv.meaning "Executable Method",
cx.user_executable_name "Executable Name",
df.column_seq_num "Sequence",
df.end_user_column_name "Parameter" ,
df.srw_param,
df.description "Desciption",
df.enabled_flag "Parameter Enabled",
df.required_flag "Parameter Required",
df.security_enabled_flag "Enable Security",
df.display_flag "Parameter Display",
fvs.flex_value_set_name "Value Set",
df.default_type "Default Type",
df.default_value "Default Value"
FROM apps.fnd_concurrent_programs_vl cp,
apps.fnd_executables_form_v cx,
apps.fnd_application_vl ap,
apps.fnd_descr_flex_col_usage_vl df,
apps.fnd_flex_value_sets fvs,
apps.fnd_lookup_values lv
WHERE cp.executable_id=cx.executable_id
AND cp.application_id=ap.application_id
AND fvs.flex_value_set_id=df.flex_value_set_id
AND lv.lookup_type = 'CP_EXECUTION_METHOD_CODE'
AND lv.lookup_code = cx.execution_method_code
--AND cp.concurrent_program_name like '%%'
AND df.descriptive_flexfield_name = '$SRS$.'||cp.concurrent_program_name
--AND lv.language='US
and df.default_value like '%FLEX%'
ORDER BY df.column_seq_num;