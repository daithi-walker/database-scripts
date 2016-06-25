select   aerha.report_header_id
,        aerha.invoice_num
,        aerha.description
,        papf.full_name employee
,        aerha.override_approver_name
,        aer.report_type
,        aerla.report_line_id
,        aerla.merchant_name
,        aerla.amount
,        aerla.item_description
,        aerla.line_type_lookup_code
from     ap_expense_report_headers_all@apps_ebus aerha
,        ap_expense_report_lines_all@apps_ebus aerla
,        per_all_people_f@apps_ebus papf
,        ap_expense_reports_all@apps_ebus aer
where    1=1
--and      aerha.report_header_id = :report_header_id --403516
and      aerha.invoice_num = :invoice_num --'SW380282'
and      aerla.report_header_id = aerha.report_header_id
and      aerha.employee_id = papf.person_id
--and      papf.last_name = :last_name --'Estrada'
and      aer.expense_report_id = aerha.expense_report_id
order by aerha.report_header_id desc
,        aerla.report_line_id;