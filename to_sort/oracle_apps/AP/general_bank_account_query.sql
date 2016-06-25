SELECT   gsob.name                     set_of_books_name
--,        pv.employee_id                employee_id
,        pv.vendor_name                vendor_name
,        pvsa.vendor_site_code         vendor_site
,        abb.bank_name
,        abb.bank_branch_name
,        abaa.bank_account_num         bank_account
,        abaa.bank_account_name
,        abb.bank_num                  bank_branch
,        abaa.iban_number
,        abaa.account_type
FROM     ap_bank_branches abb
,        ap_bank_accounts_all abaa
,        ap_bank_account_uses_all abaua
,        po_vendor_sites_all pvsa
,        po_vendors pv
,        gl_sets_of_books gsob
WHERE    1=1
AND      abaa.bank_branch_id (+) = abb.bank_branch_id
AND      abaa.bank_account_num IN ('11943186', '14112004')
--AND      abaa.account_type  = 'INTERNAL'
AND      abaua.external_bank_account_id (+) = abaa.bank_account_id
AND      abaua.primary_flag (+) = 'Y'
AND      pvsa.vendor_site_id (+) = abaua.vendor_site_id
--AND      UPPER(pvsa.vendor_site_code) LIKE 'OFFICE'
AND      pv.vendor_id (+) = pvsa.vendor_id
--AND      pv.vendor_name like '%ACCENTURE AG%'
AND      gsob.set_of_books_id = abaa.set_of_books_id
ORDER BY abaa.account_type
,        gsob.name
;