select   *
from     fnd_new_messages 
where    1=1
and      application_id = 101
and      language_code = 'US'
and      message_name like 'R_LEZL%'
and      message_text like '%EF04%'
order by message_name;

select   * 
from     fnd_lookups
where    1=1
and      lookup_type = 'PSP_SUSP_AC_ERRORS'
--and      lookup_code = 'EF04'
order by lookup_code;