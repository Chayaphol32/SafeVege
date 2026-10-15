import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _expiryController = TextEditingController();
  bool _maintenanceMode = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  AppState get appState => widget.appState;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await appState.loadAdminSettings();
      final values = appState.adminSettings;
      _maintenanceMode = _asBool(values['maintenance_mode']);
      _baseUrlController.text = values['public_app_base_url']?.toString() ?? '';
      _expiryController.text =
          values['default_certificate_expiry_days']?.toString() ?? '30';
    } catch (error) {
      _error = error.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final expiry = int.tryParse(_expiryController.text.trim());
    if (expiry == null || expiry <= 0) {
      _showMessage('จำนวนวันหมดอายุต้องเป็นตัวเลขมากกว่า 0', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await appState.updateAdminSettings({
        'maintenance_mode': _maintenanceMode,
        'public_app_base_url': _baseUrlController.text.trim(),
        'default_certificate_expiry_days': expiry,
      });
      if (mounted) _showMessage('บันทึกการตั้งค่าแล้ว');
    } catch (error) {
      if (mounted) {
        _showMessage(
          error.toString().replaceFirst('ApiException: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!appState.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('ตั้งค่าระบบ')),
        body: const Center(child: Text('ไม่มีสิทธิ์เข้าถึงเมนูนี้')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text(
          'ตั้งค่าระบบ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: _loading || _saving ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: FilledButton.tonalIcon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('โหลดไม่สำเร็จ: $_error'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('โหมดปิดปรับปรุงระบบ'),
                  subtitle: const Text(
                    'ผู้ใช้ทั่วไปจะเห็นว่าระบบอยู่ระหว่างปรับปรุง',
                  ),
                  value: _maintenanceMode,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _maintenanceMode = value),
                ),
                const Divider(),
                TextField(
                  controller: _baseUrlController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่เว็บสาธารณะ',
                    hintText: 'https://example.com',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _expiryController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'อายุใบรับรองเริ่มต้น (วัน)',
                    prefixIcon: Icon(Icons.event_available_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกการตั้งค่า'),
        ),
      ],
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
        ),
      );
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }
}
