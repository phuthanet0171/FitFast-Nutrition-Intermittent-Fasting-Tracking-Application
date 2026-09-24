-- Optional catalog photos; does not change existing foods or access policies.
alter table public.foods_catalog add column if not exists image_url text;
