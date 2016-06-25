SELECT   fpo.profile_option_name SHORT_NAME
,        fpot.user_profile_option_name NAME
,        DECODE(fpov.level_id
               ,10001, 'Site'
               ,10002, 'Application'
               ,10003, 'Responsibility'
               ,10004, 'User'
               ,10005, 'Server'
               ,'UnDef'
               ) "LEVEL_SET"
,        DECODE(TO_CHAR(fpov.level_id)
               ,'10001', ''
               ,'10002', fap.application_short_name
               ,'10003', frsp.responsibility_key
               ,'10005', fnod.node_name
               ,'10006', hou.name
               ,'10004', fu.user_name
               ,'UnDef'
               ) "CONTEXT"
,        fpov.profile_option_value VALUE
FROM     fnd_profile_options fpo
,        fnd_profile_option_values fpov
,        fnd_profile_options_tl fpot
,        fnd_user fu
,        fnd_application fap
,        fnd_responsibility frsp
,        fnd_nodes fnod
,        hr_operating_units hou
WHERE    1=1
AND      fpo.profile_option_id = fpov.profile_option_id(+)
AND      fpo.profile_option_name = fpot.profile_option_name
AND      fu.user_id(+) = fpov.level_value
AND      frsp.application_id(+) = fpov.level_value_application_id
AND      frsp.responsibility_id(+) = fpov.level_value
AND      fap.application_id(+) = fpov.level_value
AND      fnod.node_id(+) = fpov.level_value
AND      hou.organization_id(+) = fpov.level_value
--AND      fpot.user_profile_option_name like ''
AND      fpo.profile_option_name like '%FND_MO_INIT_CI_DEBUG%'
ORDER BY short_name;