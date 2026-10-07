import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  bool _loading = true;
  bool _notificationsEnabled = true;
  String _notificationSound = 'default';
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final enabled = await _storage.read(key: 'notifications_enabled');
      final sound = await _storage.read(key: 'notification_sound');
      final darkMode = await _storage.read(key: 'dark_mode');
      
      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled != 'false';
          _notificationSound = sound == 'silent' ? 'silent' : 'default';
          _darkMode = darkMode == 'true';
          appThemeMode.value = _darkMode ? ThemeMode.dark : ThemeMode.light;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.write(key: 'notifications_enabled', value: _notificationsEnabled.toString());
      await _storage.write(key: 'notification_sound', value: _notificationSound);
      await _storage.write(key: 'dark_mode', value: _darkMode.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu cài đặt thông báo'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _logout() async {
    await SupabaseService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Cài đặt')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              children: [
                Container(height: 20, width: 120, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                const SizedBox(height: 24),
                Container(height: 20, width: 100, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              title: 'CÀI ĐẶT THÔNG BÁO',
              children: [
                SwitchListTile(
                  title: const Text('Giao diện tối'),
                  value: _darkMode,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    appThemeMode.value = value ? ThemeMode.dark : ThemeMode.light;
                    _saveSettings();
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Bật thông báo ứng dụng', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Nhận thông báo khi ca học bắt đầu và kết thúc', style: TextStyle(fontSize: 12)),
                  value: _notificationsEnabled,
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                    _saveSettings();
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Âm thanh thông báo', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: DropdownButton<String>(
                    value: _notificationSound,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'default', child: Text('Mặc định')),
                      DropdownMenuItem(value: 'silent', child: Text('Im lặng')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _notificationSound = val);
                        _saveSettings();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
