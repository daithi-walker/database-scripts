rem
rem     Script:         dbms_space_use.sql
rem     Author:         Jonathan Lewis
rem     Dated:          Nov 2002
rem     Purpose:
rem
rem     Last tested 
rem             12.1.0.1
rem             11.2.0.4
rem             11.1.0.7
rem             10.2.0.3
rem              9.2.0.8
rem     Not tested
rem             10.2.0.5
rem     Not relevant
rem              8.1.7.4
rem
rem     Notes:
rem     For accuracy in free space you (once) needed to set the
rem     scan limit; and for those rare objects cases where you 
rem     had defined multiple freelist groups you still have to
rem     work through each free list group in turn
rem
rem     For the ASSM calls:
rem             FS1     => 0% - 25% free space
rem             FS2     => 25% - 50% free space
rem             FS3     => 50% - 75% free space
rem             FS4     => 75% - 100% free space
rem             Bytes = blocks * block size
rem
rem     Expected errors:
rem             ORA-10614: Operation not allowed on this segment
rem                     (MSSM segment, ASSM call)
rem             ORA-10618: Operation not allowed on this segment
rem                     (ASSM segment, MSSM call)
rem             ORA-03200: the segment type specification is invalid
rem                     (e.g. for LOBINDEX or LOBSEGMENT)
rem                     11g - "LOB" is legal for LOB segments
rem                         - use "INDEX" for the LOBINDEX
rem
rem     For indexes
rem             Blocks are FULL or FS2 (re-usable)
rem
rem     Special case: LOB segments.
rem     The number of blocks reported by FS1 etc. is actually the
rem     number of CHUNKS in use (and they're full or empty). So 
rem     if your CHUNK size is not the same as your block size the
rem     total "blocks" used doesn't match the number of blocks 
rem     below the HWM.
rem
rem     The package dbms_space is created by dbmsspu.sql
rem     and the body is in prvtspcu.plb
rem
rem     11.2 overloads dbms_space.space_usage for securefile lobs
rem     See dbms_space_use_sf.sql
rem

set verify off
set serveroutput on

define m_seg_owner      = &1
define m_seg_name       = &2
define m_seg_type       = &3

define m_segment_owner  = &m_seg_owner
define m_segment_name   = &m_seg_name
define m_segment_type   = &m_seg_type

@@setenv

spool dbms_space_use

prompt  ===================
prompt  Freelist management
prompt  ===================

declare
        wrong_ssm       exception;
        pragma exception_init(wrong_ssm, -10618);

        m_free  number(10);
begin
        dbms_space.free_blocks(
                segment_owner           => upper('&m_segment_owner'),
                segment_name            => upper('&m_segment_name'),
                segment_type            => upper('&m_segment_type'),
--              partition_name          => null,
--              scan_limit              => 50,
                freelist_group_id       => 0,
                free_blks               => m_free
        );
        dbms_output.put_line('Free blocks below HWM: ' || m_free);
exception
        when wrong_ssm then
                dbms_output.put_line('Segment not freelist managed');
end;
/


prompt  ====
prompt  ASSM
prompt  ====

declare
        wrong_ssm       exception;
        pragma exception_init(wrong_ssm, -10614);

        m_UNFORMATTED_BLOCKS    number;
        m_UNFORMATTED_BYTES     number;
        m_FS1_BLOCKS            number;
        m_FS1_BYTES             number;
        m_FS2_BLOCKS            number;  
        m_FS2_BYTES             number;

        m_FS3_BLOCKS            number;
        m_FS3_BYTES             number;
        m_FS4_BLOCKS            number; 
        m_FS4_BYTES             number;
        m_FULL_BLOCKS           number;
        m_FULL_BYTES            number;

begin
        dbms_space.SPACE_USAGE(
                upper('&m_segment_owner'),
                upper('&m_segment_name'),
                upper('&m_segment_type'),
--              PARTITION_NAME                  => null,
                m_UNFORMATTED_BLOCKS,
                m_UNFORMATTED_BYTES, 
                m_FS1_BLOCKS , 
                m_FS1_BYTES,
                m_FS2_BLOCKS,  
                m_FS2_BYTES,
                m_FS3_BLOCKS,  
                m_FS3_BYTES,
                m_FS4_BLOCKS,  
                m_FS4_BYTES,
                m_FULL_BLOCKS, 
                m_FULL_BYTES
        );

        dbms_output.new_line;
        dbms_output.put_line('Unformatted                   : ' || to_char(m_unformatted_blocks,'999,990') || ' / ' || to_char(m_unformatted_bytes,'999,999,990'));
        dbms_output.put_line('Freespace 1 (  0 -  25% free) : ' || to_char(m_fs1_blocks,'999,990') || ' / ' || to_char(m_fs1_bytes,'999,999,990'));
        dbms_output.put_line('Freespace 2 ( 25 -  50% free) : ' || to_char(m_fs2_blocks,'999,990') || ' / ' || to_char(m_fs2_bytes,'999,999,990'));
        dbms_output.put_line('Freespace 3 ( 50 -  75% free) : ' || to_char(m_fs3_blocks,'999,990') || ' / ' || to_char(m_fs3_bytes,'999,999,990'));
        dbms_output.put_line('Freespace 4 ( 75 - 100% free) : ' || to_char(m_fs4_blocks,'999,990') || ' / ' || to_char(m_fs4_bytes,'999,999,990'));
        dbms_output.put_line('Full                          : ' || to_char(m_full_blocks,'999,990') || ' / ' || to_char(m_full_bytes,'999,999,990'));

exception
        when wrong_ssm then
                dbms_output.put_line('Segment not ASSM');
end;
/


prompt  =======
prompt  Generic
prompt  =======

declare
        m_TOTAL_BLOCKS                  number;
        m_TOTAL_BYTES                   number;
        m_UNUSED_BLOCKS                 number;
        m_UNUSED_BYTES                  number;
        m_LAST_USED_EXTENT_FILE_ID      number;
        m_LAST_USED_EXTENT_BLOCK_ID     number;
        m_LAST_USED_BLOCK               number;
begin
        dbms_space.UNUSED_SPACE(
                upper('&m_segment_owner'),
                upper('&m_segment_name'),
                upper('&m_segment_type'),
--              PARTITION_NAME                  => null,
                m_TOTAL_BLOCKS,
                m_TOTAL_BYTES, 
                m_UNUSED_BLOCKS,  
                m_UNUSED_BYTES,
                m_LAST_USED_EXTENT_FILE_ID, 
                m_LAST_USED_EXTENT_BLOCK_ID,
                m_LAST_USED_BLOCK
        );

        dbms_output.put_line('Segment Total blocks: '  || m_total_blocks);
        dbms_output.put_line('Object Unused blocks: '  || m_unused_blocks);

end;
/