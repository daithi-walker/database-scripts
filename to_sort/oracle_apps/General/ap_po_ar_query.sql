SELECT distinct pha.segment1 po_number
       ,aia.invoice_num invoice_number
       ,rsh.receipt_num receipt_number
  FROM po_headers_all pha
       ,po_distributions_all pda
       ,ap_invoice_distributions_all aid
       ,ap_invoices_all aia
       ,rcv_shipment_lines rsl
       ,rcv_shipment_headers rsh
 WHERE pha.po_header_id=pda.po_header_id
   AND aid.po_distribution_id=pda.po_distribution_id
   AND aia.invoice_id=aid.invoice_id
   and aid.invoice_id = 570643
   AND rsl.po_header_id=pha.po_header_id
   AND rsl.shipment_header_id=rsh.shipment_header_id
   and pha.po_header_id = 570643
   --AND pha.segment1=nvl(:P_PO_NUM,pha.segment1)
   --AND aia.invoice_num=nvl(:P_INVOICE_NUM,aia.invoice_num)
   --AND rsh.receipt_num=nvl(:P_RECEIPT_NUM,rsh.receipt_num)
 order by 2 
;