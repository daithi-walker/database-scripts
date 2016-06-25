select 	ctt.name
,		hca.account_number
,		rct.trx_number
,		rct.creation_date
,		rctl.description
,		rctl.quantity_credited
,		rctl.unit_selling_price
,		rctl.extended_amount
,		rct.trx_date
,		rctl.line_type
,		rctl.org_id
from   	hz_cust_accounts hca
,		ra_customer_trx_all rct
,		ra_customer_trx_lines_all rctl
,		ra_cust_trx_types_all ctt
--,		hz_cust_acct_sites_all hcas
where 	1=1
and 	rct.customer_trx_id = rctl.customer_trx_id
and 	hca.cust_account_id = rct.bill_to_customer_id
and 	rct.cust_trx_type_id = ctt.cust_trx_type_id
--and 	hcas.cust_acct_site_id = rct.bill_to_site_use_id
and 	rct.creation_date between '01-MAR-2014' and '31-MAR-2014'
and 	ctt.org_id = 85
and 	ctt.type = 'CM'
--and 	rct.trx_number = '63252'