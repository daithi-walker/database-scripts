SELECT   ffcr.enabled
,        ffcr.description personalization_desc
,        ffcr.condition
,        ffcr.trigger_object
,        ffcr.sequence
,        ffcr.form_name
,        fft.user_form_name
,        fff.function_name
,        ffft.user_function_name
,        fff.type
FROM     fnd_form_custom_rules ffcr
,        fnd_form_functions fff
,        fnd_form_functions_tl ffft
,        fnd_form_tl fft
WHERE    1=1
AND      fff.function_id = ffft.function_id
AND      fft.form_id = fff.form_id
AND      ffcr.function_name = fff.function_name
--AND      fff.function_name like '%'
--AND      UPPER(ffcr.condition) LIKE '%%'
--AND      ffcr.function_name LIKE 'ONT_OEXOEORD%'
AND      ffcr.form_name = 'ARXRWMAI'
ORDER BY ffcr.form_name
,        ffcr.sequence;