# MASTER ARCHITECTURE PROMPT: TEACHER ATTENDANCE, TIMETABLE & MULTI-TENANT SALARY MANAGEMENT APP

Bạn là một Chuyên gia Lập trình Di động Full-stack (Senior Flutter & Supabase Engineer). Nhiệm vụ của bạn là xây dựng hoàn chỉnh ứng dụng mobile (Android & iOS) quản lý học sinh, lịch dạy, điểm danh thông minh và xuất báo cáo lương Excel đa chi nhánh, giải quyết triệt để tất cả các lỗi logic và giao diện từng phát sinh.

Dự án được phân chia nghiêm ngặt thành 4 phần dưới đây:
PHẦN 1: NGỮ CẢNH HỆ THỐNG & NGHIỆP VỤ (SYSTEM CONTEXT)
1. Bối cảnh & Đối tượng người dùng
Ứng dụng phục vụ các giáo viên, trợ giảng, gia sư tại nhiều trung tâm tiếng Anh hoặc lớp học độc lập (không fix cứng riêng cho bất kỳ trung tâm nào).

Cho phép người dùng tùy chỉnh tên trung tâm, ngân hàng nhận lương, chi nhánh, môn học/chương trình đào tạo và mức thù lao theo giờ.

2. Dữ liệu tham chiếu & Template Excel
Cấu trúc file Excel xuất ra phải linh hoạt theo tên trung tâm được cấu hình:

Tên file: [TÊN_TRUNG_TÂM] - [TÊN_GIÁO_VIÊN] - BÁO CÁO LƯƠNG THÁNG [MM] - [YYYY].xlsx.

Sheet TOTAL: Bảng 1 tổng hợp (STT | CHI NHÁNH | TIỀN | TỔNG TIỀN), Bảng 2 thông tin ngân hàng (Ngân hàng, Chủ TK, Số TK, Ghi chú bù trừ công).

Các Sheet chi nhánh (VD: TKCA Phú Mỹ, TKCA Hòa Phú...): Liệt kê từng ca dạy đã hoàn thành:NGÀY | THÁNG | NĂM | CA HỌC | TÊN GIÁO VIÊN | SỐ LƯỢNG HỌC VIÊN | TÊN HỌC VIÊN | CHƯƠNG TRÌNH ĐÀO TẠO | SỐ GIỜ | MỨC LƯƠNG DẠY/GIỜ | THÀNH TIỀN.

Ô M2: TỔNG TIỀN/THÁNG, Ô M3: Công thức =SUM(K2:K{n}).

Nguyên tắc lương: CHỈ các ca học có trạng thái COMPLETED (Đã điểm danh/hoàn tất) mới được cộng vào tổng lương. Khi xóa một học sinh, các ca học đã dạy trong quá khứ vẫn phải được giữ lại để bảo toàn lịch sử lương.

3. Phân tích UI Visual (image.png & Material TimePicker)
Header & Calendar: Selector tháng dạng Pill cân đối, chữ canh chính giữa. Thước đo ngày (Ruler Slider) có các vạch chia vi phân mượt mà, ngày active hiển thị bubble xanh navy đậm.

Lịch chấm màu (Dots Indicator): Dưới mỗi ngày trên thước lịch hiển thị các chấm màu đại diện cho ca học. Màu của ca học được gán cố định theo Học sinh/Chương trình (không random màu).

Time Picker: Sử dụng hộp thoại chọn giờ dạng đồng hồ kim Material Design (Dial Picker) có 2 ô hiển thị giờ : phút to rõ và nút chuyển AM/PM.

Bottom Navigation Bar: Thiết kế uốn lượn cong (Curved Concave Bottom Bar) có notch rãnh khuyết ở giữa ôm lấy nút tròn Floating Action Button (FAB).

PHẦN 2: KỸ NĂNG CỐT LÕI YÊU CẦU (REQUIRED AGENT SKILLS)
Agent phải áp dụng đồng thời các kỹ năng chuyên môn:

supabase_backend_architect: Thiết kế bảng, Foreign Keys, Triggers, RLS Policies không bị lỗi 400/500, cơ chế Email Confirmation và Auto-refresh Token.

flutter_ui_layout_guardian: Triệt tiêu 100% lỗi RenderFlex overflowed by X pixels. Sử dụng LayoutBuilder, SingleChildScrollView, Flexible, Expanded và TextOverflow.ellipsis.

