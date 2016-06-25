SELECT adoc.creation_date Creation_date
,docs.last_update_date
,docs.document_id
,adoc.attached_document_id
,docs.category_id
,DECODE (docs.datatype_id,1,docs_tl.media_id,NULL) text_Id 
,docs.datatype_id
,adoc.pk1_value Contract_Number
,docs_tl.doc_attribute2 file_size
,adoc.automatically_added_flag
,adoc.created_by
,DECODE (docs.datatype_id,5,docs_tl.file_name,NULL) link_Url
,docs_tl.LANGUAGE 
,DECODE (docs.datatype_id,6,docs_tl.file_name,NULL) File_Name
,docs_tl.description
,doc_s_text.short_text
,DECODE (docs.datatype_id,6,docs_tl.media_id,NULL) fileId
,docs.publish_flag
,docs_tl.file_name
FROM fnd_attached_documents adoc
,fnd_documents docs
,fnd_documents_tl docs_tl
,fnd_documents_short_text doc_s_text
WHERE 1 = 1
AND adoc.document_id = docs.document_id
AND docs.document_id = docs_tl.document_id
AND docs_tl.LANGUAGE = USERENV (‘LANG’)
AND docs_tl.media_id = doc_s_text.media_id(+)
AND adoc.entity_name = 'OKC_K_HEADERS_V'
AND pk1_value = '1081665' -- Enter your contract number here.

Very large files are stored in the fnd_lobs table

To check the attached file in fnd_lobs table

1. Note Document ID from above query.
2. Take media ID for this document ID from fnd_documents_tl table.
3. run following query:
select * from fnd_lobs where file_id = (media id from 2nd query)