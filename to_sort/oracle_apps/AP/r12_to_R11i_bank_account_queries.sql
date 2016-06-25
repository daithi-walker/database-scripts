create table AP_BANK_ACCOUNTS_ALL_R11_MIG
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
         and      accts.last_updated_by = -1
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

select   decode(ieba.last_updated_by,-1,abaa.last_updated_by,ieba.last_updated_by) last_updated_by
,        ieba.*
from     iby_ext_bank_accounts ieba
,        ap_bank_accounts_all abaa
,        ap_bank_accounts_all_r11_mig abaarm
where    1=1
and      ieba.ext_bank_account_id = abaarm.r12_ext_bank_account_id
and      abaa.bank_account_id = abaarm.r11_bank_account_id;

select * from (
         select accts.bank_account_name,accts.bank_account_num,payee.org_id,branch.bank_branch_name
         , uses.*
        ,   count(*) over (partition by accts.bank_account_name,accts.bank_account_num,payee.org_id,branch.bank_branch_name) cnt -- order by bank_account_name,bank_account_num ,org_id,bank_branch_name)
         from     iby_pmt_instr_uses_all uses
         ,        iby_external_payees_all payee
         ,        iby_ext_bank_accounts accts
         ,        iby_ext_bank_branches_v branch
         where    1=1
         and      uses.instrument_type = 'BANKACCOUNT'
         and      uses.end_date is null
         and      payee.ext_payee_id = uses.ext_pmt_party_id
         and      uses.instrument_id = accts.ext_bank_account_id
         and      branch.branch_party_id = uses.ext_pmt_party_id
         and      branch.branch_party_id = accts.branch_id
         and      accts.last_updated_by = -1
         order by accts.bank_account_name,accts.bank_account_num,payee.org_id,branch.bank_branch_name
         )
where cnt > 1
;

/* idetntify 18 records that cannot be matched */
select   
from     (
         select   abaa.bank_account_name bank_account_name1
         ,        abaa.bank_account_num bank_account_num1
         ,        abaa.org_id org_id1
         ,        abb.bank_branch_name bank_branch_name1
         ,        abaa.currency_code
         ,        abaa.account_type
         ,        abb.bank_name
         --,        pvsa.*
         --,        abaua.*
         ,        count(*) over (partition by abaa.bank_account_name,abaa.bank_account_num,abaa.org_id,abaa.account_type,abb.bank_branch_name,abb.bank_name,abaa.currency_code) cnt
         from     ap_bank_accounts_all abaa
         ,        ap_bank_branches abb
         where    1=1
         and      abaa.bank_branch_id = abb.bank_branch_id
         and      abaa.bank_account_id not in (112159,112160,112937,112936,117653,117652,85390,85389,39178,39179,112737,112736,108948,108949,46032,46031,87320,87340)
         order by abaa.bank_account_name
         ,        abaa.bank_account_num
         ,        abaa.org_id
         ,        abb.bank_branch_name
         )
where cnt > 1
;