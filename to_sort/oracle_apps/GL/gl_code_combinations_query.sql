SELECT   code_combination_id
,        chart_of_accounts_id
,        account_type
,        segment1||'-'||segment2||'-'||segment3||'-'||segment4||'-'||segment5||'-'||segment6 ccid
,        case
            when  to_char(last_update_date,'yyyy')= '2013' then
               'Y'
            else
               'N'
         end updated_2013
,        gl_flexfields_pkg.get_description_sql
         (gccl.chart_of_accounts_id,
         1,
         gccl.segment1
         ) seg1_desc
,        gl_flexfields_pkg.get_description_sql
         (gccl.chart_of_accounts_id,
         2,
         gccl.segment2
         ) seg2_desc
,        gl_flexfields_pkg.get_description_sql
         (gccl.chart_of_accounts_id,
         3,
         gccl.segment3
         ) seg3_desc
,        gl_flexfields_pkg.get_description_sql
         (gccl.chart_of_accounts_id,
         4,
         gccl.segment4
         ) seg4_desc
,        gl_flexfields_pkg.get_description_sql
         (gccl.chart_of_accounts_id,
         5,
         gccl.segment5
         ) seg5_desc
,        gl_flexfields_pkg.get_description_sql
         (gccl.chart_of_accounts_id,
         6,
         gccl.segment6
         ) seg6_desc
FROM     gl_code_combinations gccl;