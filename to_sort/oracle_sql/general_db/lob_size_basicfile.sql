declare  
    l_segment_name          varchar2(30); 
    l_segment_size_blocks   number; 
    l_segment_size_bytes    number; 
    l_used_blocks           number;  
    l_used_bytes            number;  
    l_expired_blocks        number;  
    l_expired_bytes         number;  
    l_unexpired_blocks      number;  
    l_unexpired_bytes       number;
    

   l_unformatted_blocks    NUMBER;
   l_unformatted_bytes     NUMBER;
   l_fs1_blocks            NUMBER;
   l_fs1_bytes             NUMBER;
   l_fs2_blocks            NUMBER;
   l_fs2_bytes             NUMBER;
   l_fs3_blocks            NUMBER;
   l_fs3_bytes             NUMBER;
   l_fs4_blocks            NUMBER;
   l_fs4_bytes             NUMBER;
   l_full_blocks           NUMBER;
   l_full_bytes            NUMBER;

begin
    select segment_name 
    into l_segment_name 
    from dba_lobs 
    where table_name = 'DWTEST2'; 
    
   dbms_output.put_line('Segment Name=' || l_segment_name);
 
    dbms_space.space_usage
      (segment_owner           => 'APPS'
      ,segment_name            => l_segment_name
      ,segment_type            => 'LOB'
      ,partition_name          => NULL
      ,unformatted_blocks => l_unformatted_blocks
      ,unformatted_bytes => l_unformatted_bytes
      ,fs1_blocks  => l_fs1_blocks
      ,fs1_bytes   => l_fs1_bytes
      ,fs2_blocks  => l_fs2_blocks
      ,fs2_bytes   => l_fs2_bytes
      ,fs3_blocks  => l_fs3_blocks
      ,fs3_bytes   => l_fs3_bytes
      ,fs4_blocks  => l_fs4_blocks
      ,fs4_bytes   => l_fs4_bytes
      ,full_blocks => l_full_blocks
      ,full_bytes  => l_full_bytes
      );   

    dbms_output.put_line('unformatted_blocks       => '||  l_unformatted_blocks);
    dbms_output.put_line('unformatted_bytes        => '||  l_unformatted_bytes);
    dbms_output.put_line('fs1_blocks               => '||  l_fs1_blocks);
    dbms_output.put_line('fs1_bytes                => '||  l_fs1_bytes);
    dbms_output.put_line('fs2_blocks               => '||  l_fs2_blocks);
    dbms_output.put_line('fs2_bytes                => '||  l_fs2_bytes);
    dbms_output.put_line('fs3_blocks               => '||  l_fs3_blocks);
    dbms_output.put_line('fs3_bytes                => '||  l_fs3_bytes);
    dbms_output.put_line('fs4_blocks               => '||  l_fs4_blocks);
    dbms_output.put_line('fs4_bytes                => '||  l_fs4_bytes);
    dbms_output.put_line('full_blocks              => '||  l_full_blocks);
    dbms_output.put_line('full_bytes               => '||  l_full_bytes);
    
end;