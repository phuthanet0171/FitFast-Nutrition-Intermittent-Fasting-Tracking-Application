-- Run once in Supabase SQL Editor before using detailed meal components.
-- Existing meal history is preserved; old rows receive an empty component list.
alter table public.meal_entries
add column if not exists components jsonb not null default '[]'::jsonb;

comment on column public.meal_entries.components is
'Snapshot of detailed food components and nutrients at logging time';
