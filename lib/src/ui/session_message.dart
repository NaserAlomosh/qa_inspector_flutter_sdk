import 'dart:math';

import 'package:flutter/material.dart';

import 'theme/qa_spacing.dart';
import 'theme/qa_theme.dart';

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
  'The best bugs are the ones users never meet.',
  'If it can fail, QA will eventually find out how.',
  'Test the obvious. Then test what nobody thought about.',
  'A quiet production day usually started with good testing.',
  'Every edge case deserves its moment.',
  'Better to find it here than read about it in production.',
  'QA is where assumptions go to get tested.',
  'The bug you find now is the incident you avoid later.',
  'Reliable software starts with uncomfortable questions.',
  'Test what should work. Challenge what should never happen.',
  'No bug is too small when thousands of users can find it.',
  'Good testing turns uncertainty into confidence.',
  'Behind every stable release is someone who tried to break it.',
  'The weirdest scenario is often the most useful test.',
  'Every test makes the next release a little safer.',
  'Find the cracks before production does.',
  'Great QA notices what everyone else overlooks.',
  'If something feels suspicious, test it twice.',
  'A passed test builds confidence. A failed test builds knowledge.',
  'Quality is not an accident. Neither are most bugs.',
  'The happy path gets the demo. Edge cases get production.',
  'One careful test can prevent a very long meeting.',
  'Every bug found here is one less notification later.',
  'Test early. Debug calmly. Release confidently.',
  'QA turns "it should work" into "we know it works."',
  'Production is a terrible place to discover assumptions.',
  'Catch it now. Sleep better after release.',
  'Good QA protects users from things they should never notice.',
  'The smallest inconsistency can reveal the biggest problem.',
  'Testing is cheaper than explaining an incident.',
  'If nobody tested it, it is just an assumption.',
  'A release is only as strong as the cases nobody expected.',
  'Curiosity finds bugs that checklists miss.',
  'Every unexpected result is worth investigating.',
  'The job is not to prove it works. It is to discover when it does not.',
  'Bugs love assumptions. QA loves evidence.',
  'Stable releases are built one suspicious tap at a time.',
  'Keep testing. Production has enough problems already.',
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
  'أحسن Bug هو اللي المستخدم ما بلحق يشوفه.',
  'إذا في احتمال يخرب، الـ QA رح يلاقيه.',
  'اختبر الواضح، وبعدها اختبر اللي ما خطر ببال حدا.',
  'Production هادي غالباً وراه Testing مرتب.',
  'كل Edge Case بتستاهل اختبار.',
  'تلاقي المشكلة هون أحسن من تلاقيها بالـ Production.',
  'الـ QA هو المكان اللي الافتراضات فيه بتتحول لاختبارات.',
  'الـ Bug اللي تمسكه هسا هو Incident أقل بعدين.',
  'Software موثوق يبدأ بأسئلة مزعجة.',
  'اختبر اللي لازم يشتغل، وجرب اللي المفروض مستحيل يصير.',
  'ما في Bug صغير لما آلاف المستخدمين ممكن يواجهوه.',
  'Testing مرتب يحول الشك لثقة.',
  'ورا كل Release مستقر في حدا حاول يكسره قبل المستخدم.',
  'أغرب سيناريو ممكن يكون أهم Test Case.',
  'كل Test بخلي الـ Release الجاي أأمن شوي.',
  'دور على المشاكل قبل ما الـ Production يدور عليها.',
  'QA شاطر بشوف التفاصيل اللي غيره بمرق عنها.',
  'إذا حسيت في إشي مش طبيعي، اختبره مرتين.',
  'Passed Test بيعطي ثقة، Failed Test بيعطي معلومة.',
  'الجودة مش صدفة، والـ Bugs غالباً برضه مش صدفة.',
  'الـ Happy Path للـ Demo، والـ Edge Cases للـ Production.',
  'Test واحد مرتب ممكن يوفر Meeting طويل جداً.',
  'كل Bug تلاقيه هون يعني Alert أقل بعدين.',
  'اختبر بكير، صلح بهدوء، واعمل Release بثقة.',
  'الـ QA بحول "المفروض يشتغل" إلى "متأكدين إنه بشتغل".',
  'الـ Production أسوأ مكان تكتشف فيه إن افتراضك كان غلط.',
  'امسك المشكلة هسا، وارتاح بعد الـ Release.',
  'QA ممتاز بحمي المستخدم من مشاكل المفروض ما يعرف إنها موجودة.',
  'أصغر ملاحظة ممكن تكشف أكبر مشكلة.',
  'Testing أرخص بكثير من شرح Incident.',
  'إذا ما حدا اختبره، فهو مجرد افتراض.',
  'قوة الـ Release بتظهر بالسيناريوهات اللي ما حدا توقعها.',
  'الفضول بلاقي Bugs الـ Checklist ممكن ما تلاقيها.',
  'كل نتيجة غير متوقعة بتستاهل تعرف سببها.',
  'مش الهدف تثبت إنه بشتغل، الهدف تعرف متى ما بشتغل.',
  'الـ Bugs بتحب الافتراضات، والـ QA بحب الدليل.',
  'Release مستقر يبدأ من كل Tap مشكوك فيه.',
  'كمل Testing، الـ Production عنده مشاكل كفاية.',
];

String selectQaMessage(Locale? locale, [Random? random]) {
  final messages = qaEnglishMessages;
  // locale?.languageCode.toLowerCase() == 'ar' ? qaArabicMessages : qaEnglishMessages;
  return messages[(random ?? Random()).nextInt(messages.length)];
}

class QaSessionMessage extends StatelessWidget {
  const QaSessionMessage({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = QaTheme.colorsOf(context);
    return Container(
      key: const Key('qa-session-message'),
      margin: const EdgeInsets.fromLTRB(
        QaSpacing.lg,
        QaSpacing.sm,
        QaSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: QaSpacing.md,
        vertical: QaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.verified_outlined, size: 17, color: colors.accent),
          const SizedBox(width: QaSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
