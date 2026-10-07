-- XÓA CÁC BẢNG CŨ BỊ SAI CẤU TRÚC
DROP TABLE IF EXISTS public.salary_records CASCADE;
DROP TABLE IF EXISTS public.attendance CASCADE;
DROP TABLE IF EXISTS public.sessions CASCADE;
DROP TABLE IF EXISTS public.students CASCADE;
DROP TABLE IF EXISTS public.programs CASCADE;
DROP TABLE IF EXISTS public.branches CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 1. BẢNG PROFILES
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    organization_name TEXT DEFAULT 'TKCA VN',
    bank_name TEXT,
    bank_account_name TEXT,
    bank_account_number TEXT,
    salary_note TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own profile" ON public.profiles FOR ALL USING (auth.uid() = id);

-- 2. BẢNG BRANCHES (CHI NHÁNH)
CREATE TABLE public.branches (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage own branches" ON public.branches FOR ALL USING (auth.uid() = user_id);

-- 3. BẢNG PROGRAMS (CHƯƠNG TRÌNH ĐÀO TẠO)
CREATE TABLE public.programs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    default_hourly_rate NUMERIC NOT NULL,
    color_hex TEXT DEFAULT '#3D5AFE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage own programs" ON public.programs FOR ALL USING (auth.uid() = user_id);

-- 4. BẢNG STUDENTS (LỚP HỌC)
CREATE TABLE public.students (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    program_id UUID REFERENCES public.programs(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    color_hex TEXT DEFAULT '#3D5AFE',
    schedule_days INTEGER[] DEFAULT '{}',
    start_time TEXT,
    end_time TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage own students" ON public.students FOR ALL USING (auth.uid() = user_id);

-- 5. BẢNG SESSIONS (CA HỌC)
CREATE TABLE public.sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    student_id UUID REFERENCES public.students(id) ON DELETE SET NULL,
    branch_name TEXT NOT NULL,
    program_name TEXT NOT NULL,
    student_name TEXT NOT NULL,
    date DATE NOT NULL,
    time_slot TEXT NOT NULL,
    duration_hours NUMERIC NOT NULL,
    hourly_rate NUMERIC NOT NULL,
    total_amount NUMERIC NOT NULL,
    status TEXT DEFAULT 'PENDING',
    is_makeup BOOLEAN DEFAULT FALSE,
    color_hex TEXT DEFAULT '#3D5AFE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage own sessions" ON public.sessions FOR ALL USING (auth.uid() = user_id);
