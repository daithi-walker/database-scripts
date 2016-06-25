select   a.applied_patch_id
,        a.patch_name
,        a.patch_type
,        b.patch_driver_id
,        b.driver_file_name
,        b.orig_patch_name
,        b.creation_date
,        b.platform
,        b.source_code
,        b.creation_date
,        b.file_size
,        b.merged_driver_flag
,        b.merge_date
from     ad_applied_patches a
,        ad_patch_drivers b
where    1=1
and      a.applied_patch_id = b.applied_patch_id
--and      a.patch_name = ''
order by b.creation_date desc