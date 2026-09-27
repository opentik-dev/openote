import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/notes_state_notifier.dart';

/// Modal dialog for backing up notes to ZIP, and importing Markdown ZIP archives
/// compatible with Obsidian, Joplin, and Keep.
class BackupExportDialog extends StatefulWidget {
  final NotesStateNotifier notifier;

  const BackupExportDialog({
    super.key,
    required this.notifier,
  });

  @override
  State<BackupExportDialog> createState() => _BackupExportDialogState();
}

class _BackupExportDialogState extends State<BackupExportDialog> {
  bool _isProcessing = false;
  String? _statusMessage;
  final TextEditingController _importPathController = TextEditingController();

  Future<void> _exportBackup() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'جارِ تجهيز وضغط الملاحظات في ملف ZIP...';
    });

    try {
      final zipFile = await widget.notifier.exportBackupZip();
      await Clipboard.setData(ClipboardData(text: zipFile.path));
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '✓ تم تصدير النسخة الاحتياطية بنجاح إلى:\n${zipFile.path}\n(تم نسخ المسار إلى الحافظة)';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'خطأ أثناء التصدير: $e';
        });
      }
    }
  }

  Future<void> _importBackup() async {
    final path = _importPathController.text.trim();
    if (path.isEmpty) {
      setState(() => _statusMessage = 'يرجى كتابة أو لصق مسار ملف ZIP المراد استيراده');
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      setState(() => _statusMessage = 'الملف غير موجود في المسار المحدد: $path');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'جارِ فك الضغط واستيراد الملاحظات وفهرستها...';
    });

    try {
      final count = await widget.notifier.importBackupZip(file);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '✓ تم استيراد $count ملاحظة بنجاح وتحديث الفهرس!';
          _importPathController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'فشل الاستيراد: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.backup_outlined, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text(
            'النسخ الاحتياطي والاستيراد',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compatibility Note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملفات النسخ الاحتياطي هي أرشيفات ZIP قياسية تحتوي ملفات Markdown، وهي متوافقة مباشرة مع Obsidian و Joplin و Keep.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF1E3A8A),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Export Section
              const Text(
                '1. تصدير نسخة احتياطية شاملة (Export):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'إجمالي الملاحظات الحالية: ${widget.notifier.allNotes.length} ملاحظة',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isProcessing ? null : _exportBackup,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('تصدير كملف ZIP الآن'),
              ),

              const Divider(height: 28),

              // Import Section
              const Text(
                '2. استيراد ملاحظات من ملف ZIP خارجي:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _importPathController,
                decoration: const InputDecoration(
                  labelText: 'مسار ملف ZIP على الجهاز',
                  hintText: '/storage/emulated/0/.../backup.zip',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _importBackup,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('استيراد ودمج الملاحظات'),
              ),

              if (_isProcessing) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],

              if (_statusMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusMessage!.startsWith('✓')
                        ? (isDark ? Colors.green[900]!.withValues(alpha: 0.3) : Colors.green[50])
                        : (isDark ? Colors.orange[900]!.withValues(alpha: 0.3) : Colors.orange[50]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _statusMessage!.startsWith('✓') ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
