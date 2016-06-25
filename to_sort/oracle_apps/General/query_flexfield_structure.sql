select   fif.application_id
,        fif.id_flex_code
,        fif.id_flex_name
,        fif.application_table_name
,        fif.description
,        fifs.id_flex_num
,        fifs.id_flex_structure_code
,        fifse.segment_name
,        fifse.segment_num
,        fifse.flex_value_set_id
from     fnd_id_flexs fif
,        fnd_id_flex_structures fifs
,        fnd_id_flex_segments fifse
where    1=1
and      fif.application_id = fifs.application_id
and      fif.id_flex_code = fifs.id_flex_code
and      fifse.application_id = fif.application_id
and      fifse.id_flex_code = fif.id_flex_code
and      fifse.id_flex_num = fifs.id_flex_num
and      fif.id_flex_code like 'GL#'
and      fif.id_flex_name like 'Accounting Flexfield';
