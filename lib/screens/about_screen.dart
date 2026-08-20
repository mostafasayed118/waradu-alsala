import 'package:flutter/material.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';
import '../widgets/gold_divider.dart';
import '../widgets/islamic_pattern.dart';
import '../widgets/mihrab_arch.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              // Mihrab-arch framed emblem
              SizedBox(
                width: 140,
                height: 140,
                child: MihrabArch(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Positioned.fill(child: IslamicPattern(opacity: 0.06)),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.secondary,
                              width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Icon(Icons.mosque,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(AppStrings.appName, style: AppTextStyles.display(context)),
              const SizedBox(height: 8),
              Text('الإصدار 1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      )),
              const SizedBox(height: 24),
              const GoldHairlineDivider(),
              Text(AppStrings.salawat,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(context)),
              const GoldHairlineDivider(),
              const SizedBox(height: 24),
              _buildFeatureItem(context, Icons.numbers, 'عدّاد ذكي',
                  'عدّاد مستمر أو يومي مع حفظ تلقائي'),
              _buildFeatureItem(context, Icons.notifications_active,
                  'تذكيرات محلية', 'إشعارات متكررة أو في أوقات محددة'),
              _buildFeatureItem(context, Icons.phone_android, 'محلي بالكامل',
                  'لا يتطلب إنترنت أو حساب مستخدم'),
              _buildFeatureItem(context, Icons.privacy_tip, 'خصوصية تامة',
                  'لا جمع بيانات ولا تتبع'),
              const SizedBox(height: 24),
              Text('صُنع بحب لخدمة النبي ﷺ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontStyle: FontStyle.italic,
                      )),
              const SizedBox(height: 32),
              Text('جميع الحقوق محفوظة © 2024',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, IconData icon, String title, String description) {
    final gold = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gold, width: 1.2),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'ReemKufi')),
                Text(description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
