SELECT   DISTINCT 
         fa.asset_number
,        fa.description
,        fa.asset_type
,        fak.segment1 asset_key1
,        fak.segment2 asset_key2
,        fak.segment3 asset_key3
,        fc.segment1 major_category
,        fc.segment2 minor_category
,        fbv.deprn_method_code
,        fbv.life_in_months/12 life
,        fbv.book_type_code
,        fbv.date_placed_in_service
,        fbv.depreciate_flag
,        fbv.cost
,        fdh.units_assigned UNITS
,        gcc.segment1 COMPANY
,        gcc.segment2 DEPARTMENT
,        gcc.segment3 ACCOUNT
,        fl.segment1 country
,        fl.segment2 state
,        fl.segment3 city
,        fl.segment4 building
FROM     fa_additions fa
,        fa_books_v fbv
,        fa_categories fc
,        fa_asset_keywords fak
,        gl_code_combinations gcc
,        fa_distribution_history fdh
,        fa_locations fl
WHERE    1=1
AND      fa.asset_id = fbv.asset_id
AND      fa.asset_id = fdh.asset_id
AND      fa.asset_category_id = fc.category_id
AND      fdh.code_combination_id = gcc.code_combination_id
AND      fdh.location_id = fl.location_id
AND      fa.asset_key_ccid = fak.code_combination_id
AND      fbv.book_type_code LIKE 'DOEHLG CORP'
AND      fdh.transaction_header_id_out IS NULL;