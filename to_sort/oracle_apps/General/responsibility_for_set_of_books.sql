SELECT   ftl.responsibility_name
,        hou.name organization_name
,        hle.name legal_entity_name
,        gsob.name set_of_books_name
--,        fpot.user_profile_option_name
--,        fpov.profile_option_value
--,        decode(level_id,10001,'Site', 10002,'Appl', 10003,'Resp',10004,'User', 10005,'Server', 10006,'Organization', level_id) "Level"
--,        level_value lvl_val
FROM     apps.fnd_profile_option_values fpov
,        apps.fnd_profile_options fpo
,        apps.fnd_responsibility_tl ftl
,        apps.fnd_profile_options_tl fpot
,        hr_organization_units hou
,        hr_legal_entities hle
,        gl_sets_of_books gsob
WHERE    1=1
AND      fpov.profile_option_id = fpo.profile_option_id
AND      ftl.responsibility_id = nvl(fpov.level_value,   ftl.responsibility_id)
--AND      ftl.responsibility_name LIKE 'Payables - Payments%' -- - MRPI%' -- ROI - Primary'
AND      fpo.profile_option_name = fpot.profile_option_name
AND      fpot.profile_option_name = 'ORG_ID'
AND      fpot.user_profile_option_name LIKE 'MO%'
AND      fpot.LANGUAGE = 'US'
AND      ftl.LANGUAGE = 'US'
AND      hou.organization_id = fpov.profile_option_value
AND      hle.organization_id = fpov.profile_option_value
AND      gsob.set_of_books_id = hle.set_of_books_id
--AND      gsob.name = ''
ORDER BY ftl.responsibility_name
;