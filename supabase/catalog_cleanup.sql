-- Run order (Supabase SQL Editor): 1) inmu_import.sql -> 2) catalog_cleanup.sql -> 3) food_search_names.sql -> 4) portion_setup_phase2.sql -> 5) add_doh_foods.sql -> 6) food_photos.sql
-- FitFast: foods_catalog cleanup. Run in Supabase SQL Editor BEFORE
-- portion_setup_phase2.sql. Only updates rows; nothing is deleted.
-- Each step has a preview SELECT. Run the preview, check it, then the UPDATE.
--
-- Nutrient values are per 100 g edible portion (Thai FCD, INMU Mahidol).
-- Atwater factors used below: protein 4, carbohydrate 4, fat 9 kcal/g.

-- ---------------------------------------------------------------------------
-- 1) Z060082 "ข้าวมันไก่ต้ม" was added by hand without a source and stores a
--    300 g plate (600 kcal) as if it were per 100 g. T59 "ข้าวมัน, ไก่ต้ม" is
--    the Thai FCD entry for the same dish (198 kcal/100 g).
--    Keep T59, convert Z060082 to per 100 g and hide it. (T59 gets a freely
--    licensed photo in food_photos.sql.)
select food_code, name_th, energy_kcal_per_100g, serving_basis_grams,
       is_usable, image_url
from public.foods_catalog
where food_code in ('Z060082', 'T59');

update public.foods_catalog
set energy_kcal_per_100g    = energy_kcal_per_100g    * 100 / serving_basis_grams,
    protein_g_per_100g      = protein_g_per_100g      * 100 / serving_basis_grams,
    carbs_g_per_100g        = carbs_g_per_100g        * 100 / serving_basis_grams,
    fat_g_per_100g          = fat_g_per_100g          * 100 / serving_basis_grams,
    sugar_g_per_100g        = sugar_g_per_100g        * 100 / serving_basis_grams,
    sodium_mg_per_100g      = sodium_mg_per_100g      * 100 / serving_basis_grams,
    fiber_g_per_100g        = fiber_g_per_100g        * 100 / serving_basis_grams,
    cholesterol_mg_per_100g = cholesterol_mg_per_100g * 100 / serving_basis_grams,
    calcium_mg_per_100g     = calcium_mg_per_100g     * 100 / serving_basis_grams,
    iron_mg_per_100g        = iron_mg_per_100g        * 100 / serving_basis_grams,
    serving_basis_grams     = 100
where serving_basis_grams is not null
  and serving_basis_grams > 0
  and serving_basis_grams <> 100;

update public.foods_catalog
set is_usable = false,
    data_quality = 'unusable'
where food_code = 'Z060082';

-- ---------------------------------------------------------------------------
-- 2) Hidden rows that have energy, protein and fat but no carbohydrate.
--    Mostly plain meat, fish, seafood and fruit, e.g. ปลานิล, หมูเนื้อ,
--    วัวเนื้อ, อกไก่, กุ้งกุลาดำ, ปลาหมึก, สตรอเบอร์รี่, แคนตาลูป.
--    Carbohydrate = energy left after protein and fat, divided by 4 (never
--    below 0). Rows where protein + fat alone exceed the stated energy by
--    more than 20% are inconsistent and stay hidden, as are weights that
--    include bone ("รวมกระดูก").
select food_code, name_th, energy_kcal_per_100g as kcal,
       protein_g_per_100g as protein, fat_g_per_100g as fat,
       greatest(0, round((energy_kcal_per_100g
                          - 4 * protein_g_per_100g
                          - 9 * fat_g_per_100g) / 4, 2)) as carbs_estimate
from public.foods_catalog
where is_usable = false
  and carbs_g_per_100g is null
  and energy_kcal_per_100g > 0
  and protein_g_per_100g is not null
  and fat_g_per_100g is not null
  and 4 * protein_g_per_100g + 9 * fat_g_per_100g <= energy_kcal_per_100g * 1.2
  and name_th not like '%รวมกระดูก%'
order by food_code;

update public.foods_catalog
set carbs_g_per_100g = greatest(0, round((energy_kcal_per_100g
                                          - 4 * protein_g_per_100g
                                          - 9 * fat_g_per_100g) / 4, 2)),
    is_usable = true,
    data_quality = 'partial',
    source_name = coalesce(source_name, 'Thai Food Composition Database')
                  || ' · คาร์โบไฮเดรตประมาณจากพลังงานที่เหลือ (FitFast)'
where is_usable = false
  and carbs_g_per_100g is null
  and energy_kcal_per_100g > 0
  and protein_g_per_100g is not null
  and fat_g_per_100g is not null
  and 4 * protein_g_per_100g + 9 * fat_g_per_100g <= energy_kcal_per_100g * 1.2
  and name_th not like '%รวมกระดูก%';

-- ---------------------------------------------------------------------------
-- 3) Hidden rows with protein, carbohydrate and fat but no energy.
--    Energy = 4P + 4C + 9F, the same method already used for G116 and G96.
select food_code, name_th, protein_g_per_100g as protein,
       carbs_g_per_100g as carbs, fat_g_per_100g as fat,
       round(4 * protein_g_per_100g + 4 * carbs_g_per_100g
             + 9 * fat_g_per_100g) as kcal_estimate
from public.foods_catalog
where is_usable = false
  and energy_kcal_per_100g is null
  and protein_g_per_100g is not null
  and carbs_g_per_100g is not null
  and fat_g_per_100g is not null
order by food_code;

update public.foods_catalog
set energy_kcal_per_100g = round(4 * protein_g_per_100g
                                 + 4 * carbs_g_per_100g
                                 + 9 * fat_g_per_100g),
    is_usable = true,
    data_quality = 'partial',
    source_name = coalesce(source_name, 'Thai Food Composition Database')
                  || ' · พลังงานคำนวณด้วยสูตร 4-4-9 (FitFast)'
where is_usable = false
  and energy_kcal_per_100g is null
  and protein_g_per_100g is not null
  and carbs_g_per_100g is not null
  and fat_g_per_100g is not null;

-- K47 เนยขาว (shortening) is pure fat: only fat is listed.
update public.foods_catalog
set protein_g_per_100g = 0,
    carbs_g_per_100g = 0,
    energy_kcal_per_100g = round(9 * fat_g_per_100g),
    is_usable = true,
    data_quality = 'partial',
    source_name = source_name || ' · พลังงานคำนวณจากไขมัน (FitFast)'
where food_code = 'K47'
  and energy_kcal_per_100g is null
  and fat_g_per_100g is not null;

-- ---------------------------------------------------------------------------
-- 4) Result.
select is_usable, count(*) from public.foods_catalog group by is_usable;

select food_code, name_th, energy_kcal_per_100g, protein_g_per_100g,
       carbs_g_per_100g, fat_g_per_100g, source_name
from public.foods_catalog
where source_name like '%(FitFast)%'
order by food_code;
