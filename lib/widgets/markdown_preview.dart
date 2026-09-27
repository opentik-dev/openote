import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Verified, styled Markdown previewer supporting Arabic and ancient South Arabian Musnad script
/// with GitHub Flavored Markdown (GFM) including tables, task lists, code blocks, and strikethrough.
class MarkdownPreview extends StatelessWidget {
  final String data;
  final ScrollController? scrollController;
  final void Function(String text, String? href, String title)? onTapLink;

  const MarkdownPreview({
    super.key,
    required this.data,
    this.scrollController,
    this.onTapLink,
  });

  static const List<String> _fontFallbacks = [
    'NotoSansArabic',
    'NotoSansOldSouthArabian',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final markdownStyleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineMedium?.copyWith(
        fontFamily: 'NotoSansArabic',
        fontFamilyFallback: _fontFallbacks,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontFamily: 'NotoSansArabic',
        fontFamilyFallback: _fontFallbacks,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontFamily: 'NotoSansArabic',
        fontFamilyFallback: _fontFallbacks,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      p: theme.textTheme.bodyLarge?.copyWith(
        fontFamily: 'NotoSansArabic',
        fontFamilyFallback: _fontFallbacks,
        height: 1.7,
        fontSize: 15,
      ),
      listBullet: theme.textTheme.bodyLarge?.copyWith(
        fontFamily: 'NotoSansArabic',
        fontFamilyFallback: _fontFallbacks,
        height: 1.7,
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: _fontFallbacks,
        fontSize: 13,
        backgroundColor:
            isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB),
        color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937),
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
        ),
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      tableBorder: TableBorder.all(
        color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD1D5DB),
        width: 1,
      ),
      tableHead: const TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: 'NotoSansArabic',
        fontFamilyFallback: _fontFallbacks,
      ),
      tableBody: const TextStyle(
        fontFamily: 'NotoSansArabic',
        fontFamilyFallback: _fontFallbacks,
      ),
      tablePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    if (data.trim().isEmpty) {
      return Center(
        child: Text(
          'لا يوجد محتوى للمعاينة',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'NotoSansArabic',
            fontFamilyFallback: _fontFallbacks,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Markdown(
        data: data,
        controller: scrollController,
        selectable: true,
        extensionSet: md.ExtensionSet.gitHubFlavored,
        styleSheet: markdownStyleSheet,
        onTapLink: onTapLink ??
            (text, href, title) {
              if (href != null && href.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('الرابط: $href'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
