select   fpot.profile_option_name
,        fpov.profile_option_value
,        fpov.last_updated_by
,        fpov.last_update_date
FROM     fnd_profile_options fpo
,        fnd_profile_option_values fpov
,        fnd_profile_options_tl fpot
WHERE    1=1
AND      fpo.profile_option_id = fpov.profile_option_id(+)
AND      fpo.profile_option_name = fpot.profile_option_name
--AND      fpot.profile_option_name like 'BSK_OUT_DIRECTORY'
AND      fpot.profile_option_name like 'BSK%'
;