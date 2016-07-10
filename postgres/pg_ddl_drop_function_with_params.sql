--Source: http://stackoverflow.com/questions/7622908/drop-function-without-knowing-the-number-type-of-parameters

SELECT format('DROP FUNCTION %s(%s);'
             ,oid::regproc
             ,pg_get_function_identity_arguments(oid))
FROM   pg_proc
WHERE  proname = 'dw_dcm_analytics_ratios' -- name without schema-qualification
--AND    pg_function_is_visible(oid)
;