import 'package:flutter/material.dart';
import '../state/notes_state_notifier.dart';

/// Clean color picker for assigning accent tints to notes.
class NoteColorPicker {
  static const List<Map<String, dynamic>> colors = [
    {'name': 'تلقائي', 'hex': null, 'color': Colors.transparent},
    {'name': 'مرجاني', 'hex': '#EF4444', 'color': Color(0xFFEF4444)},
    {'name': 'زمردي', 'hex': '#10B981', 'color': Color(0xFF10B981)},
    {'name': 'أزرق سماوي', 'hex': '#3B82F6', 'color': Color(0xFF3B82F6)},
    {'name': 'كهرماني', 'hex': '#F59E0B', 'color': Color(0xFFF59E0B)},
    {'name': 'بنفسجي', 'hex': '#8B5CF6', 'color': Color(0xFF8B5CF6)},
    {'name': 'تركواز', 'hex': '#14B8A6', 'color': Color(0xFF14B8A6)},
    {'name': 'وردي', 'hex': '#EC4899', 'color': Color(0xFFEC4899)},
  ];

  static void show(
    BuildContext context, {
    required String relativePath,
    required NotesStateNotifier notifier,
    String? currentColorHex,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'اختر لون تمييز الملاحظة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors.map((c) {
                  final hex = c['hex'] as String?;
                  final color = c['color'] as Color;
                  final isSelected = currentColorHex == hex;

                  return InkWell(
                    onTap: () {
                      notifier.setNoteColor(relativePath, hex);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: hex != null
                            ? color.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : (hex != null ? color : Colors.grey),
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: hex != null ? color : Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c['name'] as String,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
