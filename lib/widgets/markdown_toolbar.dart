import 'package:flutter/material.dart';
import '../utils/markdown_utils.dart';

/// Clean, compact Markdown formatting toolbar designed to sit directly
/// above the keyboard or at the top of the editor.
class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;

  const MarkdownToolbar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _buildButton(
            context,
            label: 'B',
            tooltip: 'عريض (Bold)',
            isBold: true,
            onPressed: () => MarkdownUtils.wrapSelection(controller, '**', '**',
                defaultPlaceholder: 'نص عريض'),
          ),
          _buildButton(
            context,
            label: 'I',
            tooltip: 'مائل (Italic)',
            isItalic: true,
            onPressed: () => MarkdownUtils.wrapSelection(controller, '*', '*',
                defaultPlaceholder: 'نص مائل'),
          ),
          _buildDivider(context),
          _buildButton(
            context,
            label: 'H1',
            tooltip: 'عنوان رئيسي (Heading 1)',
            onPressed: () => MarkdownUtils.insertLinePrefix(controller, '# '),
          ),
          _buildButton(
            context,
            label: 'H2',
            tooltip: 'عنوان فرعي (Heading 2)',
            onPressed: () => MarkdownUtils.insertLinePrefix(controller, '## '),
          ),
          _buildDivider(context),
          _buildButton(
            context,
            label: '•',
            tooltip: 'قائمة نقطية (Bullet List)',
            onPressed: () => MarkdownUtils.insertLinePrefix(controller, '- '),
          ),
          _buildButton(
            context,
            label: '1.',
            tooltip: 'قائمة رقمية (Numbered List)',
            onPressed: () => MarkdownUtils.insertLinePrefix(controller, '1. '),
          ),
          _buildButton(
            context,
            icon: Icons.check_box_outlined,
            tooltip: 'مهمة (Checklist)',
            onPressed: () =>
                MarkdownUtils.insertLinePrefix(controller, '- [ ] '),
          ),
          _buildButton(
            context,
            label: '"',
            tooltip: 'اقتباس (Quote)',
            onPressed: () => MarkdownUtils.insertLinePrefix(controller, '> '),
          ),
          _buildDivider(context),
          _buildButton(
            context,
            label: '</>',
            tooltip: 'كود مضمن (Inline Code)',
            onPressed: () => MarkdownUtils.insertInlineCode(controller),
          ),
          _buildButton(
            context,
            icon: Icons.integration_instructions_outlined,
            tooltip: 'كتلة كود (Code Block)',
            onPressed: () => MarkdownUtils.insertCodeBlock(controller),
          ),
          _buildDivider(context),
          _buildButton(
            context,
            icon: Icons.link,
            tooltip: 'رابط (Link)',
            onPressed: () => MarkdownUtils.insertLink(controller),
          ),
          _buildButton(
            context,
            icon: Icons.table_chart_outlined,
            tooltip: 'جدول (Table)',
            onPressed: () {
              const tableTemplate =
                  '\n| العنوان 1 | العنوان 2 |\n| :--- | :--- |\n| عنصر 1 | عنصر 2 |\n';
              MarkdownUtils.wrapSelection(controller, tableTemplate, '');
            },
          ),
          _buildDivider(context),
          _buildButton(
            context,
            label: '𐩽',
            tooltip: 'فاصل كلمات المسند (Musnad Word Divider 𐩽)',
            onPressed: () => MarkdownUtils.wrapSelection(controller, '𐩽', ''),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    String? label,
    IconData? icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isBold = false,
    bool isItalic = false,
  }) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: icon != null
              ? Icon(icon, size: 20, color: color)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'NotoSansArabic',
                    fontFamilyFallback: const [
                      'NotoSansArabic',
                      'NotoSansOldSouthArabian',
                    ],
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                    color: color,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB),
      ),
    );
  }
}
