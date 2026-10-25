import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/group_api.dart';
import '../../../core/services/export_service.dart';
import '../../../data/models/group_model.dart';

import 'package:dio/dio.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  List<GroupModel> _groups = [];
  int? _groupId; // null = all teams
  String _format = 'csv';
  int _preset = 7; // 1 = today, 7, 30, 0 = custom
  late DateTime _from;
  late DateTime _to;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _applyPreset(7);
    _loadGroups();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _applyPreset(int days) {
    _preset = days;
    _to = _today;
    _from = _today.subtract(Duration(days: days - 1));
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await GroupApi.getAll();
      if (mounted) setState(() => _groups = groups);
    } catch (_) {}
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: _today,
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _preset = 0;
        _from = picked.start;
        _to = picked.end;
      });
    }
  }

  Future<void> _download() async {
    setState(() => _isExporting = true);
    try {
      await ExportService.exportAttendance(from: _from, to: _to, format: _format, groupId: _groupId);
    } catch (e) {
      debugPrint('EXPORT ERROR: $e');
      if (e is DioException) {
        debugPrint('STATUS: ${e.response?.statusCode}');
        debugPrint('DATA: ${e.response?.data}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not export. Please try again.')));
      }
    }  finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.panel,
          border: Border.all(color: active ? AppColors.primary : AppColors.line),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.inkSoft)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, title: Text('Export attendance', style: AppTextStyles.heading)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Period', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip('Today', _preset == 1, () => setState(() => _applyPreset(1))),
            _chip('Last 7 days', _preset == 7, () => setState(() => _applyPreset(7))),
            _chip('Last 30 days', _preset == 30, () => setState(() => _applyPreset(30))),
            _chip('Custom', _preset == 0, _pickRange),
          ]),
          const SizedBox(height: 8),
          Text('${_fmt(_from)} to ${_fmt(_to)}', style: AppTextStyles.bodySoft),
          const SizedBox(height: 22),

          Text('Team', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip('All teams', _groupId == null, () => setState(() => _groupId = null)),
            ..._groups.map((g) => _chip(g.name, _groupId == g.id, () => setState(() => _groupId = g.id))),
          ]),
          const SizedBox(height: 22),

          Text('File format', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _chip('CSV', _format == 'csv', () => setState(() => _format = 'csv')),
            _chip('Excel (.xlsx)', _format == 'xlsx', () => setState(() => _format = 'xlsx')),
          ]),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _isExporting ? null : _download,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isExporting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Download ${_format == 'csv' ? 'CSV' : 'Excel'}'),
          ),
        ],
      ),
    );
  }
}