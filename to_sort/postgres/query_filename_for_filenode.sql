with    x as (select a.n from generate_series(1, 10000000) as a(n))
select  x.n filenode
,       pg_filenode_relation(0, x.n)  relation
from    x
where   1=1
and     x.n = 11905
and     pg_filenode_relation(0, x.n) is not null
;