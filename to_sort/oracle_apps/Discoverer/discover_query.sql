SELECT   DECODE(q1.COMMAND_CUST_NOTE_CNT,0,NULL,1,NULL,'More than 1 Note found for Trx / Customer/ Tick') as C_1
,        q1.ORG_CODE as E541522
,        q1.MONTH as E541523
,        q1.CUSTOMER_NUMBER as E541524
,        q1.LOCATION as E541525
,        q1.TRX_NO as E541526
,        q1.CURR as E541527
,        q1.EXCHANGE_RATE as E541528
,        q1.TRX_TYPE as E541529
,        q1.TRX_DATE as E541532
,        q1.CLASS as E541533
,        q1.LINE_NO as E541536
,        q1.PRODUCT as E541537
,        q1.DESCRIPTION as E541538
,        q1.ORDER_NUM as E541543
,        q1.TCKT_NO as E541545
,        q1.TCKT_LINE as E541546
,        q1.ORDER_NO as E541547
,        q1.ORDER_DATE as E541548
,        q1.TRCK_NO as E541549
,        q1.COLL_DEL as E541550
,        q1.EQ_UNITS as E541551
,        q1.LOC as E541552
,        q1.CA_TYPE as E541553
,        q1.GL_COMBINATION as E541554
,        q1.GL_LOCATION as E541555
,        q1.GL_ACCOUNT as E541557
,        q1.COMMAND_CUST_NOTE as E593309
,        q1.COMMAND_CUST_NOTE_CNT as E593310
,        SUM(q1.QTY) as E541539_SUM
,        SUM(q1.FUNCT_REV_AMOUNT) as E541755_SUM
,        SUM(q1.REV_AMOUNT) as E541753_SUM
 FROM    (
         --QUERY ONE: COMMAND REVENUE LINES
         -- From query run by Martyn Holmes for Doreen Ludlow
         SELECT   rct.customer_trx_id
         ,        rctl.customer_trx_line_id
         ,        SUBSTR (hou.NAME, 1, 3) org_code
         ,        TO_CHAR (rct.trx_date, 'RRRRMM') MONTH
         ,        hca.account_number customer_number
         ,        hsu.LOCATION
         ,        rct.trx_number trx_no
         ,        rct.invoice_currency_code curr
         ,        rct.exchange_rate
         ,        rctt.NAME trx_type
         ,        rbs.NAME batch_source_name
         ,        rbs.description batch_source_description
         ,        rct.trx_date trx_date
         ,        rgd.account_class CLASS
         ,        SUM (rgd.amount) amt
         ,        ROUND (SUM (rgd.amount * NVL (rct.exchange_rate, 1)), 2) funct_amt
         ,        SUM (DECODE (rgd.account_class, 'REV', rgd.amount, 0)) rev_amount
         ,        SUM (DECODE (rgd.account_class, 'TAX', rgd.amount, 0)) tax_amount
         ,        ROUND (SUM (  NVL (rct.exchange_rate, 1) * DECODE (rgd.account_class, 'REV', rgd.amount, 0) ), 2) funct_rev_amount
         ,        ROUND (SUM (  NVL (rct.exchange_rate, 1) * DECODE (rgd.account_class, 'TAX', rgd.amount, 0) ), 2) funct_tax_amount
         ,        rctl.line_number line_no
         ,        msi.segment1 product
         ,        rctl.description description
         ,        NVL (rctl.quantity_invoiced, 0) + NVL (rctl.quantity_credited, 0) qty
         ,        rctl.unit_selling_price price
         ,        SUM (rctl.extended_amount) ext_amt
         ,        ROUND (SUM (rctl.extended_amount * NVL (rct.exchange_rate, 1)),2) funct_ext_amt
         ,        rctl.sales_order order_num, rctl.reason_code
         ,        rctl.interface_line_attribute1 tckt_no
         ,        rctl.interface_line_attribute2 tckt_line
         ,        rctl.interface_line_attribute3 order_no
         ,        rctl.interface_line_attribute4 order_date
         ,        rctl.interface_line_attribute5 trck_no
         ,        rctl.interface_line_attribute7 coll_del
         ,        rctl.interface_line_attribute11 eq_units
         ,        rctl.interface_line_attribute9 loc
         ,        rctl.interface_line_attribute12 ca_type
         ,        gcc.concatenated_segments gl_combination
         ,        gcc.segment2 gl_location
         ,        gcc.segment7 gl_code
         ,        gcc.segment4 gl_account
         -- COS 30 JUL 2012 F0048210
         ,        (
                  SELECT   MAX (cust_note)
                  FROM     apps.xxcrh_invc_note_field_v xinfv
                  WHERE    1=1
                  AND      xinfv.invc_code = LPAD (rct.trx_number, 12)
                  AND      xinfv.cust_code = LPAD (hca.account_number, 10)
                  AND      xinfv.tkt_code = LPAD (rctl.interface_line_attribute1, 8)
                  --and      xinfv.order_code = LPAD(rctl.interface_line_attribute3,12)
                  ) AS command_cust_note
         ,        (
                  SELECT   COUNT (cust_note)
                  FROM     apps.xxcrh_invc_note_field_v xinfv
                  WHERE    1=1
                  AND      xinfv.invc_code = LPAD (rct.trx_number, 12)
                  AND      xinfv.cust_code = LPAD (hca.account_number, 10)
                  AND      xinfv.tkt_code = LPAD (rctl.interface_line_attribute1, 8)
                  --and      xinfv.order_code = LPAD(rctl.interface_line_attribute3,12)
                  ) AS command_cust_note_cnt
         FROM     apps.ra_customer_trx_all rct
         ,        apps.ra_customer_trx_lines_all rctl
         ,        apps.ra_cust_trx_line_gl_dist_all rgd
         ,        apps.ra_cust_trx_types_all rctt
         ,        apps.ra_batch_sources_all rbs
         ,        apps.hr_operating_units hou
         ,        apps.mtl_system_items_b msi
         ,        apps.gl_code_combinations_kfv gcc
         ,        apps.hz_cust_site_uses_all hsu
         ,        apps.hz_cust_accounts_all hca
         WHERE    1=1
         AND      rct.customer_trx_id = rctl.customer_trx_id
         AND      rct.cust_trx_type_id = rctt.cust_trx_type_id
         AND      rct.org_id = rctt.org_id
         AND      rct.bill_to_site_use_id = hsu.site_use_id
         AND      rct.bill_to_customer_id = hca.cust_account_id
         AND      rct.org_id = hou.organization_id
         AND      rctl.inventory_item_id = msi.inventory_item_id(+)
         AND      NVL (msi.organization_id,
                       DECODE (rct.org_id,
                               81, 86,
                               83, 86,
                               84, 86,
                               85, 86,
                               806, 86,
                               1106, 1126,
                               1107, 1126,
                               86
                              )
                      ) =
                     DECODE (rct.org_id,
                             81, 86,
                             83, 86,
                             84, 86,
                             85, 86,
                             806, 86,
                             1106, 1126,
                             1107, 1126,
                             86
                            )
         AND      rct.batch_source_id = rbs.batch_source_id
         AND      rct.org_id = rbs.org_id
         AND      rgd.account_class IN ('REV', 'TAX')
         AND      rctl.customer_trx_line_id = rgd.customer_trx_line_id
         AND      rctl.customer_trx_id = rgd.customer_trx_id
         AND      rgd.code_combination_id = gcc.code_combination_id
         GROUP BY rct.customer_trx_id
         ,        rctl.customer_trx_line_id
         ,        hou.NAME
         ,        TO_CHAR (rct.trx_date, 'RRRRMM')
         ,        hca.account_number
         ,        hsu.LOCATION
         ,        rct.trx_number
         ,        rctl.description
         ,        rctt.NAME
         ,        rbs.NAME
         ,        rbs.description
         ,        rct.trx_date
         ,        rgd.account_class
         ,        gcc.concatenated_segments
         ,        gcc.segment2
         ,        gcc.segment7
         ,        gcc.segment4
         ,        rctl.quantity_invoiced
         ,        rctl.line_number
         ,        rctl.reason_code
         ,        msi.segment1
         ,        rctl.sales_order
         ,        rct.invoice_currency_code
         ,        rct.exchange_rate
         ,        rctl.interface_line_attribute1
         ,        rctl.interface_line_attribute2
         ,        rctl.interface_line_attribute3
         ,        rctl.interface_line_attribute4
         ,        rctl.interface_line_attribute5
         ,        rctl.interface_line_attribute7
         ,        rctl.interface_line_attribute11
         ,        rctl.interface_line_attribute9
         ,        rctl.interface_line_attribute12
         ,        NVL (rctl.quantity_invoiced, 0) + NVL (rctl.quantity_credited, 0)
         ,        rctl.unit_selling_price
         ORDER BY rct.trx_number, rctl.line_number
         ) q1
