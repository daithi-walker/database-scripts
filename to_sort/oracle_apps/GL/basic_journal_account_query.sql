/* R12 */
SELECT   GJL.PERIOD_NAME
,        SOB.LEDGER_ID
,        SOB.SHORT_NAME SOB_SHORT_NAME
,        GJH.JE_SOURCE
,        GJH.JE_CATEGORY
--,        GJH.NAME
,        GJH.CURRENCY_CODE
,        GCC.SEGMENT1||'-'||GCC.SEGMENT2||'-'||GCC.SEGMENT3||'-'||GCC.SEGMENT4||'-'||GCC.SEGMENT5||'-'||GCC.SEGMENT6||'-'||GCC.SEGMENT7 ACCOUNT
,        SUM(GJL.ENTERED_DR) ENTERED_DR
,        SUM(GJL.ENTERED_CR) ENTERED_DR
,        SUM(GJL.ACCOUNTED_DR) ACCOUNTED_DR
,        SUM(GJL.ACCOUNTED_CR) ACCOUNTED_DR
FROM     GL_JE_LINES GJL
,        GL_JE_HEADERS GJH
,        GL_CODE_COMBINATIONS GCC
,        GL_LEDGERS SOB
WHERE    1=1
AND      GJL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
AND      GJL.JE_HEADER_ID = GJH.JE_HEADER_ID
AND      GJL.LEDGER_ID = GJH.LEDGER_ID
AND      SOB.LEDGER_ID = GJH.LEDGER_ID
AND      SOB.LEDGER_ID = GJL.LEDGER_ID
AND      GJH.ACTUAL_FLAG = 'A'
AND      GJH.STATUS = 'P'
AND      GJH.PERIOD_NAME IN ('Jan-14')
--and gcc.segment1 = '5710'
--and gcc.segment2 = '20027'
--and gcc.segment3 = '06201'
--and gcc.segment4 = '000000'
--and gcc.segment5 = '0000'
--and gcc.segment6 = 'L00104'
--and gcc.segment7 = '00000000'
GROUP BY GJL.PERIOD_NAME
,        SOB.LEDGER_ID
,        SOB.SHORT_NAME
,        GJH.JE_SOURCE
,        GJH.JE_CATEGORY
--,        GJH.NAME
,        GJH.CURRENCY_CODE
,        GCC.SEGMENT1||'-'||GCC.SEGMENT2||'-'||GCC.SEGMENT3||'-'||GCC.SEGMENT4||'-'||GCC.SEGMENT5||'-'||GCC.SEGMENT6||'-'||GCC.SEGMENT7
ORDER BY SUBSTR(GJL.PERIOD_NAME,-2)
,        SUBSTR(GJL.PERIOD_NAME,1,3)
,        SOB.LEDGER_ID
,        GJH.CURRENCY_CODE
,        GJH.JE_SOURCE
,        GJH.JE_CATEGORY
,        GCC.SEGMENT1||'-'||GCC.SEGMENT2||'-'||GCC.SEGMENT3||'-'||GCC.SEGMENT4||'-'||GCC.SEGMENT5||'-'||GCC.SEGMENT6||'-'||GCC.SEGMENT7

/* 11i */
SELECT   GJL.PERIOD_NAME
,        SOB.SHORT_NAME SOB_SHORT_NAME
,        GJH.JE_SOURCE
,        GJH.NAME
,        GJH.CURRENCY_CODE
,        GCC.SEGMENT1||'-'||GCC.SEGMENT2||'-'||GCC.SEGMENT3||'-'||GCC.SEGMENT4||'-'||GCC.SEGMENT5||'-'||GCC.SEGMENT6||'-'||GCC.SEGMENT7||'-'||GCC.SEGMENT8||'-'||GCC.SEGMENT9 "ACCOUNT"
,        GJL.ACCOUNTED_DR
,        GJL.ACCOUNTED_CR
FROM     GL_JE_LINES GJL
,        GL_JE_HEADERS GJH
,        GL_CODE_COMBINATIONS GCC
,        GL_SETS_OF_BOOKS SOB
WHERE    1=1
AND      GJL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
AND      GJL.JE_HEADER_ID = GJH.JE_HEADER_ID
AND      GJL.SET_OF_BOOKS_ID = GJH.SET_OF_BOOKS_ID
AND      SOB.SET_OF_BOOKS_ID = GJH.SET_OF_BOOKS_ID
AND      SOB.SET_OF_BOOKS_ID = GJL.SET_OF_BOOKS_ID
AND      SOB.SET_OF_BOOKS_ID = 2
AND      GJH.ACTUAL_FLAG = 'A'
AND      GJH.STATUS = 'P'
AND      GJH.PERIOD_NAME IN ('Week52-13'
                            ,'Week53-13'
                            ,'Week54-13'
                            ,'Week55-13'
                            ,'Week56-13'
                            ,'Week01-14'
                            ,'Week02-14'
                            ,'Week03-14'
                            ,'Week04-14'
                            ,'Week05-14'
                            ,'Week06-14'
                            ,'Week07-14'
                            ,'Week08-14'
                            )
ORDER BY SUBSTR(GJL.PERIOD_NAME,-2)
,        SUBSTR(GJL.PERIOD_NAME,1,6)
,        GJH.CURRENCY_CODE
,        GJH.JE_SOURCE
,        GCC.SEGMENT1||'-'||GCC.SEGMENT2||'-'||GCC.SEGMENT3||'-'||GCC.SEGMENT4||'-'||GCC.SEGMENT5||'-'||GCC.SEGMENT6||'-'||GCC.SEGMENT7||'-'||GCC.SEGMENT8||'-'||GCC.SEGMENT9