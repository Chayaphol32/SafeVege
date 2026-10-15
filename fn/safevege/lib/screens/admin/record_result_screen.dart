import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/common_widgets.dart';

class RecordResultScreen extends StatefulWidget {
  const RecordResultScreen({
    super.key,
    required this.request,
    required this.appState,
  });

  final InspectionRequestModel request;
  final AppState appState;

  @override
  State<RecordResultScreen> createState() => _RecordResultScreenState();
}

class _RecordResultScreenState extends State<RecordResultScreen> {
  late final List<VegetableInspection> _vegResults;
  late final TextEditingController _certificateNumberController;
  String? _selectedFileName;
  int? _selectedFileSize;
  Uint8List? _selectedFileBytes;
  bool _isSubmitting = false;

  bool get _allOutcomesRecorded =>
      _vegResults.isNotEmpty &&
      _vegResults.every(
        (result) => result.outcome != null || result.passed != null,
      );

  bool get _shouldAttachCertificate =>
      _allOutcomesRecorded &&
      _vegResults.any(
        (result) => result.outcome == 'passed' || result.passed == true,
      );

  bool get _canPublish {
    if (!_allOutcomesRecorded ||
        _vegResults.any((result) => (result.details ?? '').trim().isEmpty)) {
      return false;
    }
    if (_shouldAttachCertificate &&
        (_selectedFileName == null ||
            _selectedFileBytes == null ||
            _certificateNumberController.text.trim().isEmpty)) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    final draft = widget.appState.inspectionResultDraft(widget.request.id);
    final savedResults = draft?.results ?? widget.request.results;
    final savedByName = {
      for (final result in savedResults) result.name: result,
    };
    _vegResults = widget.request.vegetables.map((name) {
      final saved = savedByName[name];
      return saved == null
          ? VegetableInspection(name: name)
          : VegetableInspection(
              name: saved.name,
              requestItemId: saved.requestItemId,
              resultId: saved.resultId,
              outcome:
                  saved.outcome ??
                  (saved.passed == true
                      ? 'passed'
                      : saved.passed == false
                      ? 'failed'
                      : null),
              passed: saved.passed,
              inspectionDate: saved.inspectionDate,
              certNo: saved.certNo,
              notes: saved.notes,
              details: saved.details,
            );
    }).toList();
    _selectedFileName =
        draft?.certificateFileName ?? widget.request.certificateFileName;
    _certificateNumberController = TextEditingController(
      text: draft?.certificateNumber ?? widget.request.certificateNumber ?? '',
    );
  }

  @override
  void dispose() {
    _certificateNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg'],
        withData: true,
      );
      if (result == null || !mounted) return;

      final file = result.files.single;
      if (file.size > 5 * 1024 * 1024) {
        AppFeedback.showError(context, 'ไฟล์ต้องมีขนาดไม่เกิน 5 MB');
        return;
      }
      if (file.bytes == null || file.bytes!.isEmpty) {
        AppFeedback.showError(context, 'อ่านไฟล์ที่เลือกไม่ได้ กรุณาเลือกใหม่');
        return;
      }

