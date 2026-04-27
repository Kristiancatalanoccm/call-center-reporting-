-- TFU AI Reporting Dashboard — Single Agency
-- Run in: Supabase Dashboard > SQL Editor > New query

-- 1. Profiles (team login, no org isolation)
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  is_admin boolean not null default false,
  created_at timestamptz default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2. Clients (no org isolation)
create table if not exists clients (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz default now()
);

-- 3. Events
create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id) on delete cascade,
  event_type text not null,
  occurred_at timestamptz default now(),
  duration_seconds int,
  is_pickup boolean,
  is_conversation boolean,
  speed_to_lead_seconds numeric,
  ghl_contact_id text,
  raw jsonb,
  constraint events_event_type_check check (
    event_type in ('dial', 'lead', 'appointment_booked', 'show', 'no_show', 'callback_booked')
  )
);

-- 4. Ad Spend (local_services added as platform)
create table if not exists ad_spend (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id) on delete cascade,
  spend_date date not null,
  platform text not null,
  amount numeric not null default 0,
  created_at timestamptz default now(),
  constraint ad_spend_platform_check check (platform in ('meta', 'google', 'local_services')),
  unique(client_id, spend_date, platform)
);

-- 5. Indexes
create index if not exists events_client_occurred on events(client_id, occurred_at desc);
create index if not exists events_type on events(event_type);
create index if not exists ad_spend_client_date on ad_spend(client_id, spend_date desc);
