-- Chạy đoạn này để đảm bảo TẤT CẢ các user hiện có đều đã được tạo Profile (nếu tài khoản đăng ký từ trước khi chạy SQL cũ)
INSERT INTO public.profiles (id, full_name, organization_name)
SELECT id, raw_user_meta_data->>'full_name', 'TKCA VN'
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles);

