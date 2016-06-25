create or replace function trigger_text_like
(  p_schema in varchar2
,  p_trigger_name in varchar2
,  p_search in varchar2
)
return number
as
   l_text long;
begin
   select   trigger_body
   into     l_text
   from     all_triggers
   where    1=1
   and      owner = p_schema
   and      trigger_name = p_trigger_name;

   if ( lower(l_text) like lower(p_search) ) then
      return 1;
   else
      return 0;
   end if;
exception
   when no_data_found then
      return null;
end;
/
  
select   owner, trigger_name
from     all_triggers
where    1=1
and      owner in ('APPS')
and      trigger_name like '%xxx%'
and      trigger_text_like(owner, trigger_name, '%Search Pattern%' ) = 1
/