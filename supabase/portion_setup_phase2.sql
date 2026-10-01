-- Run order (Supabase SQL Editor): 1) inmu_import.sql -> 2) catalog_cleanup.sql -> 3) food_search_names.sql -> 4) portion_setup_phase2.sql -> 5) add_doh_foods.sql -> 6) food_photos.sql
-- FitFast phase 2: realistic portions for common Thai dishes.
-- Run in Supabase SQL Editor after food_servings_setup.sql and
-- catalog_cleanup.sql. Safe to re-run.
--
-- Sources
--   [S1] Nutritional Content of Popular Menu Items from Online Food Delivery
--        Applications in Bangkok, Thailand: Are They Healthy?
--        Int J Environ Res Public Health 2023;20(5):3992.
--        https://doi.org/10.3390/ijerph20053992
--        Each menu was ordered and weighed 15 times (Table 2: mean, min–max).
--   Nutrient values stay per 100 g edible portion (Thai FCD, INMU).

-- ---------------------------------------------------------------------------
-- 1) Extra serving details used by the app (older app versions ignore them).
alter table public.food_servings add column if not exists is_default boolean not null default false;
alter table public.food_servings add column if not exists is_estimate boolean not null default false;
alter table public.food_servings add column if not exists grams_min numeric check (grams_min is null or grams_min > 0);
alter table public.food_servings add column if not exists grams_max numeric check (grams_max is null or grams_max <= 5000);

-- ---------------------------------------------------------------------------
-- 2) Measured plate and bowl weights from [S1].
with measured(food_code, label, grams, grams_min, grams_max, note) as (
  values
    ('T59',     '1 จาน', 291, 230, 370, 'ข้าวมันไก่'),
    ('T48',     '1 จาน', 453, 350, 600, 'ข้าวขาหมู'),
    ('T64',     '1 จาน', 355, 150, 475, 'ข้าวหมูแดง'),
    ('T56',     '1 จาน', 344, 260, 425, 'ข้าวผัด'),
    ('T205',    '1 จาน', 344, 260, 425, 'ข้าวผัด'),
    ('T204',    '1 จาน', 344, 260, 425, 'ข้าวผัด'),
    ('T54',     '1 จาน', 397, 280, 512, 'ใช้น้ำหนักข้าวกะเพราหมูสับ'),
    ('T68',     '1 ชาม', 578, 490, 760, 'โจ๊กหมู'),
    ('T3',      '1 ชาม', 635, 480, 800, 'ก๋วยจั๊บ'),
    ('T10',     '1 ชาม', 628, 427, 857, 'เย็นตาโฟ'),
    ('T231',    '1 จาน', 302, 230, 400, 'ส้มตำไทย'),
    ('T103',    '1 จาน', 313, 240, null, 'ส้มตำปูปลาร้า'),
    ('T101',    '1 จาน', 241, 180, 330, 'ใช้น้ำหนักลาบหมู')
),
-- Group averages for similar dishes that [S1] did not weigh:
-- rice plates = mean of 9 Thai rice plates (359 g),
-- noodle soups = mean of 3 noodle soups (626 g).
estimated(food_code, label, grams, note) as (
  values
    ('T199', '1 จาน', 359, 'ข้าวราด'), ('T200', '1 จาน', 359, 'ข้าวราด'),
    ('T206', '1 จาน', 359, 'ข้าวราด'), ('T207', '1 จาน', 359, 'ข้าวราด'),
    ('T43',  '1 จาน', 359, 'ข้าวราด'), ('T44',  '1 จาน', 359, 'ข้าวราด'),
    ('T45',  '1 จาน', 359, 'ข้าวราด'), ('T46',  '1 จาน', 359, 'ข้าวราด'),
    ('T65',  '1 จาน', 359, 'ข้าวราด'),
    ('T105', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'), ('T107', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'),
    ('T112', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'), ('T114', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'),
    ('T115', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'), ('T119', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'),
    ('T122', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'), ('T123', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'),
    ('T125', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'), ('T127', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'),
    ('T153', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'), ('T154', '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ'),
    ('T92',  '1 ชาม', 626, 'ก๋วยเตี๋ยวน้ำ')
),
all_rows as (
  select food_code, label, grams, grams_min, grams_max, false as is_estimate,
         'งานวิจัยชั่งเมนูสั่งออนไลน์ กทม. (IJERPH 2023)' as source_name
  from measured
  union all
  select food_code, label, grams, null, null, true,
         'ค่าเฉลี่ย' || note || ' จากงานวิจัยชั่งเมนู กทม. (IJERPH 2023)'
  from estimated
),
targets as (
  select f.id as food_id, r.*
  from all_rows r
  join public.foods_catalog f on f.food_code = r.food_code
),
updated as (
  update public.food_servings fs
  set grams = t.grams, grams_min = t.grams_min, grams_max = t.grams_max,
      is_estimate = t.is_estimate, is_default = true, verified = true,
      source_name = t.source_name,
      source_url = 'https://doi.org/10.3390/ijerph20053992'
  from targets t
  where fs.food_id = t.food_id and fs.label = t.label
  returning fs.food_id, fs.label
)
insert into public.food_servings
  (food_id, label, grams, grams_min, grams_max, is_estimate, is_default,
   verified, source_name, source_url)
select t.food_id, t.label, t.grams, t.grams_min, t.grams_max, t.is_estimate,
       true, true, t.source_name, 'https://doi.org/10.3390/ijerph20053992'
from targets t
where not exists (
  select 1 from public.food_servings fs
  where fs.food_id = t.food_id and fs.label = t.label
);

-- ---------------------------------------------------------------------------
-- 3) "1 ช้อนกินข้าว = 15 g" of meat (กรมอนามัย).
--    food_servings_setup.sql matched names starting with "เนื้อไก่/เนื้อหมู/...",
--    but Thai FCD names read "ไก่, เนื้อ, ...". The spoon unit therefore landed
--    only on T362 ปลาหมึกเส้นปรุงรส, G70 ปลาหมึกกรอบ and G189 เนื้อหัวกุ้ง.
--    Hide those (not deleted) and attach the unit to plain cooked meat and fish.
update public.food_servings fs
set verified = false
from public.foods_catalog f
where fs.food_id = f.id
  and f.food_code in ('T362', 'G70', 'G189')
  and fs.label = '1 ช้อนกินข้าว';

