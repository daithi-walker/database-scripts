

select dbms_stats.create_extended_stats('sanfran','mis_arc_dt_kw_activity_marin','(aie_activity_type_new,aie_activity_sub_type_new)') from dual;
--begin dbms_stats.gather_Table_stats('sanfran','mis_arc_dt_kw_activity_marin'); end;
--begin dbms_stats.gather_index_stats('sanfran','MIS_ARC_DT_KW_ACT_MARIN_IX_SD'); end;

begin
 dbms_stats.drop_extended_stats('sanfran','mis_arc_dt_kw_activity_marin','(aie_activity_type_new,aie_activity_sub_type_new)');
end;