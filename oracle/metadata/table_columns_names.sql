select  c.column_name
,       UPPER (c.data_type) || case when (   c.data_type='VARCHAR'
                 OR c.data_type = 'VARCHAR2'
                 --rip this out rather than improving table to support (126 bytes) OR c.data_type ='RAW'
                 OR c.data_type='CHAR') AND (
                                 c.data_length <> 0 AND
                 nvl(c.data_length,-1) <> -1)        then
                 case when(c.char_used ='C' and 'BYTE' =(select value from nls_session_parameters where PARAMETER='NLS_LENGTH_SEMANTICS')) then '(' || c.char_length || ' CHAR)'
                                      when(c.char_used ='B' and 'CHAR' =(select value from nls_session_parameters where PARAMETER='NLS_LENGTH_SEMANTICS')) then '(' || c.data_length || ' BYTE)'
                                      when(c.char_used ='C' and 'CHAR' =(select value from nls_session_parameters where PARAMETER='NLS_LENGTH_SEMANTICS')) then '(' || c.char_length || ')'
                                      when(c.char_used ='B' and 'BYTE' =(select value from nls_session_parameters where PARAMETER='NLS_LENGTH_SEMANTICS')) then '(' || c.data_length || ')'
                                      else '(' || c.data_length || ' BYTE)'
                 end  
                       when (c.data_type='RAW') then ''
           when (c.data_type='NVARCHAR2' OR c.data_type='NCHAR') then 
           '(' || c.data_length/2 || ')'  
           when (c.data_type like 'TIMESTAMP%' OR c.data_type like 'INTERVAL DAY%' OR c.data_type like 'INTERVAL YEAR%' OR c.data_type = 'DATE' OR
                            (c.data_type = 'NUMBER' AND ((c.data_precision = 0) OR NVL (c.data_precision,-1) = -1) AND  nvl (c.data_scale,-1) = -1)) then
                            ''
           when ((c.data_type = 'NUMBER' AND NVL (c.data_precision,-1) = -1) AND (c.data_scale = 0)) then
                            '(38)' 
                           when ((c.data_type = 'NUMBER' AND NVL (c.data_precision,-1) = -1) AND (nvl (c.data_scale,-1) != -1)) then
                            '(38,'|| c.data_scale ||')'
           when (c.data_scale  = 0 OR nvl(c.data_scale,-1) = -1) then
                            '('|| c.data_precision ||')'
                           else
                              '('|| c.data_precision ||',' ||c.data_scale ||')'   
        end data_type
,       decode(nullable,'Y','Yes','No') nullable
,       c.DATA_DEFAULT
,       column_id
,       com.comments
,       c_update.insertable
,       c_update.updatable
,       c_update.deletable  
from    sys.dba_tab_columns c, 
        sys.dba_col_comments com,
        sys.dba_updatable_columns c_update
where   c.owner      = :OBJECT_OWNER  
and     c.table_name =  :OBJECT_NAME   
and     c.table_name = com.table_name
and     c.owner = com.owner
and     c.column_name = com.column_name
and     c_update.column_name = com.column_name
AND     c_update.table_name = com.table_name
and     c_update.owner = com.owner