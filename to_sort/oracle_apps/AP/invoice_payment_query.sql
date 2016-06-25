SELECT   aia.org_id "ORG ID"
,        pv.vendor_name "VENDOR NAME"
,        UPPER(pv.vendor_type_lookup_code) "VENDOR TYPE"
,        pvsa.vendor_site_code "VENDOR SITE"
,        pvsa.address_line1 "ADDRESS"
,        pvsa.city "CITY"
,        pvsa.country "COUNTRY"
,        TO_CHAR(TRUNC(pha.creation_date)) "PO DATE"
,        pha.segment1 "PO NUMBER"
,        pha.type_lookup_code "PO TYPE"
,        pda.quantity_ordered "QTY ORDERED"
,        pda.quantity_cancelled "QTY CANCALLED"
,        pla.item_description "ITEM DESCRIPTION"
,        pla.unit_price "UNIT PRICE"
,        (NVL(pda.quantity_ordered,0) - NVL(pda.quantity_cancelled,0)) * NVL(pla.unit_price,0) "PO Line Amount"
,        DECODE(pha.approved_flag, 'Y', 'Approved') "PO STATUS"
,        aia.invoice_type_lookup_code "INVOICE TYPE"
,        aia.invoice_amount "INVOICE AMOUNT"
,        TO_CHAR(TRUNC(aia.invoice_date)) "INVOICE DATE"
,        aia.invoice_num "INVOICE NUMBER"
,        DECODE(aida.match_status_flag, 'A', 'Approved') "INVOICE APPROVED?"
,        aia.amount_paid
,        aipa.amount
,        aca.check_number                "CHEQUE NUMBER"
,        TO_CHAR(TRUNC(aca.check_date))  "PAYMENT DATE"
FROM     ap.ap_invoices_all aia
,        ap.ap_invoice_distributions_all aida
,        po.po_distributions_all pda
,        po.po_headers_all pha
,        po.po_vendors pv
,        po.po_vendor_sites_all pvsa
,        po.po_lines_all pla
,        ap.ap_invoice_payments_all aipa
,        ap.ap_checks_all aca
WHERE    1=1
AND      aia.invoice_id = aida.invoice_id
AND      aida.po_distribution_id = pda.po_distribution_id(+)
AND      pda.po_header_id = pha.po_header_id(+)
AND      pv.vendor_id(+) = pha.vendor_id
AND      pvsa.vendor_site_id(+) = pha.vendor_site_id
AND      pha.po_header_id = pla.po_header_id
AND      pda.po_line_id = pla.po_line_id
AND      aia.invoice_id = aipa.invoice_id
AND      aipa.check_id = aca.check_id
AND      pvsa.vendor_site_id = aca.vendor_site_id
AND      pda.po_header_id IS NOT NULL
AND      aia.payment_status_flag = 'Y'
AND      pha.type_lookup_code != 'BLANKET';