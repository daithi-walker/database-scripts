select   i.invoice_id
,        i.invoice_num
,        i.invoice_currency_code
,        ps.amount_remaining
,        ps.gross_amount
from     ap_invoices_all i
,        ap_payment_schedules_all ps
,        po_vendor_sites_all vs
where    1=1
and      ps.amount_remaining != 0
and      ps.invoice_id = i.invoice_id
and      i.payment_status_flag < 'Y'
and      i.cancelled_date is null
and      vs.vendor_site_id = i.vendor_site_id
and      not
            (
            I.invoice_type_lookup_code = 'PREPAYMENT'
            and
            I.payment_status_flag = 'N'
            )
and      i.vendor_id =1687
and      i.org_id = 85
and      i.invoice_id = 1664480
--and      i.invoice_amount = -2285.16
;