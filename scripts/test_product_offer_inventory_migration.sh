#!/usr/bin/env bash
set -euo pipefail

migration="supabase/migrations/20261128154942_add_product_inventory_and_offer_acceptance.sql"
test -f "$migration"

psql -v ON_ERROR_STOP=1 <<'SQL'
DO $$ BEGIN
  CREATE ROLE anon NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  CREATE ROLE authenticated NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE SCHEMA IF NOT EXISTS auth;
CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

CREATE TABLE public.products (
  id uuid PRIMARY KEY,
  owner_id uuid NOT NULL,
  title text NOT NULL DEFAULT 'Test product',
  price numeric NOT NULL,
  currency text NOT NULL DEFAULT 'EGP',
  status text NOT NULL DEFAULT 'published',
  has_variants boolean NOT NULL DEFAULT false,
  reserved_by_order_id uuid
);

CREATE TABLE public.product_variants (
  id uuid PRIMARY KEY,
  product_id uuid NOT NULL REFERENCES public.products(id),
  color text,
  size text,
  quantity integer NOT NULL DEFAULT 0
);

CREATE TABLE public.product_offers (
  id uuid PRIMARY KEY,
  product_id uuid NOT NULL REFERENCES public.products(id),
  buyer_id uuid NOT NULL,
  seller_id uuid NOT NULL,
  offered_price numeric NOT NULL,
  currency text NOT NULL DEFAULT 'EGP',
  status text NOT NULL DEFAULT 'pending',
  message text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.product_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id),
  buyer_id uuid NOT NULL,
  seller_id uuid NOT NULL,
  agreed_price numeric NOT NULL,
  currency text NOT NULL DEFAULT 'EGP',
  status text NOT NULL DEFAULT 'pending',
  buyer_note text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  reminder_sent_at timestamptz,
  variant_id uuid,
  quantity integer NOT NULL DEFAULT 1,
  variant_color text,
  variant_size text,
  hold_expires_at timestamptz,
  postponement_requested_at timestamptz,
  postponement_requested_until timestamptz,
  postponement_extension_count integer NOT NULL DEFAULT 0,
  stock_restored_at timestamptz,
  cancellation_reason text,
  cancellation_note text
);

CREATE OR REPLACE FUNCTION public.create_user_notification(
  uuid, text, text, text, jsonb, text
) RETURNS void
LANGUAGE plpgsql
AS $$ BEGIN RETURN; END $$;
SQL

psql -v ON_ERROR_STOP=1 -f "$migration"

psql -v ON_ERROR_STOP=1 <<'SQL'
DO $$
DECLARE
  seller constant uuid := '10000000-0000-0000-0000-000000000001';
  buyer constant uuid := '20000000-0000-0000-0000-000000000001';
  buyer_two constant uuid := '20000000-0000-0000-0000-000000000002';
  product_counter constant uuid := '30000000-0000-0000-0000-000000000001';
  product_original constant uuid := '30000000-0000-0000-0000-000000000002';
  product_direct constant uuid := '30000000-0000-0000-0000-000000000003';
  offer_counter constant uuid := '40000000-0000-0000-0000-000000000001';
  offer_original constant uuid := '40000000-0000-0000-0000-000000000002';
  order_id uuid;
  actual_price numeric;
  actual_quantity integer;
  actual_status text;
BEGIN
  INSERT INTO public.products(id, owner_id, price, quantity)
  VALUES
    (product_counter, seller, 150, 3),
    (product_original, seller, 100, 1),
    (product_direct, seller, 30, 5);

  INSERT INTO public.product_offers(id, product_id, buyer_id, seller_id, offered_price)
  VALUES
    (offer_counter, product_counter, buyer, seller, 90),
    (offer_original, product_original, buyer_two, seller, 75);

  PERFORM set_config('request.jwt.claim.sub', seller::text, true);
  PERFORM public.counter_product_offer(offer_counter, 110, 'Counter price');

  PERFORM set_config('request.jwt.claim.sub', buyer::text, true);
  order_id := public.accept_product_offer(offer_counter);

  SELECT agreed_price, status INTO actual_price, actual_status
  FROM public.product_orders WHERE id = order_id;
  IF actual_price <> 110 OR actual_status <> 'accepted' THEN
    RAISE EXCEPTION 'Counteroffer acceptance failed: price %, status %', actual_price, actual_status;
  END IF;

  SELECT quantity INTO actual_quantity FROM public.products WHERE id = product_counter;
  IF actual_quantity <> 2 THEN
    RAISE EXCEPTION 'Counteroffer did not decrement stock: %', actual_quantity;
  END IF;

  PERFORM set_config('request.jwt.claim.sub', seller::text, true);
  order_id := public.accept_product_offer(offer_original);
  SELECT agreed_price, status INTO actual_price, actual_status
  FROM public.product_orders WHERE id = order_id;
  IF actual_price <> 75 OR actual_status <> 'accepted' THEN
    RAISE EXCEPTION 'Original offer acceptance failed: price %, status %', actual_price, actual_status;
  END IF;

  SELECT quantity, status INTO actual_quantity, actual_status
  FROM public.products WHERE id = product_original;
  IF actual_quantity <> 0 OR actual_status <> 'archived' THEN
    RAISE EXCEPTION 'Single-unit offer acceptance did not exhaust listing: quantity %, status %',
      actual_quantity, actual_status;
  END IF;

  BEGIN
    UPDATE public.products SET condition = 'new' WHERE id = product_original;
    RAISE EXCEPTION 'Reserved listing metadata update unexpectedly succeeded';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  PERFORM set_config('request.jwt.claim.sub', buyer_two::text, true);
  INSERT INTO public.product_orders(product_id, quantity)
  VALUES (product_direct, 3)
  RETURNING id INTO order_id;

  PERFORM set_config('request.jwt.claim.sub', seller::text, true);
  UPDATE public.product_orders SET status = 'accepted' WHERE id = order_id;
  SELECT quantity, status INTO actual_quantity, actual_status
  FROM public.products WHERE id = product_direct;
  IF actual_quantity <> 2 OR actual_status <> 'published' THEN
    RAISE EXCEPTION 'Bulk stock acceptance failed: quantity %, status %', actual_quantity, actual_status;
  END IF;

  UPDATE public.product_orders SET status = 'cancelled' WHERE id = order_id;
  SELECT quantity, status INTO actual_quantity, actual_status
  FROM public.products WHERE id = product_direct;
  IF actual_quantity <> 5 OR actual_status <> 'published' THEN
    RAISE EXCEPTION 'Cancelled order did not restore stock: quantity %, status %',
      actual_quantity, actual_status;
  END IF;
END $$;

DO $
BEGIN
  IF has_function_privilege('anon', 'public.accept_product_offer(uuid)', 'EXECUTE')
     OR has_function_privilege('anon', 'public.counter_product_offer(uuid,numeric,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous role must not execute offer mutation RPCs';
  END IF;
  IF NOT has_function_privilege('authenticated', 'public.accept_product_offer(uuid)', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.counter_product_offer(uuid,numeric,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated role must execute offer mutation RPCs';
  END IF;
  IF has_function_privilege('authenticated', 'public.validate_product_order_status_transition()', 'EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated role must not directly execute the order trigger function';
  END IF;
END $;

SELECT 'product inventory and offer migration tests passed' AS result;
SQL
