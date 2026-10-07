import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? email;
  final String? password;

  const VerifyEmailScreen({super.key, this.email, this.password});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Bắt đầu kiểm tra định kỳ xem email đã được xác nhận chưa
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      if (widget.email != null && widget.password != null) {
        // Cố gắng đăng nhập
        await Supabase.instance.client.auth.signInWithPassword(
          email: widget.email!,
          password: widget.password!,
        );
      } else {
        // Làm mới phiên đăng nhập hiện tại
        final res = await Supabase.instance.client.auth.refreshSession();
        if (res.user?.emailConfirmedAt == null) {
          return; // Vẫn chưa xác nhận, tiếp tục đợi
        }
      }
      
      // Nếu thành công
      _timer?.cancel();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) {
        // Vẫn chưa xác nhận, tiếp tục đợi
      } else if (e.message.contains('session_not_found') || e.message.contains('not found')) {
        // Bỏ qua lỗi không tìm thấy phiên
      } else {
        // Lỗi khác (ví dụ sai mật khẩu), dừng kiểm tra
        _timer?.cancel();
      }
    } catch (e) {
      // Lỗi mạng hoặc lỗi khác
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _resendEmail(BuildContext context) async {
    try {
      final email = widget.email ?? Supabase.instance.client.auth.currentUser?.email;
      if (email != null) {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: email,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã gửi lại email xác nhận'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi gửi email. Vui lòng thử lại sau.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _backToLogin(BuildContext context) async {
    _timer?.cancel();
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Kiểm tra email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vui lòng kiểm tra email và bấm link xác nhận để kích hoạt tài khoản. Hệ thống sẽ tự động chuyển vào màn hình chính sau khi bạn xác nhận.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _backToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _resendEmail(context),
                child: const Text(
                  'Gửi lại email',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
