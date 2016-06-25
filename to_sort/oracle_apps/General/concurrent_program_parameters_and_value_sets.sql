--SELECT USERENV('LANG') FROM DUAL;
ALTER SESSION SET NLS_LANGUAGE='AMERICAN';

select   a.*
,        b.flex_value_set_name
from     apps.fnd_descr_flex_col_usage_vl a
join     apps.fnd_flex_value_sets b
on       a.flex_value_set_id = b.flex_value_set_id
where    1=1
and      a.descriptive_flexfield_name = '$SRS$.PEPPOPARINT'
order by a.column_seq_num;