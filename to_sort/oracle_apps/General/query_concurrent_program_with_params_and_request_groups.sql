select   fcpt.user_concurrent_program_name
,        fcp.concurrent_program_name
,        fa2.application_short_name
,        fat2.application_name
,        fcpt.description
,        fev.executable_name
,        decode(fev.execution_method_code,'P','Oracle Reports','I','PL/SQL Stored Procedure',fev.execution_method_code) method
,        fev.execution_file_name
,        fdfcuv.end_user_column_name
,        fdfcuv.description
,        fvs.flex_value_set_name
,        fdfcuv.default_type
,        fdfcuv.default_value
,        fdfcuv.enabled_flag
,        fdfcuv.required_flag
,        fa1.application_short_name
,        fat1.application_name
,        frg.request_group_name
,        frv.responsibility_name
from     fnd_concurrent_programs_tl fcpt
,        fnd_concurrent_programs fcp
,        fnd_request_groups frg
,        fnd_request_group_units frgu
,        fnd_application_tl fat1
,        fnd_application fa1
,        fnd_application_tl fat2
,        fnd_application fa2
,        fnd_responsibility_vl frv
,        fnd_executables_vl fev
,        fnd_descr_flex_col_usage_vl fdfcuv
,        fnd_flex_value_sets fvs
where    1=1
and      fdfcuv.descriptive_flexfield_name='$SRS$.'||fcp.concurrent_program_name
and      fvs.flex_value_set_id (+) = fdfcuv.flex_value_set_id
and      fat2.application_id = fcp.application_id
and      fa2.application_id = fcp.application_id
and      fcp.concurrent_program_id = fcpt.concurrent_program_id
and      fev.executable_id = fcp.executable_id
and      frgu.request_unit_id (+) = fcpt.concurrent_program_id
and      frg.request_group_id (+) = frgu.request_group_id
and      fat1.application_id (+) = frg.application_id
and      fa1.application_id (+) = frg.application_id
and      frv.request_group_id (+) = frg.request_group_id
and      fcpt.user_concurrent_program_name like 'XXMET%'
--       and fvs.flex_value_set_name = 'XXMET_COST_CENTRE_CATEGORIES'
order by fcpt.user_concurrent_program_name
,        fat1.application_name
,        frg.request_group_name
,        frv.responsibility_name
,        fdfcuv.application_column_name
;