REM LOCATION:   Object Management\Tables\Utilities
REM FUNCTION:   Display the recommended Oracle segment space maintenance actions.
REM TESTED ON:  11.1.0.6 only
REM PLATFORM:   non-specific
REM REQUIRES:   Uses dbms_space.asa_recommendations Oracle supplied package.
REM NOTE:       Wild cards in the segment_owner and segment_name will not work since
REM             we are using a table function.
REM
REM             Note that rebuilding a table using the shrink space command
REM             requires that row movement be enabled. This can result in indexes
REM             becoming UNUSABLE and needing to be rebuilt.
REM
REM             Note that the commands in the second SQL (c1,c2,c3) may be duplicate
REM             commands. Often, you only need to run the first two commands listed.
REM
REM             Note that the segment space advisor (the souce of this data) sometimes
REM             will generate recommendations on segments that can not be shrunk with
REM             the shrink space command, such as tables with function based indexes.
REM
REM  This is a part of the Knowledge Xpert for Oracle Administration library.
REM  Copyright (C) 2008 Quest Software
REM  All rights reserved.
REM
REM ******************** Knowledge Xpert for Oracle Administration ********************
REM First we will display a list of objects that need reorganization

--UNDEF ENTER_TABLE_OWNER
--UNDEF ENTER_TABLE_NAME

COLUMN recommendations format a130 wrap
COLUMN c3 format a80 wrap heading 'Run Me Frist'
COLUMN c2 format a80 wrap heading 'Run Me Second'
COLUMN c1 format a80 wrap heading 'Run Me Last |(May not be required)'

SET lines 132 pages 66 echo off feedback off verify off

TTITLE left _date center 'Report of Table Rebuild Candidates' skip 2

SELECT 	segment_owner
, 		segment_name
, 		segment_type
, 		partition_name
, 		recommendations
, 		c3 || ';' c3
, 		c2 || ';' c2
, 		c1 || ';' c1
FROM 	TABLE (DBMS_SPACE.asa_recommendations ('FALSE', 'FALSE', 'FALSE'))
WHERE 	1=1
--AND 	segment_type = 'TABLE'
-- Comment out these last two lines if you want all schemas/tables.
--AND 	segment_owner = UPPER ('&&ENTER_TABLE_OWNER')
--AND 	segment_name = UPPER ('&&ENTER_TABLE_NAME')
 ;
