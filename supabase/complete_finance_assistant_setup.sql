-- Budgex - Complete Supabase Finance Assistant Setup
-- Run this in Supabase Dashboard > SQL Editor.
-- It is safe for an existing app: it creates missing tables/columns, indexes, triggers, RLS policies and receipt storage.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  currency text not null default 'PKR',
  monthly_budget numeric(12,2) not null default 0 check (monthly_budget >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles add column if not exists currency text not null default 'PKR';
alter table public.profiles add column if not exists monthly_budget numeric(12,2) not null default 0 check (monthly_budget >= 0);
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz not null default now();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, currency, monthly_budget)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), nullif(new.raw_user_meta_data ->> 'name', ''), split_part(new.email, '@', 1)),
    'PKR',
    0
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Categories
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null,
  icon_name text not null default 'category',
  color_hex text not null default '#607D8B',
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index if not exists categories_default_name_unique
on public.categories (lower(name)) where user_id is null;

create unique index if not exists categories_user_name_unique
on public.categories (user_id, lower(name)) where user_id is not null;

create index if not exists categories_user_id_idx on public.categories(user_id);

insert into public.categories (name, icon_name, color_hex, is_default)
values
  ('Food', 'restaurant', '#FF9800', true),
  ('Transport', 'directions_bus', '#2196F3', true),
  ('Bills', 'receipt_long', '#F44336', true),
  ('Shopping', 'shopping_bag', '#9C27B0', true),
  ('Health', 'local_hospital', '#4CAF50', true),
  ('Entertainment', 'movie', '#3F51B5', true),
  ('Other', 'category', '#607D8B', true)
on conflict do nothing;

-- Category-wise budgets
create table if not exists public.category_budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  monthly_limit numeric(12,2) not null check (monthly_limit >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, category_id)
);

drop trigger if exists category_budgets_set_updated_at on public.category_budgets;
create trigger category_budgets_set_updated_at
before update on public.category_budgets
for each row execute function public.set_updated_at();

create index if not exists category_budgets_user_idx on public.category_budgets(user_id);

-- Recurring expenses
create table if not exists public.recurring_expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  title text not null check (char_length(trim(title)) >= 2),
  amount numeric(12,2) not null check (amount > 0),
  payment_method text not null default 'Cash' check (payment_method in ('Cash', 'Card', 'Bank Transfer', 'Wallet')),
  frequency text not null check (frequency in ('daily', 'weekly', 'monthly', 'yearly')),
  next_due_date date not null,
  note text check (note is null or char_length(note) <= 250),
  is_active boolean not null default true,
  auto_post boolean not null default true,
  last_generated_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.recurring_expenses add column if not exists auto_post boolean not null default true;
alter table public.recurring_expenses add column if not exists last_generated_date date;

drop trigger if exists recurring_expenses_set_updated_at on public.recurring_expenses;
create trigger recurring_expenses_set_updated_at
before update on public.recurring_expenses
for each row execute function public.set_updated_at();

create index if not exists recurring_expenses_user_due_idx on public.recurring_expenses(user_id, next_due_date);

-- Expenses
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  title text not null check (char_length(trim(title)) >= 2),
  amount numeric(12,2) not null check (amount > 0),
  expense_date date not null default current_date,
  note text check (note is null or char_length(note) <= 250),
  payment_method text not null default 'Cash' check (payment_method in ('Cash', 'Card', 'Bank Transfer', 'Wallet')),
  receipt_url text,
  recurring_expense_id uuid references public.recurring_expenses(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.expenses add column if not exists receipt_url text;
alter table public.expenses add column if not exists recurring_expense_id uuid references public.recurring_expenses(id) on delete set null;

drop trigger if exists expenses_set_updated_at on public.expenses;
create trigger expenses_set_updated_at
before update on public.expenses
for each row execute function public.set_updated_at();

create index if not exists expenses_user_date_idx on public.expenses(user_id, expense_date desc);
create index if not exists expenses_user_category_idx on public.expenses(user_id, category_id);
create index if not exists expenses_user_payment_idx on public.expenses(user_id, payment_method);
create index if not exists expenses_user_recurring_idx on public.expenses(user_id, recurring_expense_id, expense_date);

-- Income tracking
create table if not exists public.incomes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) >= 2),
  amount numeric(12,2) not null check (amount > 0),
  income_date date not null default current_date,
  source text not null default 'Salary' check (source in ('Salary', 'Business', 'Freelance', 'Gift', 'Investment', 'Other')),
  note text check (note is null or char_length(note) <= 250),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists incomes_set_updated_at on public.incomes;
