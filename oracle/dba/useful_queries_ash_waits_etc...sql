--Source: https://www.brentozar.com/archive/2015/03/tables-used-oracle/

SELECT  vss.owner,
        vss.object_name,
        vss.subobject_name,
        vss.object_type ,
        vss.tablespace_name ,
        SUM(CASE statistic_name WHEN 'logical reads' THEN value ELSE 0 END
            + CASE statistic_name WHEN 'physical reads' THEN value ELSE 0 END) AS reads ,
        SUM(CASE statistic_name WHEN 'logical reads' THEN value ELSE 0 END) AS logical_reads ,
        SUM(CASE statistic_name WHEN 'physical reads' THEN value ELSE 0 END) AS physical_reads ,
        SUM(CASE statistic_name WHEN 'segment scans' THEN value ELSE 0 END) AS segment_scans ,
        SUM(CASE statistic_name WHEN 'physical writes' THEN value ELSE 0 END) AS writes
FROM    v$segment_statistics vss
WHERE   vss.owner NOT IN ('SYS', 'SYSTEM')
GROUP BY vss.owner,
        vss.object_name ,
        vss.object_type ,
        vss.subobject_name ,
        vss.tablespace_name
ORDER BY reads DESC;

SELECT  vs.username ,
        vsw.wait_class,
        vsw.EVENT AS wait_type ,
        vsw.WAIT_TIME_MICRO / 1000 AS wait_time_ms ,
        vsw.TIME_REMAINING_MICRO / 1000 AS time_remaining_ms ,
        vsw.STATE ,
        de.SEGMENT_NAME ,
        de.SEGMENT_TYPE, 
        de.OWNER ,
        de.TABLESPACE_NAME
FROM    V$SESSION_WAIT vsw
        JOIN V$SESSION vs ON vsw.SID = vs.SID
        LEFT JOIN DBA_EXTENTS de ON vsw.p1 = de.file_id
                                    AND vsw.p2 BETWEEN de.BLOCK_ID AND (de.BLOCK_ID + de.BLOCKS)
WHERE   vsw.wait_class <> 'Idle'
        AND vs.username IS NOT NULL 
ORDER BY wait_time_ms DESC;

SELECT  du.username,
        s.sql_text, 
        MAX(ash.sample_time) AS last_access ,
        sp.object_owner ,
        sp.object_name ,
        sp.object_alias as aliased_as ,
        sp.object_type ,
        COUNT(*) AS access_count 
FROM    v$active_session_history ash
        JOIN v$sql s ON ash.force_matching_signature = s.force_matching_signature
        LEFT JOIN v$sql_plan sp ON s.sql_id = sp.sql_id
        JOIN DBA_USERS du ON ash.user_id = du.USER_ID
WHERE   ash.session_type = 'FOREGROUND' 
        AND ash.SQL_ID IS NOT NULL
        AND sp.object_name IS NOT NULL
        AND ash.user_id <> 0
GROUP BY du.username, 
        s.sql_text, 
        sp.object_owner, 
        sp.object_name, 
        sp.object_alias, 
        sp.object_type 
ORDER BY 3 DESC;
