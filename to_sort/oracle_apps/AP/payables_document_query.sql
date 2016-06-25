select   distinct 
         aca.org_id
,        haou.name org_name
--,        abb.bank_branch_id
,        abb.bank_name
,        abb.bank_branch_name
--,        aca.bank_account_id
,        abaa.bank_account_num
--,        aca.check_stock_id
,        acsa.name document_name
--,        aca.checkrun_name payment_batch
--,        aca.check_number
from     ap_checks_all aca
,        ap_check_stocks_all acsa
,        hr_all_organization_units haou
,        ap_bank_accounts_all abaa
,        ap_bank_branches abb
where    1=1
and      abb.bank_branch_id = abaa.bank_branch_id
and      abaa.bank_account_id = aca.bank_account_id
and      aca.org_id = haou.organization_id
and      acsa.check_stock_id = aca.check_stock_id
and      acsa.name like '%SEPA'
--and      aca.checkrun_name = 'xxx'
order by aca.org_id
,        abaa.bank_account_num
,        acsa.name
;
