select
        endpoint_number,
        (endpoint_number - nvl(prev_endpoint,0))  frequency,
        (endpoint_number - nvl(prev_endpoint,0)) / max_endpoint_number  perc,
        ROUND(582841*((endpoint_number - nvl(prev_endpoint,0)) / max_endpoint_number)) rough_opt_est,
        chr(to_number(substr(hex_val, 2,2),'XX')) ||
        chr(to_number(substr(hex_val, 4,2),'XX')) ||
        chr(to_number(substr(hex_val, 6,2),'XX')) ||
        chr(to_number(substr(hex_val, 8,2),'XX')) ||
        chr(to_number(substr(hex_val,10,2),'XX')) ||
        chr(to_number(substr(hex_val,12,2),'XX')) val,
        endpoint_actual_value
from    (
        select
                endpoint_number,
                MAX(endpoint_number) OVER (PARTITION BY 1) max_endpoint_number,
                lag(endpoint_number,1) over(
                        order by endpoint_number
                )                                                       prev_endpoint,
                to_char(endpoint_value,'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')hex_val,
                endpoint_actual_value
        from
                dba_tab_histograms
        where owner = 'OLIVE'
        and table_name = 'ARC_PCAMPAIGNID_WOODSTOCK' and column_name = 'IS_MKTG_CODE'
        )
order by
        endpoint_number
;
