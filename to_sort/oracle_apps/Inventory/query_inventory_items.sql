ALTER SESSION SET NLS_LANGUAGE='AMERICAN';

SELECT   msi.segment1 item
,        msi.description item_description
,        DECODE(mc.segment2
               ,'P', 'PRODUCTION' 
					,'I', 'INSTRUMENTATION'
					,'M', 'MECHANICAL'
					,'A', 'ADMINISTRATION'
					,'T', 'MOBILE PLANT'
					,'E', 'ELECTRICAL'
               ,mc.segment2
               ) item_minor_category
,        mc.segment3 material_code
,        mmt.transaction_date  
,        NVL((case when mmt.transaction_action_id in (12, 24, 27, 29) then mmt.transaction_quantity else 0 end), 0) receipt_qty
,        NVL((case when mmt.transaction_action_id in (12, 24, 27, 29) then 0-mta.base_transaction_value else 0 end), 0) receipt_value
,        NVL((case when mmt.transaction_action_id in (1,21) then 0-mmt.transaction_quantity else 0 end), 0) issue_qty
,        NVL((case when mmt.transaction_action_id in (1,21) then mta.base_transaction_value else 0 end), 0) issue_value
FROM     mtl_material_transactions mmt
,        mtl_transaction_accounts mta
,        mtl_transaction_types mtt
,        mtl_system_items_b msi
,        mtl_categories_kfv mc
,        mtl_item_categories mic
WHERE    1=1
--AND      mta.accounting_line_type IN  (2,5,14) -- (Account, Receiving Inspection, Intransit Inventory) 
AND      mmt.transaction_type_id = mtt.transaction_type_id
AND      mmt.transaction_id = mta.transaction_id
AND      mmt.inventory_item_id = msi.inventory_item_id
AND      mmt.organization_id = msi.organization_id
AND      msi.inventory_item_id = mic.inventory_item_id
AND      msi.organization_id = mic.organization_id
AND      mic.category_set_id = 1
AND      mic.category_id = mc.category_id
-----------------------------------------
--query specific
AND      mta.organization_id = 1128
AND      mta.gl_batch_id = -1
AND      mta.transaction_date < to_date('01-APR-2015','DD-MON-YYYY')
;