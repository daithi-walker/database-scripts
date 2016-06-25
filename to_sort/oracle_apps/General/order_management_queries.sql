-- Order header info
select   ooh.header_id
,        ooh.flow_status_code --mine
,        ooh.booked_flag --mine
,        ooh.org_id
,        ooh.order_type_id
,        ooh.price_list_id
,        ooh.sold_to_org_id
,        ooh.ship_to_org_id
,        ooh.invoice_to_org_id
,        ooh.transactional_curr_code
,        ooh.*
from     apps.oe_order_headers_all ooh
where    1=1
and      ooh.order_number= 90907161 --:p_order_number
;

-- Operating unit info
select   hou.*
from     hr_operating_units hou
where    1=1
and      hou.organization_id = 95 --oe_order_headers_all.org_id
;

-- Order type info
select   ott.*
from     apps.oe_transaction_types_tl ott
where    1=1
and      ott.transaction_type_id = 1001 --oe_order_headers_all.order_type_id
;

-- Price list info
select   qlh.*
from     apps.qp_list_headers_tl qlh
where    1=1
and      qlh.list_header_id = 6149 --oe_order_headers_all.price_list_id
;

select   qll.*
from     apps.qp_list_lines qll
where    1=1
and      qll.list_header_id = 6149 --oe_order_headers_all.price_list_id
;

-- Find customer info
select   hca.party_id
,        hca.*
from     hz_cust_accounts hca
where    1=1
and      hca.cust_account_id = 3501 --oe_order_headers_all.sold_to_org_id
;

select   hp.*
from     apps.hz_parties hp
where    1=1
and      hp.party_id = 32828 --hz_cust_accounts.party_id
;

-- Find Ship to location info
select   hcsu.cust_acct_site_id
,        hcsu.*
from     apps.hz_cust_site_uses_all hcsu
where    1=1
and      hcsu.site_use_id = 4085 --oe_order_headers_all.ship_to_org_id
;

select   hcas.party_site_id
,        hcas.*
from     apps.hz_cust_acct_sites_all hcas
where    1=1
and      hcas.cust_acct_site_id = 3183 --hz_cust_site_uses_all.cust_acct_site_id
;

select   hps.location_id
,        hps.*
from     apps.hz_party_sites hps
where    1=1
and      hps.party_site_id = 3223 --hz_cust_acct_sites_all.party_site_id
;

-- Find Bill to location
select   hcsu.cust_acct_site_id
,        hcsu.*
from     apps.hz_cust_site_uses_all hcsu
where    1=1
and      hcsu.site_use_id = 4065 --oe_order_headers_all.invoice_to_org_id
;
         
select   hcas.*
from     apps.hz_cust_acct_sites_all hcas
where    1=1
and      cust_acct_site_id = 3164 --hz_cust_site_uses_all.cust_acct_site_id
;
         
select * from hz_party_sites
where party_site_id=hz_cust_acct_sites_all.party_site_id

actual address
select * from hz_locations 
where location_id = 7346 --hz_party_sites.location_id

Sales rep id
select name from apps.ra_salesreps_all salerep  where
salesrep_id = oe_order_headers_all.salesrep_id  and rownum =1

Payment terms
select name from apps.ra_terms_tl
where term_id =oe_order_headers_all.payment_term_id
and language = 'US'

Order source
select name from apps.oe_order_sources
where order_source_id= oe_order_headers_all.order_source_id
and enabled_flag= 'Y'

Order Source Reference
select orig_sys_document_ref from oe_order_headers_all ooh
where order_number='&oracle order number'

FOB Point Code
select lookup_code from ar_lookups
where lookup_type = 'FOB' and enabled_flag = 'Y'
and upper(meaning) = upper(oe_order_headers_all.fob_point_code)

Freight terms
select lookup_code from apps.oe_lookups
where upper (lookup_type) = 'FREIGHT_TERMS'  and enabled_flag = 'Y'
and upper (lookup_code) = upper (oe_order_headers_all.freight_terms_code)

For sales channel code validation
select lookup_code from apps.oe_lookups
where lookup_type = 'SALES_CHANNEL' and enabled_flag = 'Y'
upper(lookup_code) = upper(oe_order_headers_all.sales_channel_code)

Ship method
select ship_method_code from wsh.wsh_carrier_services
where ship_method_code = oe_order_headers_all.shipping_method_code

