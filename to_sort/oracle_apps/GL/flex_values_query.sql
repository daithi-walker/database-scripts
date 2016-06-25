select   case
            when  to_char(d.creation_date,'yyyy')= '2013' then
               'Y'
            else
               'N'
         end created_2013 
,        a.id_flex_structure_code
,        b.id_flex_code
,        e.language
,        d.flex_value
,        e.description
,        e.flex_value_meaning
,        b.flex_value_set_id
,        b.application_column_name
,        b.segment_name
,        c.flex_value_set_name
,        d.flex_value_id                 
from     apps.fnd_id_flex_structures a
,        apps.fnd_id_flex_segments b
,        apps.fnd_flex_value_sets c
,        apps.fnd_flex_values d
,        apps.fnd_flex_values_tl e
where    1=1
and      a.id_flex_num=b.id_flex_num
and      a.id_flex_code='GL#'
and      b.id_flex_code='GL#'
and      b.flex_value_set_id=c.flex_value_set_id
and      c.flex_value_set_id=d.flex_value_set_id
and      d.flex_value_id=e.flex_value_id
and      a.application_id in (101,201)
and      e.language='US'
and      b.application_column_name = 'SEGMENT3'
order by a.id_flex_structure_code
,        d.flex_value;