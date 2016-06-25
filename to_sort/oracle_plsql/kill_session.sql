create or replace procedure kill_session( p_sid in number, p_serial# in number )
as
begin
    for x in ( select *
                 from v$session 
                where username = USER
                  and sid = p_sid
                  and serial# = p_serial# )
    loop
        execute immediate 'alter system kill session ''' || 
                 p_sid || ',' || p_serial# || '''';
        dbms_output.put_line( 'Alter session done' );
    end loop;
end;