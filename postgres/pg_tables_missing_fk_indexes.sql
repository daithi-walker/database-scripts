-- Original Source:
-- http://mlawire.blogspot.co.uk/2009/08/postgresql-indexes-on-foreign-keys.html

/*
  Look for foreign key constraints that are missing indexes on the
  referencing table.

  Orders results by the size of the referencing table, largest first,
  on the assumption that, all else being equal, they are the most likely
  to benefit from the addition of indexes.

  This is only meant as a starting point, and isn't perfect.
  It's possible, for example, that it will report a missing index
  when in fact one is available. e.g., it won't realize that an index on
  (f1, f2) could be used with a fk on (f1). However, it will recognize
  that an index on (f1, f2) can be used with a fk on (f2, f1).

  Usage: psql -q dbname -f pg-find-missing-fk-indexes.sql
*/

CREATE FUNCTION pg_temp.sortarray(int2[]) returns int2[]
AS  '
    SELECT  ARRAY
            (
            SELECT  $1[i]
            FROM    generate_series(array_lower($1, 1), array_upper($1, 1)) i
            ORDER BY 1
            )
    '
LANGUAGE SQL;

SELECT  pn.nspname
,       pco.conrelid::regclass  AS "table_name"
,       pco.conname            AS "constrant_name"
,       pcl.reltuples::bigint  AS "num_rows"
FROM    pg_constraint pco
,       pg_class pcl
,       pg_namespace pn
WHERE   1=1
AND     pcl.oid = pco.conrelid
AND     pn.oid = pcl.relnamespace
AND     pco.contype = 'f'
AND     NOT EXISTS
        (
        SELECT  1
        FROM    pg_index pi
        WHERE   1=1
        AND     pi.indrelid = pco.conrelid
        --AND     pg_temp.sortarray(pco.conkey) = pg_temp.sortarray(pi.indkey)  -- if using function above.
        AND     pco.conkey::int[] <@ pi.indkey::int[]
         -- remove this line to relax the condition. with a lighter
         -- condition you can treat the cases of columns of FK 
         -- included in an index covering more columns.
        AND     pco.conkey::int[] @> pi.indkey::int[]
        )
ORDER BY pcl.reltuples DESC
;