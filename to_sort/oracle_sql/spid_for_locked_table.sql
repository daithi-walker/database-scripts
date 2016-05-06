To find a locked table and related unix process id...

select  vp.spid unix_process_id
,       lo.session_id
,       lo.oracle_username
,       lo.os_user_name
,       do.owner             OBJECT_OWNER
,       do.object_name
,       do.object_type
,       lo.locked_mode
from    v$locked_object lo
,       dba_objects do
,       v$process vp
,       v$session vs
where   1=1
and     lo.object_id = do.object_id
and     vp.addr = vs.paddr
and     vs.sid = lo.session_id
--and     do.object_name = 'MKTG_CODE_REFERENCE'
;

This gives:

"UNIX_PROCESS_ID","SESSION_ID","ORACLE_USERNAME","OS_USER_NAME","OBJECT_OWNER","OBJECT_NAME","OBJECT_TYPE","LOCKED_MODE"
"14696",324,"OLIVE","essence","OLIVE","MIS_ARCHIVE_DT_ACTIVITY","TABLE",3
"23397",8,"OLIVE","essence","OLIVE","ADWORDS_SQR_DELIVERY","TABLE",3
"3039",679,"OLIVE","essence","OLIVE","TMP_PERFORMANCE_LAG_LITE","TABLE",3
"21020",137,"OLIVE","essence","OLIVE","MIS_TGT_CAT_GOOGLE","TABLE",3
"6692",393,"OLIVE","essence","OLIVE","MIS_CMO_ALL_AGENCIES_GOO","TABLE",3

on unix, can check process monitor so see what script is responsibile...

[essence@ess-lon-ora-001 essence]$ ps faux | less

...
essence  10704  0.0  0.0 102164  1380 ?        S    Feb07   0:00  \_ crond
essence  10711  0.0  0.0   9248  1608 ?        Ss   Feb07   0:00  |   \_ /bin/bash /u03/essence/partners/google/bin/google/pcampaignid_passback/pcampaign_id.sh
essence  14695  0.0  0.0  64436 12248 ?        S    Feb07   0:00  |   |   \_ sqlplus                   @ /data/essence/partners/google/bin/google/pcampaignid_passback/woodstock.sql
oracle   14696  1.4 18.9 9760288 5638732 ?     Ss   Feb07  27:31  |   |       \_ oracleffmis (DESCRIPTION=(LOCAL=YES)(ADDRESS=(PROTOCOL=beq)))

