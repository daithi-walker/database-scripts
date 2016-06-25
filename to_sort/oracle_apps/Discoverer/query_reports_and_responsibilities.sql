SELECT   ed.doc_name disco_report
,        frt.responsibility_name
FROM     eul4_us.eul4_documents ed
,        eul4_us.eul4_access_privs eap
,        eul4_us.eul4_eul_users eeu
,        fnd_responsibility fr
,        fnd_responsibility_tl frt
WHERE    1=1
AND      ed.doc_id = eap.gd_doc_id 
AND      eap.ap_type = 'GD' 
AND      eap.ap_eu_id = eeu.eu_id 
AND      REPLACE (eeu.eu_username,'#','') = TO_CHAR(fr.responsibility_id) || TO_CHAR(fr.application_id)
AND      fr.responsibility_id = frt.responsibility_id
--AND      frt.responsibility_name like '%PCL%'
;