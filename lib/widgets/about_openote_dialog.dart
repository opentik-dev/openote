import 'package:flutter/material.dart';

/// Professional dialog showing app branding, OpenTik-Dev developer info,
/// website (www.opentik.win), and cumulative changelog.
class AboutOpeNoteDialog extends StatelessWidget {
  const AboutOpeNoteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit_note_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OpeNote',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'by OpenTik-Dev',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'v1.1.0',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
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
              const SizedBox(height: 8),
              // Website & Developer Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language, size: 16, color: Colors.teal),
                        const SizedBox(width: 6),
                        const Text(
                          'الموقع الرسمي للمطور:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const SelectableText(
                      'www.opentik.win',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'معرف الحزمة: win.opentik.openote',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'سجل التحديثات التراكمي (Changelog):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Version 1.1.0
              _buildVersionTile(
                context,
                version: 'الإصدار 1.1.0 (الحالي)',
                date: '2026-09-27',
                changes: [
                  'تأصيل هوية OpeNote وتحديث معرف الحزمة إلى win.opentik.openote للمطور OpenTik-Dev.',
                  'التبديل بين المظهر المظلم (Dark) والفاتح (Light) وتلقائي النظام.',
                  'دعم اختيار لغة الواجهة (العربية / English / لغة الجهاز).',
                  'تعدد طرق العرض في الواجهة الرئيسية: التبديل بين القائمة والشبكة (Grid Cards).',
                  'أرشفة الملاحظات وإدارتها وإخفائها من القائمة العامة.',
                  'البحث السريع في النصوص والعناوين والمقتطفات.',
                ],
              ),
              const Divider(height: 20),

              // Version 1.0.1
              _buildVersionTile(
                context,
                version: 'الإصدار 1.0.1',
                date: '2026-09-27',
                changes: [
                  'حل جذري لمشكلة ترميز النصوص العربية المشوهة (Mojibake) عبر استخدام فك ترميز UTF-8 الصارم.',
                  'دعم أصلي لخط المسند اليمني القديم (Old South Arabian) وتضمين خط Noto الرسمي.',
                  'إضافة أداة فاصل الكلمات في خط المسند (𐩽) في شريط التحرير.',
                  'إصلاح طفح شريط العنوان في شاشة المحرر على شاشات الهواتف.',
                ],
              ),
              const Divider(height: 20),

              // Version 1.0.0
              _buildVersionTile(
                context,
                version: 'الإصدار 1.0.0',
                date: '2026-09-26',
                changes: [
                  'الإطلاق الأول: معمارية Local-first حيث ملفات .md هي المصدر الوحيد للحقيقة (SSOT).',
                  'فهرس ذاكرة مباشر In-Memory بدون قواعد بيانات وسيطة.',
                  'كشف التعديلات الخارجية ومنع الكتابة فوق الملفات بصمت.',
                  'محرر ماركداون متكامل مع شريط أدوات ومعاينة سريعة.',
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _buildVersionTile(
    BuildContext context, {
    required String version,
    required String date,
    required List<String> changes,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              version,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              date,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...changes.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    c,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
