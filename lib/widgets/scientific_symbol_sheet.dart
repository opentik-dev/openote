import 'package:flutter/material.dart';
import '../utils/markdown_utils.dart';

/// Modal bottom sheet providing categorized scientific symbols, formulas,
/// and equations (Physics, Math, Chemistry, Greek) with Arabic descriptions.
class ScientificSymbolSheet extends StatelessWidget {
  final TextEditingController controller;

  const ScientificSymbolSheet({
    super.key,
    required this.controller,
  });

  static void show(BuildContext context, TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScientificSymbolSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.functions, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Text(
                    'لوحة المعادلات والرموز العلمية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'رياضيات (Math)'),
                Tab(text: 'فيزياء (Physics)'),
                Tab(text: 'كيمياء (Chemistry)'),
                Tab(text: 'رموز ويونانية (Symbols)'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGrid(context, _mathSymbols),
                  _buildGrid(context, _physicsSymbols),
                  _buildGrid(context, _chemistrySymbols),
                  _buildGrid(context, _greekSymbols),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<_SciItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return InkWell(
          onTap: () {
            MarkdownUtils.wrapSelection(
              controller,
              item.prefix,
              item.suffix,
              defaultPlaceholder: item.placeholder,
            );
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF282828) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF383838) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueAccent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Symbol sets
  static const List<_SciItem> _mathSymbols = [
    _SciItem(label: r'$x$', description: 'معادلة مضمنة', prefix: r'$', suffix: r'$', placeholder: 'x'),
    _SciItem(label: r'$$\dots$$', description: 'كتلة معادلة مستقلة', prefix: "\n\$\$\n", suffix: "\n\$\$\n", placeholder: r'f(x) = y'),
    _SciItem(label: r'\frac{a}{b}', description: 'كسر رياضي', prefix: r'$\frac{', suffix: r'}{b}$', placeholder: 'a'),
    _SciItem(label: r'\sqrt{x}', description: 'جذر تربيعي', prefix: r'$\sqrt{', suffix: r'}$', placeholder: 'x'),
    _SciItem(label: r'\sqrt[n]{x}', description: 'جذر نوني', prefix: r'$\sqrt[n]{', suffix: r'}$', placeholder: 'x'),
    _SciItem(label: r'x^{n}', description: 'أس أو قوة علوية', prefix: r'$x^{', suffix: r'}$', placeholder: '2'),
    _SciItem(label: r'x_{i}', description: 'دليل سفلي (Subscript)', prefix: r'$x_{', suffix: r'}$', placeholder: 'i'),
    _SciItem(label: r'\sum_{i=1}^{n}', description: 'مجموع (المتسلسلات)', prefix: r'$\sum_{i=1}^{n} ', suffix: r'$', placeholder: 'x_i'),
    _SciItem(label: r'\int_{a}^{b}', description: 'تكامل محدد', prefix: r'$\int_{a}^{b} ', suffix: r' dx$', placeholder: 'f(x)'),
    _SciItem(label: r'\lim_{x \to 0}', description: 'نهاية دالة', prefix: r'$\lim_{x \to 0} ', suffix: r'$', placeholder: 'f(x)'),
    _SciItem(label: r'\approx', description: 'تقريباً (يساوي تقريباً)', prefix: r'$ \approx $', suffix: ''),
    _SciItem(label: r'\pm', description: 'زائد أو ناقص', prefix: r'$ \pm $', suffix: ''),
    _SciItem(label: r'\le / \ge', description: 'أصغر/أكبر أو يساوي', prefix: r'$ \le $', suffix: ''),
    _SciItem(label: r'\infty', description: 'ما لا نهاية', prefix: r'$ \infty $', suffix: ''),
  ];

  static const List<_SciItem> _physicsSymbols = [
    _SciItem(label: r'\vec{F} = m\vec{a}', description: 'قانون نيوتن الثاني', prefix: r'$\vec{F} = m \cdot \vec{a}$', suffix: ''),
    _SciItem(label: r'E = m c^2', description: 'تكافؤ الكتلة والطاقة', prefix: r'$E = m c^2$', suffix: ''),
    _SciItem(label: r'\Delta x', description: 'التغير في المسافة', prefix: r'$\Delta x$', suffix: ''),
    _SciItem(label: r'\Delta t', description: 'الفارق الزمني', prefix: r'$\Delta t$', suffix: ''),
    _SciItem(label: r'v = \frac{\Delta x}{\Delta t}', description: 'السرعة القياسية', prefix: r'$v = \frac{\Delta x}{\Delta t}$', suffix: ''),
    _SciItem(label: r'a = \frac{\Delta v}{\Delta t}', description: 'التسارع', prefix: r'$a = \frac{\Delta v}{\Delta t}$', suffix: ''),
    _SciItem(label: r'\hbar', description: 'ثابت بلانك المختزل', prefix: r'$\hbar$', suffix: ''),
    _SciItem(label: r'\lambda', description: 'طول موجي', prefix: r'$\lambda$', suffix: ''),
    _SciItem(label: r'\rho', description: 'كثافة الكتلة', prefix: r'$\rho$', suffix: ''),
    _SciItem(label: r'\omega', description: 'تردد زاوي', prefix: r'$\omega$', suffix: ''),
    _SciItem(label: r'\mu_0', description: 'نفاذية الفراغ المغناطيسية', prefix: r'$\mu_0$', suffix: ''),
    _SciItem(label: r'\epsilon_0', description: 'سماحية الفراغ الكهربائية', prefix: r'$\epsilon_0$', suffix: ''),
  ];

  static const List<_SciItem> _chemistrySymbols = [
    _SciItem(label: r'\text{H}_2\text{O}', description: 'الماء', prefix: r'$\text{H}_2\text{O}$', suffix: ''),
    _SciItem(label: r'\text{CO}_2', description: 'ثاني أكسيد الكربون', prefix: r'$\text{CO}_2$', suffix: ''),
    _SciItem(label: r'\text{H}^+', description: 'أيون الهيدروجين (بروتون)', prefix: r'$\text{H}^+$', suffix: ''),
    _SciItem(label: r'\text{OH}^-', description: 'أيون الهيدروكسيد', prefix: r'$\text{OH}^-$', suffix: ''),
    _SciItem(label: r'\to', description: 'سهم تفاعل أمامي', prefix: r'$ \to $', suffix: ''),
    _SciItem(label: r'\rightleftharpoons', description: 'تفاعل متزن (عكسي)', prefix: r'$ \rightleftharpoons $', suffix: ''),
    _SciItem(label: r'\text{H}_2\text{SO}_4', description: 'حمض الكبريتيك', prefix: r'$\text{H}_2\text{SO}_4$', suffix: ''),
    _SciItem(label: r'\text{CH}_4', description: 'غاز الميثان', prefix: r'$\text{CH}_4$', suffix: ''),
    _SciItem(label: r'\text{C}_6\text{H}_{12}\text{O}_6', description: 'سكر الغلوكوز', prefix: r'$\text{C}_6\text{H}_{12}\text{O}_6$', suffix: ''),
  ];

  static const List<_SciItem> _greekSymbols = [
    _SciItem(label: r'\alpha', description: 'ألفا (Alpha)', prefix: r'$\alpha$', suffix: ''),
    _SciItem(label: r'\beta', description: 'بيتا (Beta)', prefix: r'$\beta$', suffix: ''),
    _SciItem(label: r'\gamma / \Gamma', description: 'غاما (Gamma)', prefix: r'$\gamma$', suffix: ''),
    _SciItem(label: r'\delta / \Delta', description: 'دلتا (Delta)', prefix: r'$\Delta$', suffix: ''),
    _SciItem(label: r'\theta', description: 'ثيتا (Theta - زاوية)', prefix: r'$\theta$', suffix: ''),
    _SciItem(label: r'\pi', description: 'باي (Pi - النسبة التقريبية)', prefix: r'$\pi$', suffix: ''),
    _SciItem(label: r'\sigma / \Sigma', description: 'سيغما (Sigma)', prefix: r'$\sigma$', suffix: ''),
    _SciItem(label: r'\tau', description: 'تاو (عزم الدوران / زمن)', prefix: r'$\tau$', suffix: ''),
    _SciItem(label: r'\omega / \Omega', description: 'أوميغا (Omega / المقاومة أوم)', prefix: r'$\Omega$', suffix: ''),
  ];
}

class _SciItem {
  final String label;
  final String description;
  final String prefix;
  final String suffix;
  final String placeholder;

  const _SciItem({
    required this.label,
    required this.description,
    required this.prefix,
    required this.suffix,
    this.placeholder = '',
  });
}
