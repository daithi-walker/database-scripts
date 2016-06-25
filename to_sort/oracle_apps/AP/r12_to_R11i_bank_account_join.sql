create table ap_bank_accounts_all_r11_mig
as
select   a.ext_bank_account_id   R12_ext_bank_account_id
,        b.bank_account_id       R11_bank_account_id
from     (
         select   accts.*
         ,        payee.org_id
         ,        branch.bank_branch_name
         from     iby_pmt_instr_uses_all uses
         ,        iby_external_payees_all payee
         ,        iby_ext_bank_accounts accts
         ,        iby_ext_bank_branches_v branch
         where    1=1
         and      uses.instrument_type = 'BANKACCOUNT'
         and      payee.ext_payee_id = uses.ext_pmt_party_id
         and      uses.instrument_id = accts.ext_bank_account_id
         and      branch.branch_party_id = accts.branch_id
         ) a
,        (
         select   apaa.*
         ,        abb.bank_branch_name
         from     ap_bank_accounts_all apaa
         ,        ap_bank_branches abb
         where    1=1
         and      apaa.bank_branch_id = abb.bank_branch_id
         ) b
where    1=1
and      a.bank_account_name = b.bank_account_name
and      a.bank_account_num = b.bank_account_num 
and      a.org_id = b.org_id
and      a.bank_branch_name = b.bank_branch_name
;