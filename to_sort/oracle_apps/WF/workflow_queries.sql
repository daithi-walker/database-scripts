/*
*****************************************
** Oracle Workflow - Important Queries **

   Notes:
   -  Most used item_types for customer X are 'POAPPRV', 'APINV', 'WFERROR'
   
   -  item_key is derived as follows:
      -  for POAPPRV : po_header_id||'-'||po_wf_itemkey_s.nexval
      -  for APINV   : invoice_id||'_1'
      -  for WFERROR : wf_error_processes_s.nextval (prefix of WF for item key comes from package WF_ENGINE_UTIL, package WF_RULE seems to be main wf package)

****************************************
*/

-- Check the status of the workflow mailer
SELECT   component_status
FROM     fnd_svc_components
WHERE    1=1
AND      component_name = 'Workflow Notification Mailer';


--SELECT all workflow items for a given item type
SELECT   wi.item_type                                    ITEM_TYPE
,        wi.item_key                                     ITEM_KEY      
,        TO_CHAR(wi.begin_date,'DD-MON-RR HH24:MI:SS')   BEGIN_DATE
,        TO_CHAR(wi.end_date,'DD-MON-RR HH24:MI:SS')     END_DATE
,        wi.root_activity                                ACTIVITY
FROM     apps.wf_items wi
WHERE    1=1
--AND      wi.item_key like '%506322%'
AND      wi.item_key = :item_key
AND      wi.item_type = :item_type
AND      wi.end_date IS NULL
ORDER BY TO_DATE(wi.begin_date,'DD-MON-YYYY HH24:MI:SS') DESC;


-- Notifications sent by a given workflow
SELECT   wias.item_type
,        wias.item_key
,        wn.notification_id
,        wn.context
,        wn.group_id
,        wn.status
,        wn.mail_status
,        wn.message_type
,        wn.message_name
,        wn.access_key
,        wn.priority
,        wn.begin_date
,        wn.end_date
,        wn.due_date
,        wn.callback
,        wn.recipient_role
,        wn.responder
,        wn.original_recipient
,        wn.from_user
,        wn.to_user
,        wn.subject
FROM     wf_notifications wn
,        wf_item_activity_statuses wias 
WHERE    1=1
AND      wn.group_id = wias.notification_id 
AND      wias.item_type = :item_type
AND      wias.item_key = :item_key
ORDER BY wn.notification_id DESC;
 

--prompt **** Find the Activity Statuses for all workflow activities of a given item type AND item key
SELECT   wias.item_type
,        wias.item_key
,        execution_time
,        TO_CHAR(wias.begin_date,'DD-MON-RR HH24:MI:SS') begin_date
,        wavp.display_name || '/' || wavc.display_name activity
,        wias.activity_status status
,        wias.activity_result_code RESULT
,        wias.assigned_user ass_user
FROM     wf_item_activity_statuses wias
,        wf_process_activities     wpa
,        wf_activities_vl          wavc
,        wf_activities_vl          wavp
,        wf_items                  wi
WHERE    1=1
AND      wias.item_type = :item_type
AND      wias.item_key = :item_key
AND      wias.process_activity = wpa.instance_id
AND      wpa.activity_name = wavc.name
AND      wpa.activity_item_type = wavc.item_type
AND      wpa.process_name = wavp.name
AND      wpa.process_item_type = wavp.item_type
AND      wpa.process_version = wavp.version
AND      wi.item_type = :item_type
AND      wi.item_key = wias.item_key
AND      wi.begin_date >= wavc.begin_date
AND      wi.begin_date < NVL(wavc.end_date,wi.begin_date + 1)
UNION ALL
SELECT   wias.item_type
,        wias.item_key
,        execution_time
,        TO_CHAR(wias.begin_date,'DD-MON-RR HH24:MI:SS') begin_date
,        wavp.display_name || '/' || wavc.display_name activity
,        wias.activity_status status
,        wias.activity_result_code RESULT
,        wias.assigned_user ass_user
FROM     wf_item_activity_statuses_h wias
,        wf_process_activities       wpa
,        wf_activities_vl            wavc
,        wf_activities_vl            wavp
,        wf_items                    wi
WHERE    1=1
AND      wias.item_type = :item_type
AND      wias.item_key = :item_key
AND      wias.process_activity = wpa.instance_id
AND      wpa.activity_name = wavc.name
AND      wpa.activity_item_type = wavc.item_type
AND      wpa.process_name = wavp.name
AND      wpa.process_item_type = wavp.item_type
AND      wpa.process_version = wavp.version
AND      wi.item_type = :item_type
AND      wi.item_key = wias.item_key
AND      wi.begin_date >= wavc.begin_date
AND      wi.begin_date < NVL(wavc.end_date,wi.begin_date + 1)
ORDER BY 4,3;


