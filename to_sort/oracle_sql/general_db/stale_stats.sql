--  Source: https://jonathanlewis.wordpress.com/2013/01/01/stale-stats/
--  Usage: 
--  select * from table(stats_required('list stale'[,{schema}));

create or replace function stats_required(
    i_status    in  varchar2    default 'LIST AUTO',
    i_schema    in  varchar2    default user
)
return dbms_stats.ObjectTab pipelined
as
    pragma autonomous_transaction;
    m_objects   dbms_stats.ObjectTab;
begin
    if upper(i_status) not in (
        'LIST AUTO', 'LIST STALE', 'LIST EMPTY'
    ) then
        return;
    end if;
 
    if i_schema is null then
        dbms_stats.gather_database_stats(
            options => i_status,
            objlist => m_objects
        );
    else
        dbms_stats.gather_schema_stats(
            ownname => i_schema,
            options => i_status,
            objlist => m_objects
        );
    end if;
    commit;
 
    for i in 1..m_objects.count loop
        pipe row(m_objects(i));
    end loop;
 
    return;
 
end;
/

