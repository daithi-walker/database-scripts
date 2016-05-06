select * from pg_matviews;

-- pg_matviews definition
SELECT
    c.oid,
    N.nspname AS schemaname,
    C.relname AS matviewname,
    pg_get_userbyid(C.relowner) AS matviewowner,
    T.spcname AS tablespace,
    C.relhasindex AS hasindexes,
    C.relispopulated AS ispopulated
    --pg_get_viewdef(C.oid) AS definition
FROM pg_class C
LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
LEFT JOIN pg_tablespace T ON (T.oid = C.reltablespace)
WHERE C.relkind = 'm'
and pg_get_userbyid(C.relowner) = 'olive'
and C.relname = 'draft_planline_report'
;