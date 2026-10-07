-- ============================================================
-- English Class Manager — SUPABASE FULL SETUP SQL
-- Xoá toàn bộ bảng cũ và tạo lại từ đầu để đồng bộ với App
-- Cảnh báo: Sẽ xoá toàn bộ dữ liệu hiện tại
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Xoá các bảng cũ nếu có (thứ tự quan trọng để không dính foreign key)
DROP TABLE IF EXISTS public.salary_records CASCADE;
DROP TABLE IF EXISTS public.attendance CASCADE;
DROP TABLE IF EXISTS public.sessions CASCADE;
DROP TABLE IF EXISTS public.students CASCADE;
DROP TABLE IF EXISTS public.programs CASCADE;
DROP TABLE IF EXISTS public.branches CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- ─────────────────────────────────────────────
-- 1. PROFILES
-- ─────────────────────────────────────────────
CREATE TABLE public.profiles (
  id                  UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name           TEXT,
  organization_name   TEXT        NOT NULL DEFAULT 'TKCA VN',
  bank_name           TEXT,
  bank_account_name   TEXT,
  bank_account_number TEXT,
  salary_note         TEXT,
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Tự tạo profile khi user đăng ký
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, organization_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    'TKCA VN'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles: owner all" ON public.profiles FOR ALL USING (auth.uid() = id);

-- ─────────────────────────────────────────────
-- 2. BRANCHES
-- ─────────────────────────────────────────────
CREATE TABLE public.branches (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "branches: owner all" ON public.branches FOR ALL USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- 3. PROGRAMS
-- ─────────────────────────────────────────────
CREATE TABLE public.programs (
  id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name                TEXT        NOT NULL,
  default_hourly_rate NUMERIC     NOT NULL DEFAULT 0,
  color_hex           TEXT        NOT NULL DEFAULT '#3D5AFE',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "programs: owner all" ON public.programs FOR ALL USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- 4. STUDENTS
-- ─────────────────────────────────────────────
CREATE TABLE public.students (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  branch_id     UUID        REFERENCES public.branches(id) ON DELETE SET NULL,
  program_id    UUID        REFERENCES public.programs(id) ON DELETE SET NULL,
  name          TEXT        NOT NULL,
  color_hex     TEXT        NOT NULL DEFAULT '#3D5AFE',
  schedule_days JSONB       NOT NULL DEFAULT '[]'::jsonb, -- Lưu mảng int
  start_time    TEXT,
  end_time      TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "students: owner all" ON public.students FOR ALL USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────
-- 5. SESSIONS
-- ─────────────────────────────────────────────
CREATE TABLE public.sessions (
  id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  student_id      UUID        REFERENCES public.students(id) ON DELETE SET NULL,
  branch_name     TEXT        NOT NULL,
  program_name    TEXT        NOT NULL,
  student_name    TEXT        NOT NULL,
  date            DATE        NOT NULL,
  time_slot       TEXT        NOT NULL,
  duration_hours  NUMERIC     NOT NULL DEFAULT 0,
  hourly_rate     NUMERIC     NOT NULL DEFAULT 0,
  total_amount    NUMERIC     NOT NULL DEFAULT 0,
  status          TEXT        NOT NULL DEFAULT 'PENDING',
  is_makeup       BOOLEAN     NOT NULL DEFAULT FALSE,
  color_hex       TEXT        NOT NULL DEFAULT '#3D5AFE',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sessions: owner all" ON public.sessions FOR ALL USING (auth.uid() = user_id);

