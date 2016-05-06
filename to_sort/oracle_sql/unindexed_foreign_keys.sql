http://tkyte.blogspot.co.uk/2009/10/httpasktomoraclecomtkyteunindex.html
http://tkyte.blogspot.co.uk/2009/10/httpasktomoraclecomtkyteunindex.html

select  uc.owner
,       uc.constraint_name cons_name
,       uc.table_name  tab_name
,       ucc.column_name cons_column
,       nvl(uic.column_name,'***No Index***') ind_column
from    dba_constraints  uc
,       dba_cons_columns ucc
,       dba_ind_columns  uic
where   1=1
and     uc.constraint_name = ucc.constraint_name
and     ucc.column_name = uic.column_name (+)
and     ucc.table_name  = uic.table_name (+)
and     uc.constraint_type = 'R'
and     uic.column_name is null
and     uc.owner in ('OLIVE','SANFRAN')
order by uc.constraint_name
,        uc.table_name;


select table_name, constraint_name,
        cname1 || nvl2(cname2,','||cname2,null) ||
        nvl2(cname3,','||cname3,null) || nvl2(cname4,','||cname4,null) ||
        nvl2(cname5,','||cname5,null) || nvl2(cname6,','||cname6,null) ||
        nvl2(cname7,','||cname7,null) || nvl2(cname8,','||cname8,null)
               columns
     from ( select b.table_name,
                   b.constraint_name,
                   max(decode( position, 1, column_name, null )) cname1,
                   max(decode( position, 2, column_name, null )) cname2,
                   max(decode( position, 3, column_name, null )) cname3,
                   max(decode( position, 4, column_name, null )) cname4,
                   max(decode( position, 5, column_name, null )) cname5,
                   max(decode( position, 6, column_name, null )) cname6,
                   max(decode( position, 7, column_name, null )) cname7,
                   max(decode( position, 8, column_name, null )) cname8,
                   count(*) col_cnt
             from (select substr(table_name,1,30) table_name,
                           substr(constraint_name,1,30) constraint_name,
                          substr(column_name,1,30) column_name,
                           position
                      from user_cons_columns ) a,
                   user_constraints b
             where a.constraint_name = b.constraint_name
               and b.constraint_type = 'R'
             group by b.table_name, b.constraint_name
          ) cons
    where col_cnt > ALL
            ( select count(*)
                from user_ind_columns i
               where i.table_name = cons.table_name
                 and i.column_name in (cname1, cname2, cname3, cname4,
                                       cname5, cname6, cname7, cname8 )
                 and i.column_position <= cons.col_cnt
               group by i.index_name
            );


explain plan for create index ADWORDS_AD_GOO_FK_AT on ADWORDS_AD_GOO(AD_TYPE_ID);
explain plan for create index ADWORDS_AD_GROUP_GOO_FK_STATUS on ADWORDS_AD_GROUP_GOO(STATUS_ID);

alter table ADWORDS_AD_GROUP_GOO rename constraint SYS_C00742910 to ADWORDS_AD_GROUP_STATUS_FK;

alter index ARC_YANDEX_METRICS_GOO_IDX_AD rename to OLD_YANDEX_METRICS_GOO_IDX_AD;
drop index OLD_YANDEX_METRICS_GOO_IDX_AD;
explain plan for create index ARC_YANDEX_METRICS_GOO_FK_AD on ARC_YANDEX_METRICS_GOO(AD_ID) tablespace olive_index;
select * from table(dbms_xplan.display(null, null, 'BASIC +NOTE'));

