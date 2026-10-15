import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  bool _loading = true;
  String? _error;

  AppState get appState => widget.appState;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await appState.loadAuditEvents();
    } catch (error) {
      _error = error.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!appState.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('ประวัติการใช้งาน')),
        body: const Center(child: Text('ไม่มีสิทธิ์เข้าถึงเมนูนี้')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text(
          'ประวัติการใช้งาน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: _loading ? null : _load,
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
    if (appState.auditEvents.isEmpty) {
      return const Center(child: Text('ยังไม่มีประวัติการใช้งาน'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appState.auditEvents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _AuditTile(event: appState.auditEvents[index]),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.event});

  final AuditEventModel event;

  @override
  Widget build(BuildContext context) {
    final date = event.createdAt?.toLocal();
    final timestamp = date == null
        ? 'ไม่ระบุเวลา'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final entity = event.entityId.isEmpty
        ? event.entityType
        : '${event.entityType} #${event.entityId}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.infoBgOf(context),
          foregroundColor: AppColors.primaryOf(context),
          child: const Icon(Icons.history_rounded),
        ),
        title: Text(
          event.action,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${event.actorUsername} • $entity\n$timestamp'),
        isThreeLine: true,
      ),
    );
  }
}
