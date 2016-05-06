/*
Task:6440...MIS_ARCHIVE_DT_ACTIVITY
Task:6441...MIS_ARCHIVE_DT_ACTIVITY_OLIVE
Task:6442...MIS_ARCHIVE_DT_ACTIVITY_PK
Task:6443...MIS_ARCHIVE_PLUS_OPT
Task:6444...DBM_DELIVERY
Task:6445...DBM_DELIVERY_PK
Task:6446...MIS_ARCHIVE_PLUS_OPT_PK
Task:6447...ARC_HIST_PLUS_OPT_GOO
Task:6448...ADWORDS_PERFORMANCE_GOO
Task:6449...MIS_ARCHIVE_PLUS_OPT_INDEX1
Task:6450...ADWORDS_PERF_GOO_PKEY
Task:6451...ADWORDS_SQR_DELIVERY
Task:6452...ARC_HIST_PLUS_OPT_GOO_PK
Task:6453...ADWORDS_AD_GOO
Task:6454...ADWORDS_KWD_FACT_GOO
Task:6455...ARC_DT_DEVICE_ACTIVITY
Task:6456...ADWORDS_PERFORMANCE_GOO_CD
Task:6457...ADWORDS_KWD_FACT_GOO_PK
Task:6458...MIS_ARCHIVE_FACEBOOK
Task:6459...MIS_ARCHIVE_DART_GOO_2014
Task:6460...ARC_DFA_SEARCH_DELIVERY
Task:6461...DBM_DELIVERY_EVENT_DATE
Task:6462...ARC_DFA_SEARCH_KEYWORD
Task:6463...ADWORDS_CRIT_PERF_GOO
Task:6464...DBM_DELIVERY_LI
Task:6465...DBM_DELIVERY_CRE
Task:6466...MIS_ARCHIVE_DT_DELIVERY
Task:6467...ARC_DT_DEVICE_ACTIVITY_PK
Task:6468...MIS_DELIVERY_GOOGLE
Task:6469...MIS_ARCHIVE_PLUS_OPT_DART
*/

select  *
from    dba_advisor_recommendations
where   1=1
and     owner = 'OLIVE'
order by task_id;

select  replace(replace(substr(a.message,instr(a.message,' ',-1,3)),'is '),' bytes.')/1024/1024/1024 gbs
,       a.*
from    dba_advisor_findings a
where   1=1
and     owner = 'OLIVE'
and     regexp_like(a.message,'bytes.')
order by task_id;

select  *
from    dba_advisor_actions
where   1=1
and     owner = 'OLIVE'
order by task_id;

select  *
from    dba_advisor_objects
where   1=1
and     owner = 'OLIVE'
order by task_id;