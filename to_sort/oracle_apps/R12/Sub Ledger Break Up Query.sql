Sub Ledger Break Up Query - Oracle Apps R-12 

select   gjh.description jv_header_description
,        gjh.name jv_name
,        gjh.je_category
,        gjh.je_source
,        gjh.period_name
,        nvl(xal.accounted_cr,0) gl_cr
,        nvl(xal.accounted_dr,0) gl_dr
,        gjl.description jv_line_description
,        xah.event_type_code
,        xah.description sla_description
,        xal.ae_line_num
,        xal.accounting_date gl_date
,        asup.vendor_name
,        to_char(aca.check_number)
,        aca.check_date
,        aca.doc_sequence_value voucher_number
,        aca.creation_date voucher_date
,        decode(xal.accounted_cr,null,xal.accounted_dr,0) receipt
,        decode(xal.accounted_dr,null,xal.accounted_cr,0) payment
from     xla_ae_headers xah
,        xla_ae_lines xal
,        gl_je_lines gjl
,        gl_import_references gir
,        gl_je_headers gjh
,        gl_code_combinations gcc
,        ap_suppliers asup
,        ap_checks_all aca
where    1 = 1
and      xah.ae_header_id = xal.ae_header_id
and      gjl.je_line_num = gir.je_line_num
and      gjl.je_header_id = gir.je_header_id
and      gir.gl_sl_link_table = xal.gl_sl_link_table
and      gir.gl_sl_link_id = xal.gl_sl_link_id
and      gjl.je_header_id = gjh.je_header_id
and      gjl.code_combination_id = gcc.code_combination_id
and      asup.vendor_id(+) = xal.party_id
and      aca.doc_sequence_id(+) = xah.doc_sequence_id
and      aca.doc_sequence_value(+) = xah.doc_sequence_value
and      gcc.segment5 = nvl(:p_acc_num,gcc.segment5)
and      trunc(gjh.default_effective_date) between nvl(:p_from_date,trunc(gjh.default_effective_date)) and nvl(:p_to_date,trunc(gjh.default_effective_date))
and      gjh.status = 'P'
and      gjh.je_source = 'Payables'
union all
------ DATA FROM CASH MANAGEMENT -------------------------------- 
select   gjh.description jv_header_description
,        gjh.name jv_name
,        gjh.je_category
,        gjh.je_source
,        gjh.period_name
,        nvl(xal.accounted_cr,0) gl_cr
,        nvl(xal.accounted_dr,0) gl_dr
,        gjl.description jv_line_description
,        xah.event_type_code
,        xah.description sla_description
,        xal.ae_line_num
,        xal.accounting_date gl_date
,        '' vendor_name
,        '' check_number
,        null check_date
,        null voucher_number
,        null voucher_date
,        decode(xal.accounted_cr,null,xal.accounted_dr,0)  receipt
,        decode(xal.accounted_dr,null,xal.accounted_cr,0) payment
from     xla_ae_headers xah
,        xla_ae_lines xal
,        gl_je_lines gjl
,        gl_import_references gir
,        gl_je_headers gjh
,        gl_code_combinations gcc
where    1=1
and      xah.ae_header_id = xal.ae_header_id
and      gjl.je_line_num = gir.je_line_num
and      gjl.je_header_id = gir.je_header_id
and      gir.gl_sl_link_table = xal.gl_sl_link_table
and      gir.gl_sl_link_id = xal.gl_sl_link_id
and      gjl.je_header_id = gjh.je_header_id
and      gjl.code_combination_id = gcc.code_combination_id
and      gcc.segment5 = nvl(:p_acc_num,gcc.segment5)
and      trunc(gjh.default_effective_date) between nvl(:p_from_date,trunc(gjh.default_effective_date)) and nvl(:p_to_date,trunc(gjh.default_effective_date))
and      gjh.status = 'P'
and      gjh.je_source = 'Cash Management'
and      gjh.je_category = 'Bank Transfers'
union all
-------------------Data from Receivable --------------------------------
select   gjh.description jv_header_description
,        gjh.name jv_name
,        gjh.je_category
,        gjh.je_source
,        gjh.period_name
,        nvl(xal.accounted_cr,0) gl_cr
,        nvl(xal.accounted_dr,0) gl_dr
,        gjl.description jv_line_description
,        xah.event_type_code
,        xah.description sla_description
,        xal.ae_line_num
,        xal.accounting_date gl_date
,        (
         select   ac.customer_name
         from     ar_customers ac
         where    ac.customer_id = xal.party_id
         ) customer_name
,        (
         select   acr.receipt_number
         from     ar_cash_receipts_all acr
         where    acr.doc_sequence_id = xah.doc_sequence_id
         and      acr.doc_sequence_value = xah.doc_sequence_value
         ) receipt_number
,        (
         select   acr.receipt_date
         from     ar_cash_receipts_all acr
         where    acr.doc_sequence_id = xah.doc_sequence_id
         and      acr.doc_sequence_value = xah.doc_sequence_value
         ) receipt_date
