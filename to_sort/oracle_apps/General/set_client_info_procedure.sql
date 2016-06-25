declare

   v_release   varchar2(2);
   v_org_id    number := NULL;
   v_org_name  varchar(1000) := 'PCIL UK A%M';

begin

   select   substr(release_name,1,2)
   into     v_release
   from     apps.fnd_product_groups;

   if (v_org_id is null and v_org_name is not null) then
      select    organization_id
      into      v_org_id
      from      hr_all_organization_units
      where     1=1
      and       name like v_org_name;
   end;   

   case v_release
      when '12' then
         mo_global.set_policy_context('S',v_org_id);
         --select mo_global.get_current_org_id from dual;
      else
         fnd_client_info.set_org_context(v_org_id);
         --dbms_application_info.set_client_info(v_org_id);
   end case;

end;