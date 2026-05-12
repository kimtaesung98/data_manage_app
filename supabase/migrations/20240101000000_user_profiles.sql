-- ============================================================
-- Migration: user_profiles
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. Table ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nickname    TEXT,
  avatar_url  TEXT,
  updated_at  TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Keep updated_at current automatically
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 2. Row Level Security -------------------------------------------
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- SELECT: own row only
CREATE POLICY "profiles_select_own"
  ON public.user_profiles FOR SELECT
  USING (auth.uid() = id);

-- INSERT: own row only
CREATE POLICY "profiles_insert_own"
  ON public.user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- UPDATE: own row only
CREATE POLICY "profiles_update_own"
  ON public.user_profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- DELETE: own row only
CREATE POLICY "profiles_delete_own"
  ON public.user_profiles FOR DELETE
  USING (auth.uid() = id);

-- 3. Realtime (optional) ------------------------------------------
-- Allow the table to be used with Supabase Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_profiles;