create trigger incomes_set_updated_at
before update on public.incomes
for each row execute function public.set_updated_at();

create index if not exists incomes_user_date_idx on public.incomes(user_id, income_date desc);
create index if not exists incomes_user_source_idx on public.incomes(user_id, source);

-- Goals / savings tracker
create table if not exists public.savings_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) >= 2),
  target_amount numeric(12,2) not null check (target_amount > 0),
  saved_amount numeric(12,2) not null default 0 check (saved_amount >= 0),
  target_date date,
  note text check (note is null or char_length(note) <= 250),
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists savings_goals_set_updated_at on public.savings_goals;
create trigger savings_goals_set_updated_at
before update on public.savings_goals
for each row execute function public.set_updated_at();

create index if not exists savings_goals_user_idx on public.savings_goals(user_id, is_completed, target_date);

-- Optional unified transaction view for future reporting / assistant logic.
create or replace view public.finance_transactions as
select
  e.id,
  e.user_id,
  'expense'::text as type,
  e.title,
  e.amount,
  e.expense_date as transaction_date,
  e.category_id,
  c.name as category_name,
  e.payment_method,
  null::text as source,
  e.note,
  e.created_at
from public.expenses e
left join public.categories c on c.id = e.category_id
union all
select
  i.id,
  i.user_id,
  'income'::text as type,
  i.title,
  i.amount,
  i.income_date as transaction_date,
  null::uuid as category_id,
  null::text as category_name,
  null::text as payment_method,
  i.source,
  i.note,
  i.created_at
from public.incomes i;

grant select on public.finance_transactions to authenticated;

-- Receipt image bucket. Public is true because the app stores a public receipt_url.
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', true)
on conflict (id) do update set public = true;

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.expenses enable row level security;
alter table public.category_budgets enable row level security;
alter table public.incomes enable row level security;
alter table public.recurring_expenses enable row level security;
alter table public.savings_goals enable row level security;

-- Profiles policies
drop policy if exists profiles_select_own on public.profiles;
drop policy if exists profiles_insert_own on public.profiles;
drop policy if exists profiles_update_own on public.profiles;

create policy profiles_select_own on public.profiles for select to authenticated using (auth.uid() = id);
create policy profiles_insert_own on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy profiles_update_own on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Categories policies
drop policy if exists categories_select_default_or_own on public.categories;
drop policy if exists categories_insert_own on public.categories;
drop policy if exists categories_update_own on public.categories;
drop policy if exists categories_delete_own on public.categories;

create policy categories_select_default_or_own on public.categories for select to authenticated using (is_default = true or user_id = auth.uid());
create policy categories_insert_own on public.categories for insert to authenticated with check (user_id = auth.uid() and is_default = false);
create policy categories_update_own on public.categories for update to authenticated using (user_id = auth.uid() and is_default = false) with check (user_id = auth.uid() and is_default = false);
create policy categories_delete_own on public.categories for delete to authenticated using (user_id = auth.uid() and is_default = false);

-- Expenses policies
drop policy if exists expenses_select_own on public.expenses;
drop policy if exists expenses_insert_own on public.expenses;
drop policy if exists expenses_update_own on public.expenses;
drop policy if exists expenses_delete_own on public.expenses;

