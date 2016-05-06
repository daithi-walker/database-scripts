select  mp.mpl_pla_id
,       mf.mfd_name
,       mp.mpl_name_in_feed
,       mp.mpl_value_in_feed
from    map_placements mp
,       map_feeds mf
where   1=1
and     mf.mfd_id = mp.mpl_mfd_id
and     mp.mpl_pla_id = :pla_id;