,        (
         select   acr.doc_sequence_value
         from     ar_cash_receipts_all acr
         where    acr.doc_sequence_id = xah.doc_sequence_id
         and      acr.doc_sequence_value = xah.doc_sequence_value
         ) voucher_number
,        (
         select   acr.creation_date
         from     ar_cash_receipts_all acr
         where    acr.doc_sequence_id = xah.doc_sequence_id
         and      acr.doc_sequence_value = xah.doc_sequence_value
         )  voucher_date
,        decode(xal.accounted_cr,null,xal.accounted_dr,0)  receipt
,        decode(xal.accounted_dr,null,xal.accounted_cr,0) payment
from     gl_je_batches gjb
,        gl_je_headers gjh
,        gl_je_lines gjl
,        gl_code_combinations gcc
,        gl_import_references gir
,        xla_ae_lines xal
,        xla_ae_headers xah
,        xla.xla_transaction_entities xte
where    1=1
and      gjb.je_batch_id = gjh.je_batch_id
and      gjh.je_header_id = gjl.je_header_id
and      gjl.code_combination_id = gcc.code_combination_id
and      gjl.je_header_id = gir.je_header_id
and      gjl.je_line_num = gir.je_line_num
and      gir.gl_sl_link_id = xal.gl_sl_link_id
and      gir.gl_sl_link_table = xal.gl_sl_link_table
and      xal.ae_header_id = xah.ae_header_id
and      xte.application_id = xah.application_id
and      xte.entity_id = xah.entity_id
and      gjl.status = 'p'
and      gcc.segment5 = nvl (:p_acc_num, gcc.segment5)
and      trunc(gjh.default_effective_date) between  nvl (:p_from_date, trunc (gjh.default_effective_date)) and nvl (:p_to_date, trunc (gjh.default_effective_date))
and      gjh.je_source = 'Receivables'
union all
---------------- Manual -----------------------
select   gjh.description jv_header_description
,        gjh.name jv_name
,        gjh.je_category
,        gjh.je_source
,        gjh.period_name
,        nvl(gjl.accounted_dr,0) accounted_dr
,        nvl(gjl.accounted_cr,0) accounted_cr
,        gjl.description jv_line_description
,        '' event_type_code
,        '' sla_description
,        null ae_line_num
,        gjh.default_effective_date gl_date
,        '' vendor_name
,        '' check_number
,        null check_date
,        null voucher_number
,        null voucher_date
,        nvl(gjl.accounted_dr,0) receipt
,        nvl(gjl.accounted_cr,0) payment
from     gl_je_batches gjb
,        gl_je_headers gjh
,        gl_je_lines gjl
,        gl_code_combinations gcc
where    1=1
and      gjb.je_batch_id = gjh.je_batch_id
and      gjh.je_header_id = gjl.je_header_id
and      gjl.code_combination_id = gcc.code_combination_id
and      gjl.status = 'P'
and      gcc.segment5 = nvl (:p_acc_num, gcc.segment5)
and      trunc (gjh.default_effective_date) between nvl (:p_from_date, trunc (gjh.default_effective_date))
and      nvl (:p_to_date, trunc (gjh.default_effective_date))
and      gjh.je_source = 'Manual'
union all
-----ALL OTHER SOURCES OTHER THAN ABOVE----------
select   gjh.description jv_header_description
,        gjh.name jv_name
,        gjh.je_category
,        gjh.je_source
,        gjh.period_name
,        nvl(xal.accounted_cr,0) gl_cr
,        nvl(xal.accounted_dr,0) gl_dr
,        gjl.description jv_line_description
,        xah.event_type_code
,        xah.description sla_description
,        xal.ae_line_num
,        xal.accounting_date gl_date
,        '' vendor_name
,        '' check_number
,        null check_date
,        null voucher_number
,        null voucher_date
,        decode(xal.accounted_cr,null,xal.accounted_dr,0)  receipt
,        decode(xal.accounted_dr,null,xal.accounted_cr,0) payment
from     xla_ae_headers xah
,        xla_ae_lines xal
,        gl_je_lines gjl
,        gl_import_references gir
,        gl_je_headers gjh
,        gl_code_combinations gcc
where    1=1
and      xah.ae_header_id = xal.ae_header_id
and      gjl.je_line_num = gir.je_line_num
and      gjl.je_header_id = gir.je_header_id
and      gir.gl_sl_link_table = xal.gl_sl_link_table
and      gir.gl_sl_link_id = xal.gl_sl_link_id
and      gjl.je_header_id = gjh.je_header_id
and      gjl.code_combination_id = gcc.code_combination_id
and      gcc.segment5 = nvl(:p_acc_num,gcc.segment5)
and      trunc(gjh.default_effective_date) between nvl(:p_from_date,trunc(gjh.default_effective_date)) and nvl(:p_to_date,trunc(gjh.default_effective_date))
and      gjh.status = 'P'
and      gjh.je_source not in ('Receivables','Payables','Cash Management')