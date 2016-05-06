explain plan for
create index dwtest on MIS_ARCHIVE_DT_ACTIVITY(MRD_DATE);

select * 
from   table(dbms_xplan.display(null, null, 'BASIC +NOTE'));