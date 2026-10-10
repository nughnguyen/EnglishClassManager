# English Class Manager

Ứng dụng Flutter hỗ trợ giáo viên tiếng Anh quản lý học sinh, lịch dạy, điểm danh và báo cáo lương trên thiết bị di động.

## Tính năng

- Quản lý học sinh, chi nhánh và chương trình học.
- Thiết lập lịch học định kỳ và tạo ca học theo lịch.
- Xem lịch theo tháng, theo dõi ca đang diễn ra và cập nhật trạng thái điểm danh.
- Nhận thông báo nhắc điểm danh khi ca học kết thúc.
- Theo dõi báo cáo lương theo tháng và xuất bảng tính Excel.
- Quản lý hồ sơ giáo viên và các tùy chọn ứng dụng.

## Công nghệ

- Flutter / Dart
- Supabase Auth và PostgreSQL
- Flutter Local Notifications
- Excel export (`.xlsx`)

## Yêu cầu

- Flutter SDK tương thích với Dart `>=3.3.0 <4.0.0`.
- Android SDK để chạy hoặc tạo bản dựng Android.
- Một dự án Supabase.

## Cấu hình Supabase

1. Tạo dự án Supabase.
2. Mở `docs/SUPABASE_SETUP.sql` và chạy nội dung trong **SQL Editor** của Supabase để tạo các bảng và chính sách truy cập cần thiết.
3. Cập nhật `url` và `anonKey` trong `lib/core/constants/supabase_config.dart` bằng thông tin dự án của bạn.
4. Chỉ sử dụng khóa `anon` ở phía ứng dụng và giữ các chính sách Row Level Security (RLS) được bật. Không đưa khóa `service_role` vào ứng dụng di động.

## Cài đặt và chạy

Tại thư mục dự án, chạy:

```bash
flutter pub get
flutter run
```

Để tạo APK phát hành:

```bash
flutter build apk --release
```

Tệp APK được tạo trong `build/app/outputs/flutter-apk/`.

## Cấu trúc thư mục

```text
lib/
├── core/
│   ├── constants/    # Cấu hình và màu sắc ứng dụng
│   ├── models/       # Mô hình dữ liệu
│   ├── services/     # Supabase, thông báo và xuất Excel
│   └── utils/        # Tiện ích ngày tháng và định dạng
├── features/
│   ├── auth/         # Đăng nhập, đăng ký và xác minh email
│   ├── schedule/     # Lịch dạy và quản lý ca học
│   ├── salary/       # Báo cáo lương
│   ├── settings/     # Cài đặt ứng dụng
│   └── students/     # Học sinh, chi nhánh và chương trình học
├── widgets/          # Thành phần giao diện dùng chung
└── main.dart         # Khởi tạo ứng dụng và điều hướng

docs/                 # Tài liệu và script cấu hình Supabase
assets/               # Tài nguyên giao diện
```