Warehouse Info
select * from org_organization_definitions
where organization_id = oe_order_headers_all.ship_from_org_id

-- Sales order Lines Details
select   ool.ordered_item
,        ool.flow_status_code --mine
,        ool.ship_from_org_id
,        ool.order_quantity_uom
,        ool.item_type_code
,        ool.inventory_item_id
,        ool.*
from     apps.oe_order_lines_all ool
where    1=1
and      ool.header_id = 97366 --oe_order_headers_all.header_id
and      ool.ordered_item = '0336'
;

-- Transactional currency code
select   ota.price_list_id
,        qhb.currency_code
from     ont.oe_transaction_types_all ota
,        qp.qp_list_headers_b qhb
where    1=1
and      ota.transaction_type_id = 1001 --oe_order_headers_all.order_type_id
and      ota.price_list_id = qhb.list_header_id(+)
and      nvl(qhb.list_type_code, 'PRL') = 'PRL'
and      qhb.currency_code = 'USD' --oe_order_headers_all.transactional_curr_code
;

-- Item info
select   *
from     apps.mtl_system_items_b msi
where    1=1
and      msi.segment1 like '0336' --oe_order_lines_all.ordered_item
and      msi.organization_id = 575 --oe_order_lines_all.ship_from_org_id
;

-- UOM
select   muom.uom_code
from     inv.mtl_units_of_measure_tl muom
where    1=1
and      upper(muom.uom_code)= 'KIT' -- upper(oe_order_lines_all.order_quantity_uom)
and      language= 'US'
and      nvl(muom.disable_date, (sysdate + 1)) > sysdate
;

-- Item type code validation
select   ol.lookup_code
from     apps.oe_lookups ol
where    1=1
and      upper(ol.lookup_type) = 'ITEM_TYPE'
and      ol.enabled_flag = 'Y'
and      upper(ol.lookup_code)= 'STANDARD' --oe_order_lines_all.item_type_code
;

-- On hand quantities
select   moq.*
from     apps.mtl_onhand_quantities moq
where    1=1
and      moq.inventory_item_id = 33765 --oe_order_lines_all.inventory_item_id
and      moq.organization_id = 575 --oe_order_lines_all.ship_from_org_id

-- Shipping
select   wdd.released_status --mine
,        wdd.*
from     apps.wsh_delivery_details wdd
where    1=1
and      wdd.source_header_id = 97366 --oe_order_headers_all.header_id
and      wdd.inventory_item_id = 33765 --added by me
;

select   wda.delivery_id
,        wda.*
from     apps.wsh_delivery_assignments wda
where    1=1
and      wda.delivery_detail_id = 15694 --wsh_delivery_details.delivery_detail_id
;

select   wnd.delivery_id
,        wnd.organization_id
,        wnd.*
from     apps.wsh_new_deliveries wnd
where    1=1
and      wnd.delivery_id = 8429 --wsh_delivery_assignments.delivery_id
;

select   wdl.pick_up_stop_id
,        wdl.*
from     apps.wsh_delivery_legs wdl
where    1=1
and      wdl.delivery_id = 8429 --wsh_new_deliveries.delivery_id
;

select   wts.trip_id
,        wts.*
from     apps.wsh_trip_stops wts
where    1=1
and      wts.stop_id = 4925 --wsh_delivery_legs.pick_up_stop_id
;

select   wt.*
from     apps.wsh_trips wt
where    1=1
and      wt.trip_id = 5626 --wsh_trip_stops.trip_id
;

select   ood.*
from     apps.org_organization_definitions ood
where    1=1
and      ood.organization_id = 575 --wsh_new_deliveries.organization_id
;

-- Material transactions
select   mtt.transaction_type_name
,        mtst.transaction_source_type_name
,        mmt.transaction_type_id
,        mmt.transaction_source_type_id
,        mmt.*
from     apps.mtl_material_transactions mmt
,        apps.mtl_transaction_types mtt
,        apps.mtl_txn_source_types mtst
where    1=1
and      mtst.transaction_source_type_id = mmt.transaction_source_type_id
and      mtt.transaction_type_id = mmt.transaction_type_id
and      mmt.inventory_item_id = 33765 --oe_order_lines_all.inventory_item_id
and      mmt.organization_id = 575 --oe_order_lines_all.ship_from_org_id
;

select   mr.*
from     apps.mtl_reservations mr
where    1=1
and      mr.inventory_item_id = 33765 --oe_order_lines_all.inventory_item_id
;

