--set pagesize 200
--col NAME for a25
--col LEV for a6
--col CONTEXT for a25
--col VALUE for a50
--col USER_PROFILE_OPTION_NAME for a37

select   po.profile_option_name "NAME"
,        po.user_profile_option_name
,        decode(to_char(pov.level_id)
               ,'10001', 'SITE'
               ,'10002', 'APP'
               ,'10003', 'RESP'
               ,'10005', 'SERVER'
               ,'10006', 'ORG'
               ,'10004', 'USER'
               , '???'
               ) "LEV"
,        decode(to_char(pov.level_id)
               ,'10001', ''
               ,'10002', app.application_short_name
               ,'10003', rsp.responsibility_key
               ,'10005', svr.node_name
               ,'10006', org.name
               ,'10004', usr.user_name
               ,'???'
               ) "CONTEXT"
,        pov.profile_option_value "VALUE"
,        substr(substr(po.sql_validation, instr(upper(po.sql_validation),'LOOKUP_TYPE = ')+15),1,instr(substr(po.sql_validation, instr(upper(po.sql_validation),'LOOKUP_TYPE = ')+15),'''')-1) lookup_Val
--,        fl1.meaning
--,        po.sql_validation
from     fnd_profile_options_vl po
,        fnd_profile_option_values pov
,        fnd_user usr
,        fnd_application app
,        fnd_responsibility rsp
,        fnd_nodes svr
,        hr_operating_units org
--,        fnd_lookups fl1
where    1=1
--and      fl1.lookup_type (+) = substr(substr(po.sql_validation, instr(upper(po.sql_validation),'LOOKUP_TYPE = ')+15),1,instr(substr(po.sql_validation, instr(upper(po.sql_validation),'LOOKUP_TYPE = ')+15),'''')-1)
--and      fl1.lookup_code = pov.profile_option_value
and      (
         po.profile_option_name like '%AFLOG%'
         --or
         --po.profile_option_name like '%AFLOG_ENABLED%'
         --or
         --po.profile_option_name like '%FND_INIT_SQL%'
         --or
         --po.user_profile_option_name like '%Debug%'
         --or
         --po.profile_option_name like '%TRACE%'
         --or
         --po.profile_option_name like '%DEBUG%'
         --or
         --po.profile_option_name like '%LOG%'
         )
and      pov.application_id = po.application_id
and      pov.profile_option_id = po.profile_option_id
and      usr.user_id (+) = pov.level_value
and      rsp.application_id (+) = pov.level_value_application_id
and      rsp.responsibility_id (+) = pov.level_value
and      app.application_id (+) = pov.level_value
and      svr.node_id (+) = pov.level_value
and      org.organization_id (+) = pov.level_value
order by "NAME"
,        pov.level_id
,        "VALUE";

select   meaning
from     fnd_lookups
where    1=1
and      lookup_type = 'AFLOG_LEVELS'
and      lookup_code = 6  --pov.profile_option_value above
order by lookup_code
;

SELECT   ROWID
,        APPLICATION_ID
,        PROFILE_OPTION_ID
,        PROFILE_OPTION_NAME
,        USER_PROFILE_OPTION_NAME
,        SQL_VALIDATION
,        HIERARCHY_TYPE
FROM     FND_PROFILE_OPTIONS_VL
WHERE    START_DATE_ACTIVE <= SYSDATE
and      NVL(END_DATE_ACTIVE,SYSDATE) >= SYSDATE
and      (
         SITE_ENABLED_FLAG = 'Y'
         or
         APP_ENABLED_FLAG = 'Y'
         or
         RESP_ENABLED_FLAG = 'Y'
         or
         USER_ENABLED_FLAG = 'Y'
         or
         SERVER_ENABLED_FLAG = 'Y'
         or
         SERVERRESP_ENABLED_FLAG = 'Y'
         or
         ORG_ENABLED_FLAG = 'Y'
         )
and      (
         UPPER(USER_PROFILE_OPTION_NAME) LIKE 'FND: DEBUG LOG%'
         and
            (
            USER_PROFILE_OPTION_NAME LIKE 'fn%'
            or
            USER_PROFILE_OPTION_NAME LIKE 'fN%'
            or
            USER_PROFILE_OPTION_NAME LIKE
            'Fn%'
            or
            USER_PROFILE_OPTION_NAME LIKE 'FN%'
            )
         )
order by user_profile_option_name;