--Get a list of all Errored Workflow Activities for a given item type/ item key
SELECT   wias.item_type
,        wias.item_key
,        wavc.display_name          activity
,        wias.activity_result_code RESULT
,        wias.error_name           error_name
,        wias.error_message        error_message
,        wias.error_stack          error_stack
FROM     wf_item_activity_statuses wias
,        wf_process_activities     wpa
,        wf_activities_vl          wavc
,        wf_activities_vl          wavp
,        wf_items                  wi
WHERE    1=1
AND      wias.item_type = :item_type
AND      wias.item_key = :item_key
AND      wias.activity_status = 'ERROR'
AND      wias.process_activity = wpa.instance_id
AND      wpa.activity_name = wavc.name
AND      wpa.activity_item_type = wavc.item_type
AND      wpa.process_name = wavp.name
AND      wpa.process_item_type = wavp.item_type
AND      wpa.process_version = wavp.version
AND      wi.item_type = :item_type
AND      wi.item_key = wias.item_key
AND      wi.begin_date >= wavc.begin_date
AND      wi.begin_date < NVL(wavc.end_date,wi.begin_date + 1)
ORDER BY wias.execution_time DESC;


--prompt *** Error Process Activity Statuses
SELECT   wi.parent_item_type
,        wi.parent_item_key
,        wias.item_type
,        wias.item_key
,        execution_time
,        TO_CHAR(wias.begin_date,'DD-MON-RR HH24:MI:SS') begin_date
,        wavp.display_name || '/' || wavc.display_name activity
,        wias.activity_status status
,        wias.activity_result_code RESULT
,        wias.assigned_user ass_user
FROM     wf_item_activity_statuses wias
,        wf_process_activities     wpa
,        wf_activities_vl          wavc
,        wf_activities_vl          wavp
,        wf_items                  wi
WHERE    1=1
AND      wias.item_type = wi.item_type
AND      wias.item_key = wi.item_key
AND      wias.process_activity = wpa.instance_id
AND      wpa.activity_name = wavc.name
AND      wpa.activity_item_type = wavc.item_type
AND      wpa.process_name = wavp.name
AND      wpa.process_item_type = wavp.item_type
AND      wpa.process_version = wavp.version
AND      wi.parent_item_type = :item_type
AND      wi.parent_item_key = :item_key
AND      wi.begin_date >= wavc.begin_date
AND      wi.begin_date < NVL(wavc.end_date,wi.begin_date + 1)
UNION ALL
SELECT   wi.parent_item_type
,        wi.parent_item_key
,        wias.item_type
,        wias.item_key
,        execution_time
,        TO_CHAR(wias.begin_date,'DD-MON-RR HH24:MI:SS') begin_date
,        wavp.display_name || '/' || wavc.display_name activity
,        wias.activity_status status
,        wias.activity_result_code RESULT
,        wias.assigned_user ass_user
FROM     wf_item_activity_statuses_h wias
,        wf_process_activities       wpa
,        wf_activities_vl            wavc
,        wf_activities_vl            wavp
,        wf_items                    wi
WHERE    1=1
AND      wias.item_type = wi.item_type
AND      wias.item_key = wi.item_key
AND      wias.process_activity = wpa.instance_id
AND      wpa.activity_name = wavc.name
AND      wpa.activity_item_type = wavc.item_type
AND      wpa.process_name = wavp.name
AND      wpa.process_item_type = wavp.item_type
AND      wpa.process_version = wavp.version
AND      wi.parent_item_type = :item_type
AND      wi.parent_item_key = :item_key
AND      wi.begin_date >= wavc.begin_date
AND      wi.begin_date < NVL(wavc.end_date,wi.begin_date + 1)
ORDER BY 4
,        3;


