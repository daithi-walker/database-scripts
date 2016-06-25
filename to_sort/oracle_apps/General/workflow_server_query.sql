select fscpv.parameter_value smtp_server_name
from   fnd_svc_comp_params_tl fscpt
,      fnd_svc_comp_param_vals fscpv
,      fnd_svc_components fsc
where  fscpt.parameter_id = fscpv.parameter_id
and    fscpv.component_id = fsc.component_id
and    fscpt.display_name = 'Outbound Server Name'
and    fsc.component_name = 'Workflow Notification Mailer';