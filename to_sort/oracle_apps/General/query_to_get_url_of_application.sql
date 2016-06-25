select   *
from     icx_parameters;

select   fpo.profile_option_name
,        fpov.profile_option_Value
from     fnd_profile_option_Values fpov
,        fnd_profile_options fpo
where    1=1
and      fpo.profile_option_id  = fpov.profile_option_id
and      fpo.profile_option_name like '%AGENT%'
;