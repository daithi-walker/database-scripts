declare
    ty      varchar2(100);
    lvr     varchar2(100);
    hvr     varchar2(100);
    lvd     date;
    hvd     date;
    lvn     number;
    hvn     number;
    lvv     varchar2(100);
    hvv     varchar2(100);
begin 

    select  utc.data_type
    ,       utc.low_value
    ,       utc.high_value
    into    ty
    ,       lvr
    ,       hvr
    from    user_tab_columns  utc
    where   1=1
    and     utc.table_name  = upper('mis_cmo_fact_metrics_goo')
    and     utc.column_name = upper('date_of_activity');

    if ty = upper('date') then
        dbms_stats.convert_raw_value(lvr,lvd);
        lvv := to_char(lvd);
        dbms_stats.convert_raw_value(hvr,hvd);
        hvv := to_char(hvd);
    elsif ty = upper('number') then
        dbms_stats.convert_raw_value(lvr,lvn); 
        lvv := to_char(lvn);
        dbms_stats.convert_raw_value(hvr,hvn); 
        hvv := to_char(hvn);
    elsif ty = upper('varchar2') then
        dbms_stats.convert_raw_value(lvr,lvv); 
        dbms_stats.convert_raw_value(hvr,hvv); 
    else  
        dbms_output.put_line('unsupported type'); 
    end if;

    dbms_output.put_line('low_value: ' || lvv); 
    dbms_output.put_line('high_value: ' || hvv);

end;