import 'package:salawat_app/domain/entities/dhikr_item.dart';

/// Curated adhkar with authentic texts (from the established sunnah adhkar
/// collections). Grouped by category; ids are stable so they can be referenced
/// elsewhere without renaming.
const List<DhikrItem> adhkarLibrary = [
  // ── أذكار الصباح ──
  DhikrItem(
    id: 'morning-ayat-al-kursi',
    name: 'آية الكرسي',
    text:
        'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ وَلَا يَؤُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ',
    category: DhikrCategory.morning,
    recommendedCount: 1,
  ),
  DhikrItem(
    id: 'morning-bismillah-no-harm',
    name: 'بسم الله الذي لا يضر',
    text:
        'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
    category: DhikrCategory.morning,
    recommendedCount: 3,
  ),
  DhikrItem(
    id: 'morning-subhanallahi-wa-bihamdih-100',
    name: 'سبحان الله وبحمده (مائة مرة)',
    text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    category: DhikrCategory.morning,
    recommendedCount: 100,
  ),
  DhikrItem(
    id: 'morning-radhitu-billah',
    name: 'رضيت بالله رباً',
    text:
        'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا',
    category: DhikrCategory.morning,
    recommendedCount: 3,
  ),
  DhikrItem(
    id: 'morning-hasbi-allah',
    name: 'حسبي الله لا إله إلا هو',
    text:
        'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
    category: DhikrCategory.morning,
    recommendedCount: 7,
  ),

  // ── أذكار المساء ──
  DhikrItem(
    id: 'evening-audhu-bi-kalimatillah',
    name: 'أعوذ بكلمات الله التامات',
    text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    category: DhikrCategory.evening,
    recommendedCount: 3,
  ),
  DhikrItem(
    id: 'evening-allahumma-inni-asaluka-al-afwa',
    name: 'اللهم إني أسألك العفو والعافية',
    text:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي',
    category: DhikrCategory.evening,
    recommendedCount: 1,
  ),
  DhikrItem(
    id: 'evening-allahumma-bika-asbahna',
    name: 'اللهم بك أصبحنا',
    text:
        'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
    category: DhikrCategory.evening,
    recommendedCount: 1,
  ),
  DhikrItem(
    id: 'evening-sayyid-al-istighfar',
    name: 'سيد الاستغفار',
    text:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    category: DhikrCategory.evening,
    recommendedCount: 1,
  ),

  // ── أذكار عامة ──
  DhikrItem(
    id: 'general-tasbih-tahlil-takbir',
    name: 'سبحان الله والحمد لله والله أكبر',
    text: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَاللهُ أَكْبَرُ',
    category: DhikrCategory.general,
    recommendedCount: 33,
  ),
  DhikrItem(
    id: 'general-subhanallahi-wa-bihamdih',
    name: 'سبحان الله وبحمده',
    text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    category: DhikrCategory.general,
    recommendedCount: 100,
  ),
  DhikrItem(
    id: 'general-subhanallahi-al-azim',
    name: 'سبحان الله العظيم',
    text: 'سُبْحَانَ اللَّهِ الْعَظِيمِ، وَبِحَمْدِهِ',
    category: DhikrCategory.general,
    recommendedCount: 100,
  ),
  DhikrItem(
    id: 'general-la-hawla-wa-la-quwwata',
    name: 'لا حول ولا قوة إلا بالله',
    text: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ',
    category: DhikrCategory.general,
    recommendedCount: 100,
  ),
  DhikrItem(
    id: 'general-la-ilaha-illa-allah-wahdahu',
    name: 'لا إله إلا الله وحده لا شريك له',
    text:
        'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    category: DhikrCategory.general,
    recommendedCount: 100,
  ),
  DhikrItem(
    id: 'general-salat-on-prophet',
    name: 'الصلاة على النبي ﷺ',
    text:
        'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    category: DhikrCategory.general,
    recommendedCount: 100,
  ),
];

