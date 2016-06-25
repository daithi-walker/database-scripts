SELECT   pha.*
FROM     apps.po_headers_all pha
WHERE    1=1
AND      pha.po_header_id IN (490683);

SELECT * FROM APPS.PO_REQUISITION_HEADERS_ALL;
SELECT * FROM APPS.PO_REQUISITION_LINES_ALL;
SELECT * FROM APPS.PO_LINES_ALL;
SELECT * FROM APPS.PO_VENDOR_SITES_ALL;
SELECT * FROM APPS.PO_DISTRIBUTIONS_ALL;
SELECT * FROM APPS.PO_RELEASES_ALL;
SELECT * FROM APPS.PO_VENDOR_CONTACTS;
SELECT * FROM APPS.PO_ACTION_HISTORY;
SELECT * FROM APPS.PO_REQ_DISTRIBUTIONS_ALL;
SELECT * FROM APPS.PO_LINE_LOCATIONS_ALL;

SELECT   invoice_id
FROM     apps.ap_invoice_distributions_all
WHERE    1=1
AND      po_distribution_id IN
         (
         SELECT   po_distribution_id
         FROM     apps.po_distributions_all
         WHERE    1=1
         AND      po_header_id = 490683
         );