interactive_gesture_master: Viết tương tác Dismissible/Slide Action kéo từ phải sang trái (Right-to-Left) để lộ nút xóa nhỏ màu đỏ, nhấn lần nữa mới xác nhận xóa, kèm Snackbar Hoàn tác (Undo) 5 giây.

local_notification_scheduler: Cài đặt flutter_local_notifications lập lịch push notification ngay khi ca học kết thúc để nhắc giáo viên bấm xác nhận điểm danh.

excel_binary_generator: Tạo file .xlsx tự động lưu vào thư mục riêng của app trên thiết bị và mở native share sheet.

PHẦN 3: ĐẶC TẢ TÀI LIỆU DỰ ÁN (.MD DOCS)
Agent hãy tự động tạo các file markdown sau trong thư mục /docs trước khi viết code:

File 1: /docs/SUPABASE_SETUP.sql
SQL
-- KÍCH HOẠT EXTENSION
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. BẢNG PROFILES (Tự động liên kết khi user đăng ký qua Supabase Auth)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    organization_name TEXT DEFAULT 'TKCA VN',
    bank_name TEXT,
    bank_account_name TEXT,
    bank_account_number TEXT,
    salary_note TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Bật RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view and edit own profile" 
ON public.profiles FOR ALL USING (auth.uid() = id);

