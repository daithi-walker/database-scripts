declare
  
    c_num_tasks constant NUMBER := 30;

    cursor  c_tx
    is
    select  *
    from    (
            select  owner
            ,       segment_name
            ,       segment_type
            ,       bytes/1024/1024/1024 gb
            ,       tablespace_name
            from    dba_segments
            where   1=1
            --and     segment_type = 'INDEX'
            order by 4 desc
            )
    where   1=1
    and     rownum <= c_num_tasks;

    v_id    NUMBER;

begin

    for r_tx in c_tx
    loop
        declare
            name varchar2(100);
            descr varchar2(500);
            obj_id number;
        begin
            --name := CASE r_tx.segment_type
                      --WHEN 'INDEX' THEN 'I'
                      --WHEN 'TABLE' THEN 'T'
                      --ELSE 'X'
                    --END ||'_'||r_tx.tablespace_name||'_'||r_tx.segment_name;
            name := r_tx.segment_name;
            descr:='walkerd';
            
            begin
                dbms_advisor.delete_task(name);
                dbms_output.put_line('task deleted:' || name);
            exception
                when others then
                    null;
            end;

            dbms_advisor.create_task (
                advisor_name     => 'Segment Advisor',
                task_id          => v_id,
                task_name        => name,
                task_desc        => descr
            );

            dbms_advisor.create_object (
                task_name        => name,
                object_type      => r_tx.segment_type,
                attr1            => r_tx.owner,
                attr2            => r_tx.segment_name,
                attr3            => NULL,
                attr4            => NULL,
                attr5            => NULL,
                object_id        => obj_id
            );

            dbms_advisor.set_task_parameter(
                task_name        => name,
                parameter        => 'recommend_all',
                value            => 'TRUE'
            );

            dbms_advisor.execute_task(name);
        
        dbms_output.put_line('Task:'||v_id||'...'||name);

        end;

    end loop;

end;