-- PO_RELEASES view
SELECT   ATTRIBUTE5
,        ATTRIBUTE6
, ATTRIBUTE7
, ATTRIBUTE8
, ATTRIBUTE9
, ATTRIBUTE10
, ATTRIBUTE11
, ATTRIBUTE12
, ATTRIBUTE13
, ATTRIBUTE14
, ATTRIBUTE15
, AUTHORIZATION_STATUS
, USSGL_TRANSACTION_CODE
, GOVERNMENT_CONTEXT
, REQUEST_ID
, PROGRAM_APPLICATION_ID
, PROGRAM_ID
, PROGRAM_UPDATE_DATE
, CLOSED_CODE
, FROZEN_FLAG
, RELEASE_TYPE
, NOTE_TO_VENDOR
, ORG_ID
, PO_RELEASE_ID
, LAST_UPDATE_DATE
, LAST_UPDATED_BY
, PO_HEADER_ID
, RELEASE_NUM , AGENT_ID , RELEASE_DATE , LAST_UPDATE_LOGIN , CREATION_DATE , CREATED_BY , REVISION_NUM , REVISED_DATE , APPROVED_FLAG , APPROVED_DATE , PRINT_COUNT , PRINTED_DATE , ACCEPTANCE_REQUIRED_FLAG , ACCEPTANCE_DUE_DATE , HOLD_BY , HOLD_DATE , HOLD_REASON , HOLD_FLAG , CANCEL_FLAG , CANCELLED_BY , CANCEL_DATE , CANCEL_REASON , FIRM_STATUS_LOOKUP_CODE , FIRM_DATE , ATTRIBUTE_CATEGORY , ATTRIBUTE1 , ATTRIBUTE2 , ATTRIBUTE3 , ATTRIBUTE4 ,EDI_PROCESSED_FLAG ,GLOBAL_ATTRIBUTE_CATEGORY ,GLOBAL_ATTRIBUTE1 ,GLOBAL_ATTRIBUTE2 ,GLOBAL_ATTRIBUTE3 ,GLOBAL_ATTRIBUTE4 ,GLOBAL_ATTRIBUTE5 ,GLOBAL_ATTRIBUTE6 ,GLOBAL_ATTRIBUTE7 ,GLOBAL_ATTRIBUTE8 ,GLOBAL_ATTRIBUTE9 ,GLOBAL_ATTRIBUTE10 ,GLOBAL_ATTRIBUTE11 ,GLOBAL_ATTRIBUTE12 ,GLOBAL_ATTRIBUTE13 ,GLOBAL_ATTRIBUTE14 ,GLOBAL_ATTRIBUTE15 ,GLOBAL_ATTRIBUTE16 ,GLOBAL_ATTRIBUTE17 ,GLOBAL_ATTRIBUTE18 ,GLOBAL_ATTRIBUTE19 ,GLOBAL_ATTRIBUTE20 ,WF_ITEM_TYPE ,WF_ITEM_KEY ,PCARD_ID ,PAY_ON_CODE ,XML_FLAG ,XML_SEND_DATE ,XML_CHANGE_SEND_DATE ,CONSIGNED_CONSUMPTION_FLAG ,CBC_ACCOUNTING_DATE ,CHANGE_REQUESTED_BY ,SHIPPING_CONTROL ,CHANGE_SUMMARY ,VENDOR_ORDER_NUM ,DOCUMENT_CREATION_METHOD ,SUBMIT_DATE
FROM     PO_RELEASES_ALL
WHERE    1=1
AND      NVL(ORG_ID,NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1), ' ', NULL, SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)) = NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1), ' ', NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)