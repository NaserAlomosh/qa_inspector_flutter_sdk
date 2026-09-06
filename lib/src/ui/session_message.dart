import 'dart:math';

import 'package:flutter/material.dart';

import 'theme/qa_colors.dart';
import 'theme/qa_spacing.dart';

const qaEnglishMessages = <String>[
  'Every bug you catch saves someone a headache.',
  "Breaking it here means users won't break it later.",
  'Good QA turns edge cases into confidence.',
  'One more test. One less production surprise.',
  "Users may never know what you prevented. That's the point.",
  'Finding bugs before release is a feature.',
  'Trust the happy path. Test everything else.',
  'Production sleeps better when QA is thorough.',
  'Small details prevent big incidents.',
  "Today's weird edge case is tomorrow's saved incident.",
  'Quality is built by people who ask: what if?',
  'Every failed test tells us something useful.',
];

const qaArabicMessages = <String>[
  'كل Bug تكتشفه اليوم، مشكلة أقل للمستخدم بكرا.',
  'اكسرها هون قبل ما المستخدم يكسرها بالإنتاج.',
  'اختبار زيادة اليوم، مفاجأة أقل بالـ Production.',
  'التفاصيل الصغيرة هي اللي تمنع المشاكل الكبيرة.',
  'كل حالة غريبة تختبرها ممكن توفر Incident كامل.',
  'الجودة تبدأ من سؤال بسيط: طيب لو صار هيك؟',
  'المستخدم يمكن ما يعرف شو منعت، وهذا هو المطلوب.',
  'كل Failed Test بيعطينا معلومة مفيدة.',
  'الـ Happy Path سهل، الشطارة بالـ Edge Cases.',
  'QA قوي يعني Production أهدى.',
  'Bug انمسك قبل الـ Release أحسن من Incident بعده.',
  'اختبر السيناريو اللي الكل مفكر إنه مستحيل يصير.',
];

String selectQaMessage(Locale? locale, [Random? random]) {
  final messages = locale?.languageCode.toLowerCase() == 'ar' ? qaArabicMessages : qaEnglishMessages;
  return messages[(random ?? Random()).nextInt(messages.length)];
}

class QaSessionMessage extends StatelessWidget {
  const QaSessionMessage({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('qa-session-message'),
    margin: const EdgeInsets.fromLTRB(QaSpacing.lg, QaSpacing.sm, QaSpacing.lg, 0),
    padding: const EdgeInsets.symmetric(horizontal: QaSpacing.md, vertical: QaSpacing.sm),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(10)),
    child: Row(children: <Widget>[
      Icon(Icons.verified_outlined, size: 17, color: Theme.of(context).brightness == Brightness.dark ? QaColors.accentDark : QaColors.accent),
      const SizedBox(width: QaSpacing.sm),
      Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
    ]),
  );
}
