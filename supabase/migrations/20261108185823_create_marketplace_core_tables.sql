create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories(id) on delete set null,
  name_ar text not null,
  name_en text not null,
  slug text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint categories_name_ar_not_blank check (length(trim(name_ar)) > 0),
  constraint categories_name_en_not_blank check (length(trim(name_en)) > 0),
  constraint categories_slug_not_blank check (length(trim(slug)) > 0)
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  title text not null,
  description text,
  price numeric not null,
  currency text not null default 'EGP',
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  constraint products_title_not_blank check (length(trim(title)) > 0),
  constraint products_price_check check (price >= 0),
  constraint products_currency_code check (currency ~ '^[A-Z]{3}$'),
  constraint products_status_check check (status in ('draft', 'published', 'archived'))
);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  storage_path text not null unique,
  alt_text text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint product_images_storage_path_not_blank check (length(trim(storage_path)) > 0)
);

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
