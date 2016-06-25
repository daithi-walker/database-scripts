select * from all_tables where table_name like '%EUL4%';

select   distinct
         doc.doc_name
,        obj.obj_name folder_name
,        bas.ba_name
from     query.eul4_documents doc
,        query.eul4_elem_xrefs xref
,        query.eul4_expressions exp
,        query.eul4_objs obj
,        query.eul4_ba_obj_links bol
,        query.eul4_bas bas
where    1=1
and      xref.ex_from_id = doc.doc_id
and      xref.ex_to_id = exp.exp_id 
and      obj.obj_id = exp.it_obj_id
and      bol.bol_obj_id = obj.obj_id
and      bas.ba_id = bol.bol_ba_id
and      doc.doc_name = 'ALL CM Unrec Bank Statement Lines'
;

select   eul4_bas.ba_name           -- business area
,        eul4_objs.sobj_ext_table   -- table name
,        eul4_objs.obj_ext_owner    -- object owner
from     eul4_bas
,        eul4_ba_obj_links
,        eul4_objs
where    1=1
and      eul4_bas.ba_id = eul4_ba_obj_links.bol_ba_id
and      eul4_objs.obj_id = eul4_ba_obj_links.bol_obj_id
order by 1,2;


---------------------------------------------------------------------------
--Query to find out Frequently used Custom Workbook and worksheet details--
---------------------------------------------------------------------------
select   distinct
         stats.qs_doc_owner         workbook_owner
,        workbooks.doc_name         workbookname
,        stats.qs_doc_details       worksheetname
,        folders1.obj_name          folder_name
,        exps.exp_name              column_name
,        max(stats.qs_created_date) sheet_last_run_date
from     query.eul4_documents workbooks
,        query.eul4_qpp_stats stats
,        query.eul4_objs folders1
,        query.eul4_ba_obj_links balinks
,        query.eul4_bas busunit
,        query.eul4_expressions exps
where    1=1
and      exps.it_obj_id           = folders1.obj_id
and      balinks.bol_ba_id        = busunit.ba_id
and      balinks.bol_obj_id       = folders1.obj_id
and      to_char(folders1.obj_id) = substr (stats.qs_object_use_key, 1, length(folders1.obj_id))
and      stats.qs_doc_name        = workbooks.doc_name
and      stats.qs_created_date = to_date('13-feb-14 08:42:23','dd-mon-yy hh24:mi:ss')
and      upper(workbooks.doc_name)= upper('all cm unrec bank statement lines')
/* doesn't work unless worksheet name is unique?
and      stats.qs_id in
         (
         select   distinct max(stats1.qs_id)
         from     query.eul4_qpp_stats stats1
         where    1=1
         and      stats.qs_doc_details = stats1.qs_doc_details
         )
*/
--and      stats.qs_doc_owner = 'discgbrpt'
group by stats.qs_doc_owner
,        folders1.obj_name
,        busunit.ba_name
,        workbooks.doc_name
,        stats.qs_doc_details
,        exps.exp_name
order by workbookname
;

---------------------------------------------------------
--Query to find Custom Business Area and Custom Folders--
---------------------------------------------------------
SELECT   DISTINCT
         EB.BA_NAME "CUSTOM BUSINESS AREA"
,        EO.OBJ_NAME "CUSTOM FOLDER"
FROM     QUERY.EUL4_BAS EB
,        QUERY.EUL4_OBJS EO
,        QUERY.EUL4_BA_OBJ_LINKS EBOL
,        QUERY.EUL4_EXPRESSIONS EE
WHERE    1=1
AND      EBOL.BOL_BA_ID = EB.BA_ID
AND      EBOL.BOL_OBJ_ID  = EO.OBJ_ID
AND      EE.IT_OBJ_ID     = EO.OBJ_ID
--AND      UPPER(EB.BA_NAME) LIKE 'XX%'
--AND      UPPER(EO.OBJ_NAME) LIKE 'XX%'
ORDER BY 1

----------------------------------------------------------

select   i.exp_name item_name
,        f.obj_name folder_name
,        b.ba_name
from     query.eul4_expressions i
,        query.eul4_objs f
,        query.eul4_ba_obj_links l
,        query.eul4_bas b
where    1=1
and      f.obj_id = i.it_obj_id
and      f.obj_id = l.bol_obj_id
and      b.ba_id = l.bol_ba_id
and      upper(i.exp_name) like upper('%invoice%date%') --folder item
--and      upper(b.ba_name) like upper('%') --business area
--and      upper(f.obj_name) like upper('%') --folder
order by b.ba_name
,        f.obj_name
,        i.exp_name;