insert into public.food_servings
  (food_id, label, grams, verified, source_name, source_url)
select f.id, '1 ช้อนกินข้าว', 15, true,
       'กรมอนามัย กระทรวงสาธารณสุข',
       'https://nutrition2.anamai.moph.go.th/th/book/download/?did=194287&id=46803&reload='
from public.foods_catalog f
where f.is_usable = true
  and f.food_code in (
    'F12',  -- ไก่, น่อง, ต้ม
    'F20',  -- ไก่, สะโพก, ต้ม
    'F23',  -- ไก่, ปีก, ต้ม
    'F130', -- ไก่, ตุ๋น
    'G9',   -- กุ้งกุลาดำ, ต้ม (usable after catalog_cleanup.sql)
    'G48',  -- ปลาช่อน, ต้ม
    'G74',  -- ปลาดุกอุย, ต้ม
    'G78',  -- ปลาตะเพียนขาว, ต้ม
    'G126'  -- ปลาสวาย, ต้ม
  )
  and not exists (
    select 1 from public.food_servings fs
    where fs.food_id = f.id and fs.label = '1 ช้อนกินข้าว'
  );

-- ---------------------------------------------------------------------------
-- 4) Check the result.
select f.food_code, f.name_th, fs.label, fs.grams, fs.grams_min, fs.grams_max,
       fs.is_default, fs.is_estimate,
       round(f.energy_kcal_per_100g * fs.grams / 100) as kcal_per_serving
from public.food_servings fs
join public.foods_catalog f on f.id = fs.food_id
where fs.verified = true
order by fs.is_estimate, f.food_code;
