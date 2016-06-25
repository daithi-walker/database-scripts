SELECT   wf_item_key
,        wf_item_type
,        authorization_status
,        org_id
,        last_update_date
,        segment1 po_no
FROM     po_headers_all
WHERE    1=1
AND      authorization_status = 'IN PROCESS'
AND      org_id = 1106
AND      segment1 in ('5623760','5623761')
ORDER BY last_update_date DESC;

SELECT   wf_item_type
,        wf_item_key
,        authorization_status
,        org_id
,        last_update_date
,        segment1 poreq_no
FROM     po_requisition_headers_all
WHERE    1=1
AND      authorization_status = 'IN PROCESS'
AND      org_id = 1106
AND      segment1 in ('5623760','5623761')
ORDER BY last_update_date DESC;

-- For PO
BEGIN
   --wf_engine.startprocess( 'WF_ITEM_TYPE' , 'WF_ITEM_KEY');
   wf_engine.startprocess('POAPPRV', '826648-924975');
   wf_engine.startprocess('POAPPRV', '826669-924995');
END;

-- For PO REQ
BEGIN
   --wf_engine.startprocess('WF_ITEM_TYPE','WF_ITEM_KEY');
   wf_engine.startprocess('REQAPPRV', '<WF_ITEM_KEY>' );
END;