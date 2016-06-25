SELECT   PV.VENDOR_NAME                SUPPLIER_NAME
,        PV.SEGMENT1                   SUPPLIER_NUM
,        PVSA.VENDOR_SITE_CODE         SUPPLIER_SITE
,        AIA.INVOICE_DATE              INVOICE_DATE
,        AIA.INVOICE_NUM               INVOICE_NO
,        AIA.DESCRIPTION               INVOICE_DESCRIPTION
,        AIA.INVOICE_AMOUNT            INVOICE_AMOUNT
,        FU1.USER_NAME                 ENTERED_BY_USERNAME      --who enters invoice puts a hold on “awaiting EO approval”
,        FU1.DESCRIPTION               ENTERED_BY_NAME
,        FU2.USER_NAME                 WHO_RELEASED_USERNAME      --Who released “awaiting EO approval” hold
,        FU2.DESCRIPTION               WHO_RELEASED_NAME
,        FU3.USER_NAME                 WHO_SEC_APPRV_USERNAME         --Who Secondary approved payment
,        FU3.DESCRIPTION               WHO_SEC_APPRV
FROM     AP_INVOICES_ALL               AIA
,        PO_VENDORS                    PV
,        PO_VENDOR_SITES_ALL           PVSA
,        FND_USER                      FU1
,        AP_INVOICE_DISTRIBUTIONS_ALL  AIDA
,        GL_CODE_COMBINATIONS          GCC
,        AP_HOLDS_ALL                  AHA1
,        FND_USER                      FU2
,        AP_HOLDS_ALL                  AHA2
,        FND_USER                      FU3
WHERE    1=1
AND      AIA.INVOICE_ID = :INVOICE_ID --1336780
AND      PV.VENDOR_ID = AIA.VENDOR_ID
AND      PVSA.VENDOR_ID = PV.VENDOR_ID
AND      PVSA.VENDOR_SITE_ID = AIA.VENDOR_SITE_ID
AND      FU1.USER_ID = AIA.CREATED_BY
AND      AIDA.INVOICE_ID = AIA.INVOICE_ID
AND      AIDA.LINE_TYPE_LOOKUP_CODE = 'ITEM'
AND      GCC.CODE_COMBINATION_ID = AIDA.DIST_CODE_COMBINATION_ID
AND      AHA1.INVOICE_ID = AIA.INVOICE_ID
AND      AHA1.HOLD_LOOKUP_CODE = 'Awaiting EO Approval' 
AND      AHA1.RELEASE_LOOKUP_CODE = 'INVOICE QUICK RELEASED'
AND      FU2.USER_ID = AHA1.LAST_UPDATED_BY
AND      AHA2.INVOICE_ID = AIA.INVOICE_ID
AND      AHA2.HOLD_LOOKUP_CODE = 'AWAIT_SEC_APP' 
AND      AHA2.RELEASE_LOOKUP_CODE = 'SEC_APP'
AND      FU3.USER_ID = AHA2.LAST_UPDATED_BY
ORDER BY PV.VENDOR_NAME
;