WHERE    1=1
AND      (q1.CLASS = 'REV')
AND      (q1.ORG_CODE = UPPER(:"Organization") AND q1.ORG_CODE IN ('ICL','PCL','SCL'))
AND      (q1.MONTH = :"Month")
AND      (q1.BATCH_SOURCE_NAME = :"Batch Source")
GROUP BY DECODE(q1.COMMAND_CUST_NOTE_CNT,0,NULL,1,NULL,'More than 1 Note found for Trx / Customer/ Tick')
,        q1.ORG_CODE
,        q1.MONTH
,        q1.CUSTOMER_NUMBER
,        q1.LOCATION
,        q1.TRX_NO
,        q1.CURR
,        q1.EXCHANGE_RATE
,        q1.TRX_TYPE
,        q1.TRX_DATE
,        q1.CLASS
,        q1.LINE_NO
,        q1.PRODUCT
,        q1.DESCRIPTION
,        q1.ORDER_NUM
,        q1.TCKT_NO
,        q1.TCKT_LINE
,        q1.ORDER_NO
,        q1.ORDER_DATE
,        q1.TRCK_NO
,        q1.COLL_DEL
,        q1.EQ_UNITS
,        q1.LOC
,        q1.CA_TYPE
,        q1.GL_COMBINATION
,        q1.GL_LOCATION
,        q1.GL_ACCOUNT
,        q1.COMMAND_CUST_NOTE
,        q1.COMMAND_CUST_NOTE_CNT
ORDER BY q1.TRX_TYPE ASC 
,        q1.CUSTOMER_NUMBER ASC ;
