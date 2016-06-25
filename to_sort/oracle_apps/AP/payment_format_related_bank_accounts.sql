SELECT   gsob.name                     set_of_books_name
,        acf.name                     payment_format_name
,        acsa.name                    document_name
--,        acsa.disbursement_type_lookup_code
--,        acsa.last_document_num
--,        acsa.last_available_document_num
--,        pv.employee_id                employee_id
,        abb.bank_name
,        abb.bank_branch_name
,        abaa.bank_account_num         bank_account
,        abaa.bank_account_name
,        abb.bank_branch_type
,        abb.bank_num
,        abaa.iban_number
,        abaa.account_type
FROM     ap.ap_bank_branches abb
,        ap.ap_bank_accounts_all abaa
,        ap.ap_bank_account_uses_all abaua
,        gl.gl_sets_of_books gsob
,        ap.ap_check_formats acf
,        ap.ap_check_stocks_all acsa
WHERE    1=1
AND      acsa.bank_account_id = abaa.bank_account_id
AND      acf.check_format_id = acsa.check_format_id
--AND      acf.name like'%SEPA%'
AND      acsa.name like 'Elec%'
AND      abaa.bank_branch_id (+) = abb.bank_branch_id
AND      abaa.bank_account_num = '10349522'
AND      abaua.external_bank_account_id (+) = abaa.bank_account_id
AND      abaua.primary_flag (+) = 'Y'
AND      gsob.set_of_books_id = abaa.set_of_books_id
ORDER BY gsob.name
,        acf.name
,        acsa.name
;