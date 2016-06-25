select   fscpv.parameter_value "SMTP Host Name"
         --SMTP protocol uses default port number 25 for outgoing emails
,        25                    "SMTP Port Number" 
,        fscpt.description
from     apps.fnd_svc_comp_params_tl fscpt
,        apps.fnd_svc_comp_param_vals fscpv
where    1=1
and      fscpt.parameter_id = fscpv.parameter_id
and      fscpt.display_name = 'Outbound Server Name' --'Inbound Server Name'
and      fscpt.language = 'US'
;