/*
select   mmt.transaction_type_id
,        mmt.transaction_source_type_id
,        mmt.*
from     apps.mtl_material_transactions mmt
where    1=1
and      mmt.inventory_item_id = 33765 --oe_order_lines_all.inventory_item_id
and      mmt.organization_id = 575 --oe_order_lines_all.ship_from_org_id
;

select   mtt.transaction_type_name
,        mtt.*
from     apps.mtl_transaction_types mtt
where    1=1
and      mtt.transaction_type_id in (18,33) --mmt.transaction_type_id
;

select   mtst.transaction_source_type_name 
,        mtst.*
from     apps.mtl_txn_source_types mtst
where    1=1
and      mtst.transaction_source_type_id in (1,2) -- = mmt.transaction_source_type_id
;
*/

-- Join between OM, WSH, AR Tables
select   ooh.order_number
,        ool.line_id
,        ool.ordered_quantity
,        ool.shipped_quantity
,        ool.invoiced_quantity
,        wdd.delivery_detail_id
,        wnd.delivery_id
,        rctl.interface_line_attribute1
,        rctl.interface_line_attribute3
,        rctl.interface_line_attribute6
,        rct.org_id
,        rct.creation_date
,        rct.trx_number
,        rctl.quantity_ordered
,        rct.interface_header_context
from     apps.oe_order_headers_all ooh
,        apps.oe_order_lines_all ool
,        apps.wsh_delivery_details wdd
,        apps.wsh_delivery_assignments wda
,        apps.wsh_new_deliveries wnd
,        apps.ra_customer_trx_lines_all rctl
,        apps.ra_customer_trx_all rct
where    1=1
and      rctl.customer_trx_id = rct.customer_trx_id
and      rct.interface_header_context = 'ORDER ENTRY'
and      rctl.interface_line_attribute1 = to_char(ooh.order_number)
and      rctl.interface_line_attribute6 = to_char(ool.line_id)
and      rctl.interface_line_attribute3 = to_char(wnd.delivery_id)
and      wnd.delivery_id = wda.delivery_id
and      wda.delivery_detail_id = wdd.delivery_detail_id
and      wdd.source_header_id = ooh.header_id
and      ool.header_id = ooh.header_id
and      ool.ordered_item = '0336'
and      ooh.header_id = 97366
;

-- Purchase release concurrent program will transfer the details from OM
-- to PO requisitions interface. The following query will verify the same:
select   pri.interface_source_code
,        pri.interface_source_line_id
,        pri.quantity
,        pri.destination_type_code
,        pri.transaction_id
,        pri.process_flag
,        pri.request_id
,        TRUNC(pri.creation_date)
from     apps.po_requisitions_interface_all pri
where    1=1
and      pri.interface_source_code = 'ORDER ENTRY'
and      pri.interface_source_line_id IN
         (
         select   odss.drop_ship_source_id
         from     apps.oe_drop_ship_sources odss
         where    1=1
         and      odss.header_id = 97366 --&order_hdr_id
         --and      odss.line_id = &order_line_id
         )
;
 
-- The following sql is used to review the requisition, sales order, and receipt number.
-- It shows the joins between various tables in Internal Sales order (ISO)
select   porh.segment1
,        porl.line_num
,        pord.distribution_num
,        ooh.order_number sales_order
,        ool.line_number so_line_num
,        rsh.receipt_num
,        rcv.transaction_type
from     apps.oe_order_headers_all ooh
,        apps.po_system_parameters_all posp
,        apps.po_requisition_headers_all porh
,        apps.oe_order_lines_all ool
,        apps.po_requisition_lines_all porl
,        apps.po_req_distributions_all pord
,        apps.rcv_transactions rcv
,        apps.rcv_shipment_headers rsh
where    1=1
and      rsh.shipment_header_id = rcv.shipment_header_id
and      rcv.requisition_line_id = porl.requisition_line_id
and      rcv.req_distribution_id = pord.distribution_id
and      pord.requisition_line_id = porl.requisition_line_id
and      porl.requisition_header_id = porh.requisition_header_id
and      porl.requisition_line_id = ool.source_document_line_id
and      ool.source_document_id = porh.requisition_header_id
and      porh.org_id = posp.org_id
and      posp.order_source_id = ooh.order_source_id
and      ooh.order_number = 90907161
;