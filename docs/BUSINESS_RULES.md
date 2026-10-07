# Quy tắc logic & Hành vi ứng dụng

## 1. Đăng ký & Xác thực
- Khi đăng ký, ứng dụng hiển thị màn hình thông báo: "Vui lòng kiểm tra email và bấm link xác nhận để kích hoạt tài khoản".
- Tự động lưu Token (Remember Me) bằng `flutter_secure_storage`.
- Tự động refresh token khi hết hạn thông qua Supabase SDK.

## 2. Sinh ca học tự động
- Khi thêm học sinh (chọn các thứ trong tuần + giờ bắt đầu/kết thúc + chương trình đào tạo + chi nhánh), hệ thống tự động sinh ra các `sessions` tương ứng trong tháng hiện tại.
- Số ca học của học sinh trong tháng được đếm chính xác dựa trên số ngày thực tế của tháng đó (VD: Thứ Tư tháng 9 có 4 ngày → hiển thị 4 ca, tháng 10 có 5 ngày → hiển thị 5 ca).

## 3. Thao tác xóa & Hoàn tác (Swipe-to-Delete)
- Kéo thẻ ca học từ **PHẢI SANG TRÁI**: Dừng lại hé lộ nút xóa nhỏ màu đỏ.
- Nhấn vào nút đỏ → Đánh dấu tạm xóa và hiện Snackbar đếm ngược 5 giây "Đã xóa ca học - [HOÀN TÁC]".
- Sau 5 giây mới commit xóa trên Supabase.
- Khi xóa một học sinh, các ca học đã dạy trong quá khứ vẫn được giữ lại (student_id SET NULL) để bảo toàn lịch sử lương.

## 4. Trang Cài đặt
- Thiết kế tối giản, sạch sẽ (Clean & Flat UI), không màu mè.
- Gồm các khối:
  - **Tên Trung Tâm**: Tên tổ chức hiển thị trong báo cáo Excel
  - **Thông tin giáo viên**: Tên đầy đủ
  - **Thông tin tài khoản ngân hàng**: Ngân hàng, Chủ TK, Số TK, Ghi chú bù trừ công
  - **Quản lý chi nhánh**: Thêm/sửa/xóa chi nhánh
  - **Quản lý môn học/chương trình**: Thêm/sửa/xóa chương trình đào tạo (tên + mức lương/giờ + màu sắc)
  - **Nút Đăng xuất**

## 5. Xuất Excel (Business Logic)
- **CHỈ** các ca học có trạng thái `COMPLETED` (Đã điểm danh/hoàn tất) mới được cộng vào tổng lương.
- Tên file: `[TÊN_TRUNG_TÂM] - [TÊN_GIÁO_VIÊN] - BÁO CÁO LƯƠNG THÁNG [MM] - [YYYY].xlsx`
- Sheet **TOTAL**:
  - Bảng 1: STT | CHI NHÁNH | TIỀN | TỔNG TIỀN
  - Bảng 2: Ngân hàng | Chủ TK | Số TK | Ghi chú bù trừ công
- Các **Sheet chi nhánh** (VD: TKCA Phú Mỹ): NGÀY | THÁNG | NĂM | CA HỌC | TÊN GIÁO VIÊN | SỐ LƯỢNG HỌC VIÊN | TÊN HỌC VIÊN | CHƯƠNG TRÌNH ĐÀO TẠO | SỐ GIỜ | MỨC LƯƠNG DẠY/GIỜ | THÀNH TIỀN

## 6. Màu sắc Ca học (Color Logic)
- Màu của ca học được gán cố định theo học sinh/chương trình (không random mỗi lần render).
- Cùng một học sinh/chương trình sẽ luôn có cùng một màu chấm trên lịch.
- Màu được lưu trong trường `color_hex` của bảng `students`.

## 7. Điểm danh (Attendance)
- Trạng thái ca học: `PENDING` → `COMPLETED` hoặc `CANCELLED`
- Sau khi ca học kết thúc, app gửi push notification nhắc giáo viên bấm xác nhận điểm danh.
- Chỉ sau khi bấm xác nhận → trạng thái chuyển sang `COMPLETED` → ca học được tính lương.
