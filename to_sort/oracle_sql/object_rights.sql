SELECT   obj.object_name
,        obj.object_type
,        obj.owner obj_owner
,        privs.*
FROM     dba_tab_privs privs
,        dba_objects obj
WHERE    1=1
--AND      obj.owner = 'XXCUS'
AND      obj.object_name = 'XXCUS_SEPA_BANK_UPDATE_PKG'
AND      privs.owner(+) = obj.owner
AND      privs.table_name(+) = obj.object_name;