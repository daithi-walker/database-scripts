SELECT   column_name
,        CASE data_type
            WHEN 'VARCHAR2' THEN
               data_type || DECODE(data_length, NULL, NULL, '(' || data_length || ')')
            WHEN 'DATE' THEN
               data_type
            WHEN 'NUMBER' THEN
               data_type || DECODE(data_precision, NULL, NULL, '(' || data_precision || DECODE(data_scale, NULL, NULL, ',' || data_scale) || ')')
            ELSE
               'Not Defined'
         END col_type
,        data_type
,        data_length
,        data_precision
,        data_scale
FROM     all_tab_columns
WHERE    1=1
AND      owner = :owner
AND      table_name = :table_name
ORDER BY column_id;