-- Error Process Errored Activities
SELECT   wi.parent_item_type
,        wi.parent_item_key
,        wias.item_type
,        wias.item_key
,        wavc.display_name          activity
,        wias.activity_result_code RESULT
,        wias.error_name           error_name
,        wias.error_message        error_message
,        wias.error_stack          error_stack
FROM     wf_item_activity_statuses wias
,        wf_process_activities     wpa
,        wf_activities_vl          wavc
,        wf_activities_vl          wavp
,        wf_items                  wi
WHERE    wias.item_type = wi.item_type
AND      wias.item_key = wi.item_key
AND      wias.activity_status = 'ERROR'
AND      wias.process_activity = wpa.instance_id
AND      wpa.activity_name = wavc.name
AND      wpa.activity_item_type = wavc.item_type
AND      wpa.process_name = wavp.name
AND      wpa.process_item_type = wavp.item_type
AND      wpa.process_version = wavp.version
AND      wi.parent_item_type = :item_type
AND      wi.parent_item_key = :item_key
AND      wi.begin_date >= wavc.begin_date
AND      wi.begin_date < NVL(wavc.end_date,wi.begin_date + 1)
ORDER BY wias.execution_time DESC;


-- Attribute Values
SELECT   wiav.item_type
,        wiav.item_key
,        wiav.name   ATTR_NAME
,        NVL(wiav.text_value,NVL(TO_CHAR(wiav.number_value),TO_CHAR(wiav.date_value))) VALUE
FROM     wf_item_attribute_values wiav
WHERE    1=1
AND      wiav.item_type = upper(:item_type)
AND      wiav.item_key = NVL(:item_key,item_key)
--AND      wiav.name like '%SEGMENT%'
ORDER BY wiav.name;


-- Count of all workflow deferred activities based
SELECT   COUNT(*)
,        was.item_type
FROM     apps.wf_items                  wi
,        apps.wf_item_activity_statuses was
,        apps.wf_process_activities     wpa
WHERE    wi.item_type = was.item_type
AND      wi.item_key = was.item_key
AND      wi.end_date IS NULL
AND      was.end_date IS NULL
AND      was.activity_status = 'DEFERRED'
--AND      was.item_type = 'REQAPPRV'
AND      was.item_type = wi.item_type
AND      wpa.instance_id(+) = was.process_activity
GROUP BY was.item_type;


-- Count of activities per item_type
SELECT   was.item_type
,        was.activity_status
,        COUNT(*) CNT
FROM     apps.wf_items                  wi
,        apps.wf_item_activity_statuses was
,        apps.wf_process_activities     wpa
WHERE    1=1
AND      was.item_type = :item_type
AND      wi.item_type = was.item_type
AND      wi.item_key = was.item_key
AND      wi.end_date IS NULL
AND      was.end_date IS NULL
AND      was.item_type = wi.item_type
AND      wpa.instance_id(+) = was.process_activity
GROUP BY was.item_type
,        was.activity_status
ORDER BY was.item_type
,        was.activity_status;

------------------------------------------------------------------------------------------
--How to Monitor the FNDWFBG-Workflow Background Program? (Doc ID 369537.1)
------------------------------------------------------------------------------------------

select * --corrid, user_data user_data 
from wf_deferred_table_m 
where state = 0 
and corrid = '&Corrid'  --APPSREQAPPRV
order by priority, enq_time; 


select w.user_data.itemtype "Item Type", w.user_data.itemkey "Item Key", 
decode(w.state, 0, '0 = Ready',
1, '1 = Delayed', 
2, '2 = Retained', 
3, '3 = Exception', 
to_char(w.state)) State, 
w.priority, w.ENQ_TIME, w.DEQ_TIME, w.msgid 
from wf_deferred_table_m w 
where 1=1
and w.user_data.itemtype = '&item_type' --REQAPPRV
;
