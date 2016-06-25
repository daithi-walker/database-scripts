whenever sqlerror exit FAILURE
set echo off 
set newpage 0 
set space 0 
set pagesize 0 
set feedback off
set termout off
set trimspool on
set linesize 512
set verify off
set arraysize 150

def OUTPUT=&1
def sdate=&2
def edate=&3
def ledger=&4

spool &OUTPUT

select 'ACCOUNTED_CR|ACCOUNTED_DR|CODE_COMBINATION_ID|CREATED_BY|CREATION_DATE|DESCRIPTION|EFFECTIVE_DATE|ENTERED_CR|ENTERED_DR|GL_SL_LINK_ID|GL_SL_LINK_TABLE|INVOICE_AMOUNT|INVOICE_DATE|INVOICE_IDENTIFIER|JE_HEADER_ID|JE_LINE_NUM|LAST_UPDATE_DATE|LAST_UPDATED_BY|PERIOD_NAME|LEDGER_ID|STAT_AMOUNT|TAX_CODE|TAX_CODE_ID|TAX_GROUP_ID|TAX_TYPE_CODE|STATUS'
from dual;
  
select 
L.ACCOUNTED_CR ||'|'||
L.ACCOUNTED_DR ||'|'||
L.CODE_COMBINATION_ID ||'|'||
L.CREATED_BY ||'|'||
L.CREATION_DATE ||'|'||
REPLACE(REPLACE(L.DESCRIPTION,'|'),chr(10)) ||'|'||
L.EFFECTIVE_DATE ||'|'||
L.ENTERED_CR ||'|'||
L.ENTERED_DR ||'|'||
L.GL_SL_LINK_ID ||'|'||
L.GL_SL_LINK_TABLE ||'|'||
L.INVOICE_AMOUNT ||'|'||
L.INVOICE_DATE ||'|'||
L.INVOICE_IDENTIFIER ||'|'||
L.JE_HEADER_ID ||'|'||
L.JE_LINE_NUM ||'|'||
L.LAST_UPDATE_DATE ||'|'||
L.LAST_UPDATED_BY ||'|'||
L.PERIOD_NAME ||'|'||
L.SET_OF_BOOKS_ID ||'|'||
L.STAT_AMOUNT ||'|'||
L.TAX_CODE ||'|'||
L.TAX_CODE_ID ||'|'||
L.TAX_GROUP_ID ||'|'||
L.TAX_TYPE_CODE ||'|'||
L.STATUS
FROM GL.GL_JE_HEADERS H
  inner join GL.GL_JE_LINES L on H.JE_HEADER_ID = L.JE_HEADER_ID
  left join GL.GL_SETS_OF_BOOKS LD on h.SET_OF_BOOKS_ID = LD.SET_OF_BOOKS_ID
  left join GL.GL_PERIODS P on P.PERIOD_SET_NAME = LD.PERIOD_SET_NAME and P.PERIOD_NAME = H.PERIOD_NAME 
  where ( P.START_DATE between to_date(&sdate,'YYYYMMDD') and to_date(nvl(&edate,to_char(SYSDATE,'YYYYMMDD')),'YYYYMMDD') 
  or P.END_DATE between to_date(&sdate,'YYYYMMDD') and to_date(nvl(&edate,to_char(SYSDATE,'YYYYMMDD')),'YYYYMMDD') )
  and ((H.SET_OF_BOOKS_ID = &ledger) or &ledger =-1)
  ;

 
spool off

exit
