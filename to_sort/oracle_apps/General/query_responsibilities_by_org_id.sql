select   p.profile_option_name SHORT_NAME
,        n.user_profile_option_name NAME
,        decode(v.level_id
               ,10001, 'Site'
               ,10002, 'Application'
               ,10003, 'Responsibility'
               ,10004, 'User'
               ,10005, 'Server'
               ,10006, 'Org'
               ,10007, decode(to_char(v.level_value2)
                             ,'-1', 'Responsibility'
                             ,decode(to_char(v.level_value)
                                   ,'-1', 'Server'
                                   ,'Server+Resp'
                                   )
                             )
               ,'UnDef'
               ) LEVEL_SET
,        decode(to_char(v.level_id)
               ,'10001', ''
               ,'10002', app.application_short_name
               ,'10003', rsp.responsibility_key
               ,'10004', usr.user_name
               ,'10005', svr.node_name
               ,'10006', org.name
               ,'10007', decode(to_char(v.level_value2)
                               ,'-1', rsp.responsibility_key
                               ,decode(to_char(v.level_value)
                                      ,'-1',(
                                            select    node_name
                                            from      fnd_nodes
                                            where     1=1
                                            and       node_id = v.level_value2
                                            )
                                      ,(
                                       select   node_name
                                       from     fnd_nodes
                                       where    node_id = v.level_value2
                                       )||'-'||rsp.responsibility_key
                                       )
                                )
               ,'UnDef') "CONTEXT"
,        v.profile_option_value VALUE
from     fnd_profile_options p
,        fnd_profile_option_values v
,        fnd_profile_options_tl n
,        fnd_user usr
,        fnd_application app
,        fnd_responsibility rsp
,        fnd_nodes svr
,        hr_operating_units org
where    1=1
and      p.profile_option_id = v.profile_option_id (+)
and      p.profile_option_name = n.profile_option_name
and      upper(p.profile_option_name) in
         (
         select   profile_option_name
         from     fnd_profile_options_tl 
         where    1=1
         and      upper(user_profile_option_name) like upper('MO: Operating Unit')
         )
and      usr.user_id (+) = v.level_value
and      rsp.application_id (+) = v.level_value_application_id
and      rsp.responsibility_id (+) = v.level_value
and      app.application_id (+) = v.level_value
and      svr.node_id (+) = v.level_value
and      org.organization_id (+) = v.level_value
and      v.profile_option_value = '104'  --org_id...
order by short_name
,        user_profile_option_name
,        level_id
,        level_set;