-- TRIGGER TỰ ĐỘNG TẠO PROFILE KHI ĐĂNG KÝ (Tránh lỗi 500 Database error saving new user)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, organization_name)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'full_name', 'Giáo viên'), 'TKCA VN');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. BẢNG CHI NHÁNH (Branches)
CREATE TABLE public.branches (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage own branches" ON public.branches FOR ALL USING (auth.uid() = user_id);

-- 3. BẢNG CHƯƠNG TRÌNH ĐÀO TẠO (Programs)
CREATE TABLE public.programs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    default_hourly_rate NUMERIC DEFAULT 60000,
    color_hex TEXT DEFAULT '#3D5AFE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage own programs" ON public.programs FOR ALL USING (auth.uid() = user_id);

-- 4. BẢNG HỌC SINH (Students)
CREATE TABLE public.students (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
    program_id UUID REFERENCES public.programs(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    color_hex TEXT DEFAULT '#3D5AFE',
    schedule_days INTEGER[] DEFAULT '{}', -- 1: T2, 2: T3, ..., 7: CN
    start_time TEXT, -- '17:00'
    end_time TEXT,   -- '19:00'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage own students" ON public.students FOR ALL USING (auth.uid() = user_id);

-- 5. BẢNG CA HỌC (Sessions)
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
    status TEXT DEFAULT 'PENDING', -- 'PENDING', 'COMPLETED', 'CANCELLED'
    is_makeup BOOLEAN DEFAULT FALSE,
    color_hex TEXT DEFAULT '#3D5AFE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage own sessions" ON public.sessions FOR ALL USING (auth.uid() = user_id);
File 2: /docs/BUSINESS_RULES.md
Markdown
# Quy tắc logic & Hành vi ứng dụng

1. **Đăng ký & Xác thực:**
   - Khi đăng ký, ứng dụng hiển thị màn hình thông báo: "Vui lòng kiểm tra email và bấm link xác nhận để kích hoạt tài khoản".
   - Tự động lưu Token (Remember Me) bằng `flutter_secure_storage`.
2. **Sinh ca học tự động:**
   - Khi thêm học sinh (chọn các thứ trong tuần + giờ bắt đầu/kết thúc + chương trình đào tạo + chi nhánh), hệ thống tự động sinh ra các `sessions` tương ứng trong tháng.
   - Số ca học của học sinh trong tháng được đếm chính xác dựa trên số ngày thực tế của tháng đó (VD: Thứ Tư tháng 9 có 4 ngày -> hiển thị 4 ca, tháng 10 có 5 ngày -> hiển thị 5 ca).
3. **Thao tác xóa & Hoàn tác:**
   - Kéo thẻ ca học từ PHẢI SANG TRÁI: Dừng lại hé lộ nút xóa nhỏ màu đỏ.
   - Nhấn vào nút đỏ -> Đánh dấu tạm xóa và hiện Snackbar đếm ngược 5 giây "Đã xóa ca học - [HOÀN TÁC]". Sau 5 giây mới commit xóa trên Supabase.
4. **Trang Cài đặt:**
   - Thiết kế tối giản, sạch sẽ (Clean & Flat UI), không màu mè AI.
   - Gồm các khối: Tên Trung Tâm, Thông tin giáo viên, Thông tin tài khoản ngân hàng, Quản lý chi nhánh & môn học, Nút Đăng xuất.
PHẦN 4: HƯỚNG DẪN TRIỂN KHAI CODE CHI TIẾT (CODE IMPLEMENTATION)
Agent triển khai toàn bộ mã nguồn theo cấu trúc Flutter chuẩn Clean Code:

1. Kiến trúc thư mục dự án
Plaintext
lib/
├── core/
│   ├── constants/       # AppColors, SupabaseConfig
│   ├── services/        # NotificationService, ExcelExportService, StorageService
│   └── utils/           # DateUtils, CurrencyFormatter
├── features/
│   ├── auth/            # LoginScreen, RegisterScreen, VerifyEmailScreen
│   ├── schedule/        # ScheduleScreen, RulerDatePicker, SessionCard
│   ├── students/        # StudentListScreen, AddStudentScreen (Multi-day & TimePicker)
│   ├── salary/          # SalaryReportScreen, ExcelPreviewSheet
│   └── settings/        # CleanSettingsScreen, ProfileEditor
├── widgets/
│   ├── curved_bottom_nav.dart # Custom Bottom Bar uốn lượn có rãnh FAB
│   └── swipeable_action_card.dart # Kéo phải sang trái hiển thị nút xóa + Undo
└── main.dart
2. Yêu cầu chi tiết các Module bắt buộc
A. Cấu hình Supabase & Tránh lỗi mạng (lib/core/constants/supabase_config.dart)
Khai báo hằng số URL và Anon Key tĩnh trong code để sẵn sàng chạy ngay.

Xử lý bắt ngoại lệ thân thiện khi mất kết nối mạng hoặc sai mật khẩu.

B. Time Picker chuẩn Material Dial (lib/features/students/widgets/custom_time_picker.dart)
Khi chọn giờ bắt đầu/kết thúc, gọi showTimePicker(context: context, initialTime: ..., initialEntryMode: TimePickerEntryMode.dial) hiển thị mặt đồng hồ kim chuẩn xác, tự động tính ra duration_hours (Số giờ = (End - Start)).

C. Thêm học sinh đa năng (lib/features/students/screens/add_student_screen.dart)
Bỏ trường nhập số điện thoại. Chỉ cần: Tên học sinh, Chọn Chi nhánh (Dropdown), Chọn Chương trình đào tạo (để lấy mức lương/giờ), Chọn màu đại diện.

Chọn thứ trong tuần: Dạng 7 nút tròn (T2, T3, T4, T5, T6, T7, CN). Bấm 1 lần để chọn (đổi màu active), bấm lần nữa để bỏ chọn.

Tự động tính số tiền 1 buổi = duration_hours * program.hourly_rate.

D. Tránh lỗi RenderFlex Overflow (lib/features/schedule/widgets/session_card.dart)
Mọi hàng (Row) chứa thông tin giờ học, tên học sinh và tag môn học bắt buộc phải bọc text trong Expanded hoặc Flexible với maxLines: 1 và overflow: TextOverflow.ellipsis.

Tuyệt đối không dùng kích thước cố định gây tràn màn hình trên các thiết bị nhỏ.

E. Chấm màu đồng bộ trên Ruler Picker (lib/features/schedule/widgets/ruler_date_picker.dart)
Tại mỗi vạch ngày trên thước đo, query các ca học trong ngày.

Vẽ các chấm tròn màu (dot indicators) theo mã màu color_hex của chính ca học/học sinh đó. Cùng một môn/học sinh sẽ luôn có cùng một màu chấm.

F. Engine xuất file Excel (lib/core/services/excel_export_service.dart)
Tự động gom nhóm các ca học có trạng thái COMPLETED theo Chi nhánh.

Sinh đúng Sheet TOTAL và các Sheet chi nhánh theo mẫu đã phân tích ở Phần 1.

Lưu file vào thư mục tài liệu riêng của ứng dụng bằng path_provider:Directory appDocDir = await getApplicationDocumentsDirectory();

Kích hoạt chia sẻ nhanh bằng share_plus.

Agent hãy bắt đầu khởi tạo cấu trúc thư mục, sinh file tài liệu tại /docs và viết toàn bộ code chi tiết, hoàn chỉnh từng file, sẵn sàng build APK Android mà không có bất kỳ lỗi cú pháp nào!