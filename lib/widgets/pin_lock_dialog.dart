import 'package:flutter/material.dart';

/// Modal dialog for entering or verifying a 4-digit security PIN.
class PinLockDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isSettingPin;
  final String? expectedPin;

  const PinLockDialog({
    super.key,
    this.title = 'تأكيد الرمز السري',
    this.subtitle = 'أدخل الرمز السري المكون من 4 أرقام للمتابعة',
    this.isSettingPin = false,
    this.expectedPin,
  });

  /// Helper to prompt PIN verification. Returns true if correct.
  static Future<bool> verify(BuildContext context, String expectedPin) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinLockDialog(
        expectedPin: expectedPin,
      ),
    );
    return result ?? false;
  }

  /// Helper to prompt setting a new PIN. Returns the new PIN string or null.
  static Future<String?> setPin(BuildContext context) async {
    return showDialog<String?>(
      context: context,
      builder: (_) => const PinLockDialog(
        title: 'تعيين رمز سري جديد',
        subtitle: 'أدخل 4 أرقام لتأمين التطبيق والملاحظات',
        isSettingPin: true,
      ),
    );
  }

  @override
  State<PinLockDialog> createState() => _PinLockDialogState();
}

class _PinLockDialogState extends State<PinLockDialog> {
  String _enteredPin = '';
  String? _errorMessage;

  void _onDigit(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _errorMessage = null;
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _onPinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _onPinComplete() {
    if (widget.isSettingPin) {
      Navigator.of(context).pop(_enteredPin);
    } else {
      if (widget.expectedPin == null || _enteredPin == widget.expectedPin) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'الرمز السري غير صحيح، حاول ثانية';
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Column(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 36,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final filled = index < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.grey[800] : Colors.grey[300]),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),

          const SizedBox(height: 8),
          // Numeric Keypad
          SizedBox(
            width: 240,
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                const SizedBox(height: 8),
                _buildRow(['4', '5', '6']),
                const SizedBox(height: 8),
                _buildRow(['7', '8', '9']),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 60, height: 60),
                    _buildKeypadButton('0'),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: IconButton(
                        icon: const Icon(Icons.backspace_outlined, size: 22),
                        onPressed: _onBackspace,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildKeypadButton).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282828) : const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _onDigit(digit),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