      setState(() {
        _selectedFileName = file.name;
        _selectedFileSize = file.size;
        _selectedFileBytes = file.bytes;
      });
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, 'เปิดตัวเลือกไฟล์ไม่สำเร็จ ลองอีกครั้ง');
      }
    }
  }

  void _saveDraft() {
    widget.appState.saveInspectionResultDraft(
      requestId: widget.request.id,
      results: _vegResults,
      certificateFileName: _selectedFileName,
      certificateNumber: _certificateNumberController.text.trim(),
    );
    AppFeedback.showSuccess(context, 'บันทึกร่างไว้ชั่วคราวในแอปแล้ว');
    Navigator.pop(context, true);
  }

  Future<void> _submitResults() async {
    if (!_canPublish) {
      AppFeedback.showError(context, 'กรอกผลตรวจและรายละเอียดให้ครบก่อนบันทึก');
      return;
    }

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'ยืนยันการบันทึกผลตรวจ?',
      message: 'บันทึกผลตรวจและใบรับรองที่เลือกไปยังระบบ SafeVege หรือไม่?',
      confirmLabel: 'บันทึกผลตรวจ',
    );

    if (confirmed && mounted) {
      setState(() => _isSubmitting = true);
      try {
        await widget.appState.recordInspectionResults(
          requestId: widget.request.id,
          results: _vegResults,
          certFileName: _shouldAttachCertificate ? _selectedFileName : null,
          certNumber: _shouldAttachCertificate
              ? _certificateNumberController.text.trim()
              : null,
          certificateBytes: _shouldAttachCertificate
              ? _selectedFileBytes
              : null,
        );
        if (!mounted) return;
        AppFeedback.showSuccess(context, 'บันทึกผลตรวจเรียบร้อยแล้ว');
        Navigator.pop(context, true);
      } catch (error) {
        if (mounted) AppFeedback.showError(context, error.toString());
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('บันทึกผลตรวจสอบ')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.request.id,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryOf(context),
                              ),
                            ),
                          ),
                          StatusBadge(status: widget.request.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ร้านค้า: ${widget.request.shopName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'ผู้บันทึกผล: ${widget.appState.adminName}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SectionHeader(
                title: 'ผลตรวจแยกตามชนิดผัก',
                subtitle: 'เลือกผลและกรอกรายละเอียดตามรายงานจริง',
              ),
              for (var index = 0; index < _vegResults.length; index++)
                _buildVegetableResult(index),
              const SizedBox(height: 8),
              _buildCertificateSection(),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _canPublish && !_isSubmitting
                    ? _submitResults
                    : null,
                icon: const Icon(Icons.task_alt_rounded),
                label: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('บันทึกและเผยแพร่ผล'),
              ),
              if (!_canPublish) ...[
                const SizedBox(height: 8),
                Text(
                  'ระบุผลและรายละเอียดให้ครบทุกชนิด หากมีผักที่ผ่าน ให้ระบุเลขใบรับรองและเลือกไฟล์',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saveDraft,
                icon: const Icon(Icons.save_outlined),
                label: const Text('บันทึกร่าง'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVegetableResult(int index) {
    final result = _vegResults[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(
                  value: 'passed',
                  icon: Icon(Icons.check_circle_outline, size: 16),
                  label: Text('ผ่าน'),
                ),
                ButtonSegment(
                  value: 'failed',
                  icon: Icon(Icons.cancel_outlined, size: 16),
                  label: Text('ไม่ผ่าน'),
                ),
                ButtonSegment(
                  value: 'inconclusive',
                  icon: Icon(Icons.help_outline, size: 16),
                  label: Text('ตรวจซ้ำ'),
                ),
              ],
              selected: result.outcome == null
                  ? const <String>{}
                  : {result.outcome!},
              onSelectionChanged: (selection) {
                setState(() {
                  final outcome = selection.isEmpty ? null : selection.first;
                  result.outcome = outcome;
                  result.passed = switch (outcome) {
                    'passed' => true,
                    'failed' => false,
                    _ => null,
                  };
                });
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey('details-${result.name}'),
              initialValue: result.details ?? '',
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'รายละเอียดผลตรวจ *',
                hintText: 'กรอกตามรายงานแล็บหรือเอกสารตรวจ',
                alignLabelWithHint: true,
              ),
              onChanged: (value) => setState(() => result.details = value),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('notes-${result.name}'),
              initialValue: result.notes ?? '',
              decoration: const InputDecoration(
                labelText: 'หมายเหตุเพิ่มเติม',
                hintText: 'ข้อสังเกตหรือคำแนะนำ (ถ้ามี)',
              ),
              onChanged: (value) => setState(() => result.notes = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ใบรับรอง',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _shouldAttachCertificate
                  ? 'แนบใบรับรองสำหรับรายการที่ผ่านและกรอกเลขที่ตามเอกสาร'
                  : 'จะแสดงช่องใบรับรองเมื่อมีผลผ่านอย่างน้อยหนึ่งรายการ',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            if (_shouldAttachCertificate) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _certificateNumberController,
                decoration: const InputDecoration(
                  labelText: 'เลขที่ใบรับรอง *',
                  hintText: 'กรอกเลขตามเอกสารจริง',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (_selectedFileName != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      color: AppColors.primaryOf(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _selectedFileSize == null
                                ? 'เลือกในเครื่อง • ยังไม่ได้อัปโหลด'
                                : 'เลือกในเครื่อง • ${(_selectedFileSize! / (1024 * 1024)).toStringAsFixed(1)} MB • ยังไม่ได้อัปโหลด',
                            style: TextStyle(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'ลบไฟล์ที่เลือก',
                      onPressed: () => setState(() {
                        _selectedFileName = null;
                        _selectedFileSize = null;
                        _selectedFileBytes = null;
                      }),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickCertificate,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(
                _selectedFileName == null
                    ? 'เลือกไฟล์ PDF หรือ JPG'
                    : 'เปลี่ยนไฟล์',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
