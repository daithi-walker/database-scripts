SELECT   gsob.name                     set_of_books_name
,        pv.employee_id                employee_id
,        pv.vendor_id                  vendor_id
,        pv.vendor_name                vendor_name
,        pvsa.vendor_site_id           vendor_site_id
,        pvsa.vendor_site_code         vendor_site
,        abaua.bank_account_uses_id    bank_acc_uses_id
,        abaa.bank_account_num         bank_account
,        abaa.bank_account_id          bank_account_id
,        abb.bank_num                  bank_branch
,        abb.bank_branch_id            bank_branch_id
,        abaa.iban_number
FROM     po_vendors pv
,        po_vendor_sites_all pvsa
,        ap_bank_account_uses_all abaua
,        ap_bank_accounts_all abaa
,        ap_bank_branches abb
,        gl_sets_of_books gsob
WHERE    1=1
and      gsob.set_of_books_id = abaa.set_of_books_id
--AND      v.employee_id
AND      pv.vendor_id = pvsa.vendor_id
--AND      pv.vendor_name like '%ACCENTURE AG%'
--AND      UPPER(pvsa.vendor_site_code) LIKE 'OFFICE'
AND      pvsa.vendor_site_id = abaua.vendor_site_id (+)
AND      abaua.external_bank_account_id = abaa.bank_account_id (+)
AND      abaa.bank_branch_id = abb.bank_branch_id (+)
and      abaa.bank_account_num = '93638357'
--AND      'Y' = abaua.primary_flag (+)
;