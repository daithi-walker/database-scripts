-- Query to get the supplier, invoice and payment details of a supplier
SELECT   aia.invoice_id, pov.vendor_name, pov.segment1 "Vendor Num", pov.vendor_type_lookup_code, aia.payment_currency_code,
         aia.invoice_date, aia.invoice_num, aia.invoice_amount, aia.amount_paid, aia.description, apsa.payment_method_lookup_code,
         apsa.due_date, apsa.gross_amount, apsa.payment_status_flag "Paid Y/N", apsa.amount_remaining, apb.bank_name, apb.bank_branch_name,
         apba.bank_account_num, aca.check_date, aca.check_number, aca.status_lookup_code
    FROM ap_payment_schedules_all apsa,
         ap_invoices_all aia,
         ap_bank_branches apb,
         ap_bank_accounts_all apba,
         po_vendors pov,
         ap_checks_all aca,
         ap_invoice_payments_all aipa
   WHERE aia.invoice_id = apsa.invoice_id(+)
     AND aia.vendor_id = pov.vendor_id
AND pov.vendor_name LIKE 'SIER%'
     AND apsa.external_bank_account_id = apba.bank_account_id
     AND apba.bank_branch_id = apb.bank_branch_id
     AND aipa.invoice_id = aia.invoice_id
     AND aca.check_id = aipa.check_id
ORDER BY aia.invoice_date DESC