create policy expenses_select_own on public.expenses for select to authenticated using (user_id = auth.uid());
create policy expenses_insert_own on public.expenses for insert to authenticated with check (user_id = auth.uid());
create policy expenses_update_own on public.expenses for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy expenses_delete_own on public.expenses for delete to authenticated using (user_id = auth.uid());

-- Category budget policies
drop policy if exists category_budgets_select_own on public.category_budgets;
drop policy if exists category_budgets_insert_own on public.category_budgets;
drop policy if exists category_budgets_update_own on public.category_budgets;
drop policy if exists category_budgets_delete_own on public.category_budgets;

create policy category_budgets_select_own on public.category_budgets for select to authenticated using (user_id = auth.uid());
create policy category_budgets_insert_own on public.category_budgets for insert to authenticated with check (user_id = auth.uid());
create policy category_budgets_update_own on public.category_budgets for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy category_budgets_delete_own on public.category_budgets for delete to authenticated using (user_id = auth.uid());

-- Income policies
drop policy if exists incomes_select_own on public.incomes;
drop policy if exists incomes_insert_own on public.incomes;
drop policy if exists incomes_update_own on public.incomes;
drop policy if exists incomes_delete_own on public.incomes;

create policy incomes_select_own on public.incomes for select to authenticated using (user_id = auth.uid());
create policy incomes_insert_own on public.incomes for insert to authenticated with check (user_id = auth.uid());
create policy incomes_update_own on public.incomes for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy incomes_delete_own on public.incomes for delete to authenticated using (user_id = auth.uid());

-- Recurring expenses policies
drop policy if exists recurring_expenses_select_own on public.recurring_expenses;
drop policy if exists recurring_expenses_insert_own on public.recurring_expenses;
drop policy if exists recurring_expenses_update_own on public.recurring_expenses;
drop policy if exists recurring_expenses_delete_own on public.recurring_expenses;

create policy recurring_expenses_select_own on public.recurring_expenses for select to authenticated using (user_id = auth.uid());
create policy recurring_expenses_insert_own on public.recurring_expenses for insert to authenticated with check (user_id = auth.uid());
create policy recurring_expenses_update_own on public.recurring_expenses for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy recurring_expenses_delete_own on public.recurring_expenses for delete to authenticated using (user_id = auth.uid());

-- Savings goals policies
drop policy if exists savings_goals_select_own on public.savings_goals;
drop policy if exists savings_goals_insert_own on public.savings_goals;
drop policy if exists savings_goals_update_own on public.savings_goals;
drop policy if exists savings_goals_delete_own on public.savings_goals;

create policy savings_goals_select_own on public.savings_goals for select to authenticated using (user_id = auth.uid());
create policy savings_goals_insert_own on public.savings_goals for insert to authenticated with check (user_id = auth.uid());
create policy savings_goals_update_own on public.savings_goals for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy savings_goals_delete_own on public.savings_goals for delete to authenticated using (user_id = auth.uid());

-- Storage policies for receipts bucket
drop policy if exists receipts_read_own on storage.objects;
drop policy if exists receipts_insert_own on storage.objects;
drop policy if exists receipts_update_own on storage.objects;
drop policy if exists receipts_delete_own on storage.objects;

create policy receipts_read_own on storage.objects
for select to authenticated
using (bucket_id = 'receipts' and auth.uid()::text = (storage.foldername(name))[1]);

create policy receipts_insert_own on storage.objects
for insert to authenticated
with check (bucket_id = 'receipts' and auth.uid()::text = (storage.foldername(name))[1]);

create policy receipts_update_own on storage.objects
for update to authenticated
using (bucket_id = 'receipts' and auth.uid()::text = (storage.foldername(name))[1])
with check (bucket_id = 'receipts' and auth.uid()::text = (storage.foldername(name))[1]);

create policy receipts_delete_own on storage.objects
for delete to authenticated
using (bucket_id = 'receipts' and auth.uid()::text = (storage.foldername(name))[1]);

-- Sanity checks after running:
-- select name, is_default from public.categories order by is_default desc, name;
-- select table_name from information_schema.tables where table_schema = 'public' order by table_name;
