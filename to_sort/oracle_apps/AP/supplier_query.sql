with vendors as
(
select vendor_id
from   ap_suppliers
where  1=1
/* COMMENT / UNCOMMENT and UPDATE THE NEXT 5 LINES AS YOU REQUIRE */
--and    vendor_type_lookup_code = 'VENDOR'
--and    upper( vendor_name ) like 'VIRTUATE%'
and    creation_date between '01-JAN-2011' and '01-JAN-2012'
--and    enabled_flag = 'Y'
)
, vend as
(
select pv.vendor_id                 vendor_id
,      pv.vendor_name_alt           vendor_name_alt
,      pv.vendor_name               vendor_name
,      pv.segment1                  vendor_number
,      pv.vendor_type_lookup_code   vendor_type_lookup_code
from   ap_suppliers pv
where  pv.vendor_id in (select v.vendor_id from vendors v)
)
, site as
(
select ss.vendor_id                    vendor_id
,      ss.vendor_site_id               vendor_site_id
,      ss.vendor_site_code             vendor_site_code
,      ss.vendor_site_code_alt         vendor_site_code_alt
,      ss.vat_code                     tax_code
,      ss.vat_registration_num         vat_registration_num
,      t.name                          terms_name
,      ss.address_line1                ss_address_line1
,      ss.address_line2                ss_address_line2
,      ss.address_line3                ss_address_line3
,      ss.zip                          ss_zip          
,      ss.city                         ss_city         
,      ss.state                        ss_state        
,      ss.country                      ss_country      
,      ss.area_code                    ss_area_code    
,      ss.phone                        ss_phone        
,      ss.fax_area_code                ss_fax_area_code
,      ss.fax                          ss_fax          
,      ss.telex                        ss_telex
,      ss.pay_site_flag                ss_pay_site_flag
,      ss.primary_pay_site_flag        ss_primary_pay_site_flag
,      pm.remit_advice_delivery_method ss_remit_advice_deliv_meth
,      pm.remit_advice_email           ss_remit_advice_email
,      pm.remit_advice_fax             ss_remit_advice_fax
,      pm.payment_method_code          ss_payment_method_code
,      ss.remittance_email             ss_remittance_email
,      ss.supplier_notif_method        ss_supplier_notif_method
,      ps.addressee                    ss_addressee
,      ( select hcp.phone_area_code
         from   hz_contact_points hcp
         where  hcp.owner_table_id = ss.party_site_id
         and    hcp.owner_table_name = 'HZ_PARTY_SITES'
         and    hcp.phone_line_type = 'GEN'
         and    hcp.contact_point_type = 'PHONE'
         --and    hcp.created_by_module = 'AP_SUPPLIERS_API'
         and    rownum < 2 -- copied from OAF View Object 
       ) ss_hcp_phone_area_code
,      ( select hcp.phone_number
         from   hz_contact_points hcp
         where  hcp.owner_table_id = ss.party_site_id
         and    hcp.owner_table_name = 'HZ_PARTY_SITES'
         and    hcp.phone_line_type = 'GEN'
         and    hcp.contact_point_type = 'PHONE'
         --and    hcp.created_by_module = 'AP_SUPPLIERS_API'
         and    rownum < 2 -- copied from OAF View Object 
       ) ss_hcp_phone_number
,      ( select hcp.phone_area_code
         from   hz_contact_points hcp
         where  hcp.owner_table_id = ss.party_site_id
         and    hcp.owner_table_name = 'HZ_PARTY_SITES'
         and    hcp.phone_line_type = 'FAX'
         and    hcp.contact_point_type = 'PHONE'
         --and    hcp.created_by_module = 'AP_SUPPLIERS_API'
         and    rownum < 2 -- copied from OAF View Object 
       ) ss_hcp_fax_area_code
,      ( select hcp.phone_number
         from   hz_contact_points hcp
         where  hcp.owner_table_id = ss.party_site_id
         and    hcp.owner_table_name = 'HZ_PARTY_SITES'
         and    hcp.phone_line_type = 'FAX'
         and    hcp.contact_point_type = 'PHONE'
         --and    hcp.created_by_module = 'AP_SUPPLIERS_API'
         and    rownum < 2 -- copied from OAF View Object 
       ) ss_hcp_fax_number
from   ap_supplier_sites_all ss
,      ap_suppliers sup
,      ap_terms t
,      (
         select ss.vendor_site_id
              , payee.remit_advice_delivery_method
              , payee.remit_advice_email
              , payee.remit_advice_fax
              , pm.payment_method_code
         from   iby_external_payees_all payee
         ,      iby_ext_party_pmt_mthds pm
         ,      hz_party_sites ps
         ,      ap_supplier_sites_all ss
         where  payee.payee_party_id = ps.party_id
         and    payee.payment_function = 'PAYABLES_DISB'
         and    payee.party_site_id = ss.party_site_id
         and    payee.supplier_site_id = ss.vendor_site_id
         and    payee.org_id = ss.org_id
         and    payee.org_type = 'OPERATING_UNIT'
         and    ss.party_site_id = ps.party_site_id
         and    payee.ext_payee_id = pm.ext_pmt_party_id (+)
         and    pm.primary_flag (+) = 'N'
         and not exists
                ( select 1
                  from   iby_ext_party_pmt_mthds pm2
                  where  pm.ext_pmt_party_id = pm2.ext_pmt_party_id
                  and    pm2.primary_flag = 'Y'
                )
         union all
         select ss.vendor_site_id
              , payee.remit_advice_delivery_method
              , payee.remit_advice_email
              , payee.remit_advice_fax
              , pm.payment_method_code
         from   iby_external_payees_all payee
         ,      iby_ext_party_pmt_mthds pm
         ,      hz_party_sites ps
         ,      ap_supplier_sites_all ss
         where  payee.payee_party_id = ps.party_id
         and    payee.payment_function = 'PAYABLES_DISB'
         and    payee.party_site_id = ss.party_site_id
         and    payee.supplier_site_id = ss.vendor_site_id
         and    payee.org_id = ss.org_id
         and    payee.org_type = 'OPERATING_UNIT'
         and    ss.party_site_id = ps.party_site_id
         and    pm.ext_pmt_party_id = payee.ext_payee_id
         and    pm.primary_flag = 'Y'
       ) pm
,      hz_party_sites ps
where  sup.vendor_id in (select vendor_id from vendors)
and    sup.vendor_id = ss.vendor_id
and    ss.vendor_site_id = pm.vendor_site_id (+)
and    ss.party_site_id = ps.party_site_id (+)
and    ss.terms_id = t.term_id (+)
)
, cont as
(
select pv.vendor_id           vendor_id
,      pvs.vendor_site_id     vendor_site_id
,      hp.party_id            c_party_id
,      hp.person_first_name   c_first_name
,      hp.person_last_name    c_last_name
,      hp.person_title        c_person_title
,      hcpe.email_address     c_email_address
,      hcpp.phone_area_code   c_phone_area_code
,      hcpp.phone_number      c_phone_number
,      hcpf.phone_area_code   c_fax_area_code
,      hcpf.phone_number      c_fax_number
from   hz_parties hp
,      hz_relationships hzr
,      hz_contact_points hcpp
,      hz_contact_points hcpf
,      hz_contact_points hcpe
,      ap_suppliers pv
,      ap_supplier_sites_all pvs
,      hz_party_sites hps
where  hp.party_id = hzr.subject_id
and    hzr.relationship_type = 'CONTACT'
and    hzr.relationship_code = 'CONTACT_OF'
and    hzr.subject_type = 'PERSON'
and    hzr.subject_table_name = 'HZ_PARTIES'
and    hzr.object_type = 'ORGANIZATION'
and    hzr.object_table_name = 'HZ_PARTIES'
and    hzr.status = 'A'
and    hcpp.owner_table_name(+) = 'HZ_PARTIES'
and    hcpp.owner_table_id(+) = hzr.party_id
and    hcpp.phone_line_type(+) = 'GEN'
and    hcpp.contact_point_type(+) = 'PHONE'
and    hcpf.owner_table_name(+) = 'HZ_PARTIES'
and    hcpf.owner_table_id(+) = hzr.party_id
and    hcpf.phone_line_type(+) = 'FAX'
and    hcpf.contact_point_type(+) = 'PHONE'
and    hcpe.owner_table_name(+) = 'HZ_PARTIES'
and    hcpe.owner_table_id(+) = hzr.party_id
and    hcpe.contact_point_type(+) = 'EMAIL'
and    hcpp.status (+)='A'
and    hcpf.status (+)='A'
and    hcpe.status (+)='A'
and    hps.party_id = hzr.object_id
and    pvs.party_site_id = hps.party_site_id
and    pv.vendor_id = pvs.vendor_id
and    exists
       ( select 1
         from ap_supplier_contacts ascs
         where (ascs.inactive_date is null
         or ascs.inactive_date      > sysdate)
         and hzr.relationship_id    = ascs.relationship_id
         and hzr.party_id           = ascs.rel_party_id
         and hps.party_site_id      = ascs.org_party_site_id
         and hzr.subject_id         = ascs.per_party_id
       )
and    pv.vendor_id in (select vendor_id from vendors)
)
, bank as
(
select  pv.vendor_id                    vendor_id
,       ss.vendor_site_id               vendor_site_id
,       hopbank.bank_or_branch_number   bank_number
,       hopbranch.bank_or_branch_number branch_number
,       eba.bank_account_num            bank_account_num
,       eba.bank_account_name           bank_account_name
,       piu.start_date                  bank_use_start_date
,       piu.end_date                    bank_use_end_date
,       piu.order_of_preference         bank_priority
from    iby_ext_bank_accounts eba
,       iby_external_payees_all payee
,       iby_pmt_instr_uses_all piu
,       ap_supplier_sites_all ss
,       ap_suppliers pv
,       hz_organization_profiles hopbank
,       hz_organization_profiles hopbranch
where   1=1
and     eba.bank_id = hopbank.party_id
and     eba.branch_id = hopbranch.party_id
and     payee.payment_function = 'PAYABLES_DISB'
and     payee.party_site_id = ss.party_site_id
and     payee.supplier_site_id = ss.vendor_site_id
and     payee.org_id = ss.org_id
and     payee.org_type = 'OPERATING_UNIT'
and     payee.ext_payee_id = piu.ext_pmt_party_id
and     piu.payment_flow = 'DISBURSEMENTS'
and     piu.instrument_type = 'BANKACCOUNT'
and     piu.instrument_id = eba.ext_bank_account_id
and     piu.start_date < sysdate
and     ( piu.end_date is null or
          piu.end_date > sysdate
        )
and     ss.vendor_id = pv.vendor_id
and     pv.vendor_id in (select vendor_id from vendors)
)
-- select distinct v.*, s.*, c.*, b.*
select distinct v.vendor_id             supplier_id
,      v.vendor_number                  supplier_num
,      v.vendor_name                    supplier_name
,      v.vendor_type_lookup_code        supplier_type
,      s.terms_name                     terms_name
,      s.tax_code                       invoice_tax_code
,      s.vat_registration_num           vat_registration_num
,      s.vendor_site_code               site_code
,      s.ss_address_line1               address1
,      s.ss_address_line2               address2
,      s.ss_address_line3               address3
,      s.ss_city                        suburb
,      s.ss_state                       state
,      s.ss_zip                         post_code
,      s.ss_country                     country
,      s.ss_payment_method_code         payment_method
,      b.bank_account_name              bank_account_name
,      b.bank_number                    bank_number
,      b.branch_number                  branch_number
,      b.bank_account_num               bank_account_num
,      s.ss_remit_advice_email          remittance_email
,      s.ss_remit_advice_deliv_meth     notification_method
,      c.c_first_name                   contact_first_name
,      c.c_last_name                    contact_last_name
,      c.c_person_title                 contact_title
,      c.c_email_address                contact_email
,      c.c_phone_area_code              contact_ph_area_code
,      c.c_phone_number                 contact_ph_number
,      c.c_fax_area_code                contact_fax_area_code
,      c.c_fax_number                   contact_fax_number
from   vend v
,      site s
,      cont c
,      bank b
where  v.vendor_id = s.vendor_id (+)
and    s.vendor_id = b.vendor_id (+)
and    s.vendor_site_id = b.vendor_site_id (+)
and    s.vendor_id = c.vendor_id (+)
and    s.vendor_site_id = c.vendor_site_id (+)
and    nvl(b.bank_priority,-1) = (select nvl(min(bank_priority),-1)
                                  from   bank b2
                                  where  b2.vendor_id = b.vendor_id
                                  and    b2.vendor_site_id = b.vendor_site_id)
order by 3,1,2,4,5,6,7,8,9,10,11,12,13;