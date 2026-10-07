-- ============================================================
-- English Class Manager — Supabase Database Setup
-- Run this entire script in the Supabase SQL Editor
-- ============================================================

-- ─────────────────────────────────────────────
-- EXTENSIONS
-- ─────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────
-- 1. PROFILES
--    One row per authenticated user (teacher)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name     TEXT        NOT NULL DEFAULT '',
  avatar_url    TEXT,
  phone         TEXT,
  email         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create a profile row when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- RLS — Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles: owner can view own"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles: owner can update own"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ─────────────────────────────────────────────
-- 2. BRANCHES
--    Teaching locations / centres
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.branches (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id  UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  address     TEXT,
  color       TEXT        NOT NULL DEFAULT '#3D5AFE',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS — Branches
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "branches: owner select"
  ON public.branches FOR SELECT
  USING (auth.uid() = teacher_id);

CREATE POLICY "branches: owner insert"
  ON public.branches FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "branches: owner update"
  ON public.branches FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "branches: owner delete"
  ON public.branches FOR DELETE
  USING (auth.uid() = teacher_id);

-- ─────────────────────────────────────────────
-- 3. PROGRAMS
--    Course / class programs (e.g. IELTS, TOEIC)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.programs (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  branch_id     UUID        REFERENCES public.branches(id) ON DELETE SET NULL,
  name          TEXT        NOT NULL,
  description   TEXT,
  -- Recurring weekdays: array of ISO weekday numbers 1=Mon … 7=Sun
  weekdays      INT[]       NOT NULL DEFAULT '{}',
  -- HH:MM strings
  start_time    TEXT        NOT NULL DEFAULT '08:00',
  end_time      TEXT        NOT NULL DEFAULT '10:00',
  -- Fee per session in VND
  fee_per_session NUMERIC   NOT NULL DEFAULT 0,
  -- Salary per session for teacher
  salary_per_session NUMERIC NOT NULL DEFAULT 0,
  color         TEXT        NOT NULL DEFAULT '#3D5AFE',
  is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS — Programs
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "programs: owner select"
  ON public.programs FOR SELECT
  USING (auth.uid() = teacher_id);

CREATE POLICY "programs: owner insert"
  ON public.programs FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "programs: owner update"
  ON public.programs FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "programs: owner delete"
  ON public.programs FOR DELETE
  USING (auth.uid() = teacher_id);

-- ─────────────────────────────────────────────
-- 4. STUDENTS
--    Enrolled students per program
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.students (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id  UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  program_id  UUID        NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
  full_name   TEXT        NOT NULL,
  phone       TEXT,
  parent_phone TEXT,
  email       TEXT,
  date_of_birth DATE,
  notes       TEXT,
  is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS — Students
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

CREATE POLICY "students: owner select"
  ON public.students FOR SELECT
  USING (auth.uid() = teacher_id);

CREATE POLICY "students: owner insert"
  ON public.students FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "students: owner update"
  ON public.students FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "students: owner delete"
  ON public.students FOR DELETE
  USING (auth.uid() = teacher_id);

-- ─────────────────────────────────────────────
-- 5. SESSIONS
--    Individual class meetings with attendance
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sessions (
  id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id      UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  program_id      UUID        NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
  session_date    DATE        NOT NULL,
  start_time      TEXT        NOT NULL,   -- HH:MM
  end_time        TEXT        NOT NULL,   -- HH:MM
  topic           TEXT,
  notes           TEXT,
  -- Salary actually earned for this session (may differ from program default)
  salary_earned   NUMERIC     NOT NULL DEFAULT 0,
  is_cancelled    BOOLEAN     NOT NULL DEFAULT FALSE,
  cancel_reason   TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS — Sessions
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sessions: owner select"
  ON public.sessions FOR SELECT
  USING (auth.uid() = teacher_id);

CREATE POLICY "sessions: owner insert"
  ON public.sessions FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "sessions: owner update"
  ON public.sessions FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "sessions: owner delete"
  ON public.sessions FOR DELETE
  USING (auth.uid() = teacher_id);

-- ─────────────────────────────────────────────
-- 6. ATTENDANCE
--    Per-student attendance record for each session
-- ─────────────────────────────────────────────
CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'excused');

CREATE TABLE IF NOT EXISTS public.attendance (
  id          UUID               PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id  UUID               NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_id  UUID               NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  student_id  UUID               NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  status      attendance_status  NOT NULL DEFAULT 'present',
  note        TEXT,
  created_at  TIMESTAMPTZ        NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ        NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, student_id)
);

-- RLS — Attendance
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "attendance: owner select"
  ON public.attendance FOR SELECT
  USING (auth.uid() = teacher_id);

CREATE POLICY "attendance: owner insert"
  ON public.attendance FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "attendance: owner update"
  ON public.attendance FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "attendance: owner delete"
  ON public.attendance FOR DELETE
  USING (auth.uid() = teacher_id);

-- ─────────────────────────────────────────────
-- 7. SALARY_RECORDS
--    Monthly salary summary per program
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.salary_records (
  id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id      UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  program_id      UUID        NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
  month           INT         NOT NULL CHECK (month BETWEEN 1 AND 12),
  year            INT         NOT NULL,
  sessions_taught INT         NOT NULL DEFAULT 0,
  total_salary    NUMERIC     NOT NULL DEFAULT 0,
  is_paid         BOOLEAN     NOT NULL DEFAULT FALSE,
  paid_at         TIMESTAMPTZ,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (teacher_id, program_id, month, year)
);

-- RLS — Salary Records
ALTER TABLE public.salary_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "salary_records: owner select"
  ON public.salary_records FOR SELECT
  USING (auth.uid() = teacher_id);

CREATE POLICY "salary_records: owner insert"
  ON public.salary_records FOR INSERT
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "salary_records: owner update"
  ON public.salary_records FOR UPDATE
  USING (auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "salary_records: owner delete"
  ON public.salary_records FOR DELETE
  USING (auth.uid() = teacher_id);

-- ─────────────────────────────────────────────
-- 8. UPDATED_AT TRIGGERS (auto-maintain timestamps)
-- ─────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'profiles', 'branches', 'programs',
    'students', 'sessions', 'attendance', 'salary_records'
  ]
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%1$s_updated_at ON public.%1$s;
       CREATE TRIGGER trg_%1$s_updated_at
         BEFORE UPDATE ON public.%1$s
         FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();',
      tbl
    );
  END LOOP;
END;
$$;

-- ─────────────────────────────────────────────
-- 9. HELPFUL INDEXES
-- ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_branches_teacher     ON public.branches(teacher_id);
CREATE INDEX IF NOT EXISTS idx_programs_teacher     ON public.programs(teacher_id);
CREATE INDEX IF NOT EXISTS idx_programs_branch      ON public.programs(branch_id);
CREATE INDEX IF NOT EXISTS idx_students_teacher     ON public.students(teacher_id);
CREATE INDEX IF NOT EXISTS idx_students_program     ON public.students(program_id);
CREATE INDEX IF NOT EXISTS idx_sessions_teacher     ON public.sessions(teacher_id);
CREATE INDEX IF NOT EXISTS idx_sessions_program     ON public.sessions(program_id);
CREATE INDEX IF NOT EXISTS idx_sessions_date        ON public.sessions(session_date);
CREATE INDEX IF NOT EXISTS idx_attendance_session   ON public.attendance(session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student   ON public.attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_salary_teacher_month ON public.salary_records(teacher_id, year, month);

-- ─────────────────────────────────────────────
-- DONE
-- ─────────────────────────────────────────────
-- Tables created:
--   profiles, branches, programs, students,
--   sessions, attendance, salary_records
-- All tables have RLS enabled with per-owner policies.
-- Run this script once in Supabase SQL Editor → Run.
