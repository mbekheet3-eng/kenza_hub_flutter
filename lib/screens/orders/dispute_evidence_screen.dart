import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/dispute_evidence_service.dart';

class DisputeEvidenceScreen extends StatefulWidget {
  const DisputeEvidenceScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<DisputeEvidenceScreen> createState() => _DisputeEvidenceScreenState();
}

class _DisputeEvidenceScreenState extends State<DisputeEvidenceScreen> {
  final _service = DisputeEvidenceService();
  final _picker = ImagePicker();
  final _captionController = TextEditingController();
  String? _disputeId;
  List<Map<String, dynamic>> _evidence = const [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final disputeId = await _service.getDisputeIdForOrder(widget.orderId);
      final evidence = await _service.listEvidence(disputeId);
      if (!mounted) return;
      setState(() {
        _disputeId = disputeId;
        _evidence = evidence;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('StateError: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_disputeId == null || _uploading) return;
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (image == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await image.readAsBytes();
      final extension = image.name.contains('.')
          ? image.name.split('.').last
          : 'jpg';
      await _service.uploadImage(
        disputeId: _disputeId!,
        bytes: bytes,
        extension: extension,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
      );
      _captionController.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع الدليل وتسجيل بصمته بنجاح.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر رفع الدليل: $error')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openEvidence(String evidenceId, {required bool download}) async {
    try {
      final uri = await _service.createTemporaryUrl(
        evidenceId: evidenceId,
        download: download,
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح رابط الدليل على الجهاز.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الدليل: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أدلة النزاع')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _load,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'ارفع صورًا توضح المشكلة. تُحفظ الأدلة في مساحة خاصة، وتُسجل بصمتها الرقمية، ويُسجل كل طلب مشاهدة أو تحميل.',
                        style: TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _captionController,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظة على الدليل (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _uploading
                                  ? null
                                  : () => _pickAndUpload(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('اختيار صورة'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _uploading
                                  ? null
                                  : () => _pickAndUpload(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('التقاط صورة'),
                            ),
                          ),
                        ],
                      ),
                      if (_uploading) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 6),
                        const Text('جارٍ رفع الصورة وفحص بصمتها...'),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'الأدلة المسجلة (${_evidence.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_evidence.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('لم يتم تسجيل أدلة لهذا النزاع بعد.'),
                        ),
                      for (final item in _evidence)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.verified_user_outlined),
                            title: Text(
                              (item['caption'] as String?)?.isNotEmpty == true
                                  ? item['caption'] as String
                                  : 'دليل مرفق',
                            ),
                            subtitle: Text(
                              'بصمة SHA-256: ${(item['file_sha256'] as String? ?? '').isEmpty ? 'غير متاحة' : (item['file_sha256'] as String).substring(0, 12) + '…'}\n${item['created_at'] ?? ''}',
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) => _openEvidence(
                                item['id'] as String,
                                download: value == 'download',
                              ),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Text('مشاهدة'),
                                ),
                                PopupMenuItem(
                                  value: 'download',
                                  child: Text('تحميل'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
