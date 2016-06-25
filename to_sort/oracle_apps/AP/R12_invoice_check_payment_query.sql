select   aia.invoice_num
,        aia.invoice_id
,        apsa.ext_bank_account_id pay_sched_bank_ac_id
,        aca.check_id
,        aca.check_number
,        aca.payment_id
,        ipa.external_bank_account_id
from     ap_invoices_all@apps_ebus aia
,        ap_payment_schedules_all@apps_ebus apsa
,        ap_invoice_payments_all@apps_ebus aipa
,        ap_checks_all@apps_ebus aca
,        iby_payments_all@apps_ebus ipa
where    1=1
and      apsa.invoice_id = aia.invoice_id
and      aipa.invoice_id = aia.invoice_id
and      aca.check_id = aipa.check_id
and      ipa.payment_id = aca.payment_id
and      ipa.payment_process_request_name = 'LIPTONUSDWIRE05.05.26'
and      aia.invoice_num in
         ('H 015055.'
         ,'H 015054.'
         )
;