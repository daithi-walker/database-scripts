/* GL CODE COMBINATIONS
WRITTEN BY DANIEL NORTH,  ORAFINAPPS LIMITED 2007
GL CODE COMBINATIONS EXTRACT. CAN BE SELECT BY CHART OF ACCOUNTS, SPECIFIC SEGMENT VALUES OR SPECIFIC CODE COMBINATION ATTRIBUTES.
THIS CAN BE USED FOR CHART OF ACCOUNTS MAINTENANCE AND REVIEW
(TESTED ON VISION 11.5.10.2  JUNE 2007 )*/
SELECT FST.ID_FLEX_STRUCTURE_NAME
,    GCC.SEGMENT1||'-'||GCC.SEGMENT2||'-'||GCC.SEGMENT3||'-'||GCC.SEGMENT4||'-'||GCC.SEGMENT5||'-'||GCC.SEGMENT6
,   GCC.CODE_COMBINATION_ID
,   GCC.LAST_UPDATE_DATE
,   GCC.JGZZ_RECON_FLAG
,   GCC.START_DATE_ACTIVE
,   GCC.END_DATE_ACTIVE  
,   GCC.DETAIL_POSTING_ALLOWED_FLAG
,   GCC.ENABLED_FLAG
,   GCC.SUMMARY_FLAG
,   GCC.START_DATE_ACTIVE
FROM GL_CODE_COMBINATIONS GCC
,    FND_ID_FLEX_STRUCTURES_VL FST
WHERE FST.ID_FLEX_NUM = GCC.CHART_OF_ACCOUNTS_ID
AND FST.APPLICATION_ID = 101
AND FST.ID_FLEX_CODE = 'GL#'
--AND GCC.SEGMENT1 IN ('25','26','30')
--AND SUBSTR(FST.ID_FLEX_STRUCTURE_NAME,1,2) IN ('ES','BE','LU')
--AND GCC.SEGMENT4 = '99901'
ORDER BY 1,2,3