with t as  
(
 select chr(100) || 'abcx' || chr(120) ename from dual union all
 select chr(190) || 'abcx' || chr(180) ename from dual
)
select ename, replace(translate(ename, convert(ename,'us7ascii'), 'x'), 'x') non_ascii from t
;

with t as
(
select * from ap_selected_invoice_all
)
select * from t;