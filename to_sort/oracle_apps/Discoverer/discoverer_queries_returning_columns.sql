select   user_name
,        workbook
,        worksheet
,        doc_date
--,        item_name
,        eul4_get_item(substr(item_name, 1,                           instr(item_name,',',1,1)-1)) item1
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,1)+1 , instr(item_name,',',1,2)-instr(item_name,',',1,1)-3)) item2
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,2)+1 , instr(item_name,',',1,3)-instr(item_name,',',1,2)-3)) item3
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,3)+1 , instr(item_name,',',1,4)-instr(item_name,',',1,3)-3)) item4
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,4)+1 , instr(item_name,',',1,5)-instr(item_name,',',1,4)-3)) item5
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,5)+1 , instr(item_name,',',1,6)-instr(item_name,',',1,5)-3)) item6
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,6)+1 , instr(item_name,',',1,7)-instr(item_name,',',1,6)-3)) item7
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,7)+1 , instr(item_name,',',1,8)-instr(item_name,',',1,7)-3)) item8
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,8)+1 , instr(item_name,',',1,9)-instr(item_name,',',1,8)-3)) item9
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,9)+1 , instr(item_name,',',1,10)-instr(item_name,',',1,9)-3)) item10
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,10)+1 , instr(item_name,',',1,11)-instr(item_name,',',1,10)-3)) item11
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,11)+1 , instr(item_name,',',1,12)-instr(item_name,',',1,11)-3)) item12
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,12)+1 , instr(item_name,',',1,13)-instr(item_name,',',1,12)-3)) item13
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,13)+1 , instr(item_name,',',1,14)-instr(item_name,',',1,13)-3)) item14
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,14)+1 , instr(item_name,',',1,15)-instr(item_name,',',1,14)-3)) item15
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,15)+1 , instr(item_name,',',1,16)-instr(item_name,',',1,15)-3)) item16
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,16)+1 , instr(item_name,',',1,17)-instr(item_name,',',1,16)-3)) item17
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,17)+1 , instr(item_name,',',1,18)-instr(item_name,',',1,17)-3)) item18
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,18)+1 , instr(item_name,',',1,19)-instr(item_name,',',1,18)-3)) item19
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,19)+1 , instr(item_name,',',1,20)-instr(item_name,',',1,19)-3)) item20
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,20)+1 , instr(item_name,',',1,21)-instr(item_name,',',1,20)-3)) item21
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,21)+1 , instr(item_name,',',1,22)-instr(item_name,',',1,21)-3)) item22
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,22)+1 , instr(item_name,',',1,23)-instr(item_name,',',1,22)-3)) item23
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,23)+1 , instr(item_name,',',1,24)-instr(item_name,',',1,23)-3)) item24
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,24)+1 , instr(item_name,',',1,25)-instr(item_name,',',1,24)-3)) item25
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,25)+1 , instr(item_name,',',1,26)-instr(item_name,',',1,25)-3)) item26
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,26)+1 , instr(item_name,',',1,27)-instr(item_name,',',1,26)-3)) item27
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,27)+1 , instr(item_name,',',1,28)-instr(item_name,',',1,27)-3)) item28
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,28)+1 , instr(item_name,',',1,29)-instr(item_name,',',1,28)-3)) item29
,        eul4_get_item(substr(item_name, instr(item_name,'.',1,29)+1 , instr(item_name,',',1,30)-instr(item_name,',',1,29)-3)) item30
from     (
         select   distinct
                  sts.qs_doc_owner    user_name
         ,        sts.qs_doc_name     workbook
         ,        sts.qs_doc_details  worksheet
         ,        sts.qs_created_date doc_date
         ,        max(sts.qs_created_date) over (partition by docs.doc_name) max_doc_date
         ,        eul4_get_item_name(sts.qs_id) item_name
         from     query.eul4_qpp_stats sts
         ,        query.eul4_documents docs
         where    1=1
         and      sts.qs_doc_name      = docs.doc_name
         --and      sts.qs_created_date  = to_date('13-feb-14 08:42:23','dd-mon-yy hh24:mi:ss')
         --and      docs.doc_name = 'ALL CM Unrec Bank Statement Lines'
         and      sts.qs_created_date  > '01-Jan-2013'
         )
where    1=1
and      doc_date = max_doc_date;