create table entries (
  id uuid primary key default gen_random_uuid(),
  anonymous_name text not null,
  today_mm bigint not null,
  total_mm bigint not null,
  best_day_mm bigint not null,
  days_tracked int not null,
  milestone text,
  created_at timestamptz not null default now()
);

alter table entries enable row level security;

create policy "Anyone can insert" on entries for insert to anon with check (true);
create policy "Anyone can read" on entries for select to anon using (true);

create index idx_entries_name_created on entries (anonymous_name, created_at desc);
create index idx_entries_created on entries (created_at desc);
