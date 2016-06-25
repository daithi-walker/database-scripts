SELECT   aud.creation_date                   audit_creation_date
,        categories.user_je_category_name    category
,        aud.doc_sequence_value              doc_number
,        aud.doc_sequence_id                 doc_sequence_id
,        DECODE(headers.name,NULL,:DELETED_MSG,:ENTERED_MSG) status
,        headers.name                        header_name
,        headers.currency_code               currency_code
,        batches.name                        batch_name
,        lookups.description                 posting_status
,        headers.posted_date                 posted_date
,        headers.running_total_dr            debits
,        headers.running_total_cr            credits
,        seq.name                            sequence_name
,        seq.doc_sequence_id                 seq_sequence_id
,        seq.db_sequence_name                seq_db_name
,        seq.initial_value                   initial_value
,        seq.type                            type
FROM     gl_lookups                          lookups
,        gl_je_categories                    categories
,        gl_je_batches                       batches
,        gl_je_headers                       headers
,        gl_doc_sequence_audit               aud
,        fnd_document_sequences              seq
WHERE    1=1
AND      lookups.lookup_type(+) = 'MJE_BATCH_STATUS'
AND      lookups.lookup_code(+) = headers.status
AND      categories.je_category_name(+) = headers.je_category
AND      batches.je_batch_id(+) = headers.je_batch_id
AND      headers.doc_sequence_value(+) = aud.doc_sequence_value
AND      headers.doc_sequence_id(+) = aud.doc_sequence_id
AND      headers.parent_je_header_id IS NULL
AND      aud.doc_sequence_value BETWEEN NVL(:P_SEQUENCE_FROM,aud.doc_sequence_value) AND NVL(:P_SEQUENCE_TO,aud.doc_sequence_value)
AND      aud.doc_sequence_id = seq.doc_sequence_id
AND      seq.type IN ('A','G')
AND      headers.set_of_books_id = :P_SET_OF_BOOKS_ID  -- 20140912 - DWALKER (V1)
AND      batches.set_of_books_id = :P_SET_OF_BOOKS_ID  -- 20140912 - DWALKER (V1)
AND      batches.set_of_books_id = headers.set_of_books_id  -- 20140912 - DWALKER (V1)
ORDER BY seq.name
,        aud.doc_sequence_value