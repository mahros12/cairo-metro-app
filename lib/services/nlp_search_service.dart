// NLP Search Service implementation for Cairo Metro
import 'dart:math' as math;

class NlpSearchService {
  static final RegExp _diacriticsRegex = RegExp(r'[\u064B-\u0652\u0670\u0640]');
  
  static const List<String> _intentPrefixes = [
    // Arabic intent & navigational phrases
    'عايز اروح ل', 'عايز اروح', 'عايزة اروح', 'عاوز اروح', 'اروح ل', 'اروح', 
    'رايح ل', 'رايح', 'رايحة', 'وديني ل', 'وديني', 'مكان', 
    'ازاي اروح ل', 'ازاي اروح', 'ازي اروح', 'اريد الذهاب الى', 
    'اريد الوصول الى', 'طريق', 'عنوان', 'قريب من', 'بجوار', 'جنب', 
    'عند', 'فين', 

    // English intent & navigational phrases
    'i want to go to the', 'i want to go to', 'how do i get to the', 
    'how do i get to', 'how to get to the', 'how to get to', 
    'how do i go to the', 'how do i go to', 'how to go to the', 'how to go to',
    'take me to the', 'take me to', 'take me towards', 'show me the way to', 
    'directions to the', 'directions to', 'heading to the', 'heading to', 
    'going to the', 'going to', 'trip to the', 'trip to', 'near the', 'near', 
    'close to the', 'close to', 'next to', 'beside', 'around', 
    'at the', 'in the', 'to the', 'to', 'at',
  ];

  /// Normalizes Arabic and English text for robust comparison
  static String normalize(String text) {
    if (text.isEmpty) return '';
    var s = text.trim().toLowerCase();

    // Remove Arabic diacritics & tatweel
    s = s.replaceAll(_diacriticsRegex, '');

    // Unify Alifs
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // Unify Taa Marbuta & Haa
    s = s.replaceAll('ة', 'ه');

    // Unify Yaa & Alif Maksura
    s = s.replaceAll('ى', 'ي');

    // Replace punctuation with spaces
    s = s.replaceAll(RegExp(r'''[,_\-\/\\.#()\[\]:'"]'''), ' ');

    // Normalize multiple spaces
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Extracts the core destination entity by stripping conversational fillers and intent prefixes
  static String extractDestinationEntity(String rawQuery) {
    var cleaned = rawQuery.trim();
    final lower = cleaned.toLowerCase();

    for (final prefix in _intentPrefixes) {
      if (lower.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length).trim();
        break;
      }
    }

    // Strip leading English articles
    final lowerCleaned = cleaned.toLowerCase();
    for (final art in ['the ', 'el ', 'al ']) {
      if (lowerCleaned.startsWith(art)) {
        cleaned = cleaned.substring(art.length).trim();
        break;
      }
    }

    return cleaned.isNotEmpty ? cleaned : rawQuery.trim();
  }

  /// Generates alternative search candidates (e.g. spelling variations like ميرلاند <-> ميريلاند)
  static List<String> generateQueryCandidates(String query) {
    final entity = extractDestinationEntity(query);
    final candidates = <String>{entity};

    // Arabic "الـ" variations
    if (entity.startsWith('ال') && entity.length > 3) {
      candidates.add(entity.substring(2));
    } else if (!entity.startsWith('ال') && _isArabic(entity)) {
      candidates.add('ال$entity');
    }

    // Specific Egyptian spelling variations: "ميرلاند" <-> "ميريلاند"
    if (entity.contains('ميرلاند')) {
      candidates.add(entity.replaceAll('ميرلاند', 'ميريلاند'));
      candidates.add('Merryland');
    } else if (entity.contains('ميريلاند')) {
      candidates.add(entity.replaceAll('ميريلاند', 'ميرلاند'));
      candidates.add('Merryland');
    } else if (entity.toLowerCase().contains('merryland') || entity.toLowerCase().contains('maryland')) {
      candidates.add('الميريلاند');
      candidates.add('الميرلاند');
    }

    return candidates.toList();
  }

  static bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Bigram similarity for typo tolerance in English and transliterated Arabic
  static double bigramSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;
    if (s1.length < 2 || s2.length < 2) return s1 == s2 ? 1.0 : 0.0;

    final pairs1 = <String>{};
    for (int i = 0; i < s1.length - 1; i++) {
      pairs1.add(s1.substring(i, i + 2));
    }

    final pairs2 = <String>{};
    for (int i = 0; i < s2.length - 1; i++) {
      pairs2.add(s2.substring(i, i + 2));
    }

    int intersection = 0;
    for (final pair in pairs1) {
      if (pairs2.contains(pair)) intersection++;
    }

    return (2.0 * intersection) / (pairs1.length + pairs2.length);
  }

  /// Calculates NLP semantic/textual similarity score between 0.0 and 1.0
  static double calculateSimilarity(String query, String target, {List<String>? aliases}) {
    final normQuery = normalize(query);
    final normTarget = normalize(target);

    if (normQuery.isEmpty || normTarget.isEmpty) return 0.0;

    final allTargets = <String>[
      normTarget,
      if (aliases != null) ...aliases.map(normalize),
    ];

    final candidates = generateQueryCandidates(query).map(normalize).toList();

    double maxScore = 0.0;

    for (final c in candidates) {
      for (final t in allTargets) {
        final score = _scoreSingle(c, t);
        if (score > maxScore) maxScore = score;
        if (maxScore >= 1.0) break;
      }
    }

    return maxScore;
  }

  static double _scoreSingle(String q, String t) {
    if (q == t) return 1.0;
    if (t.startsWith(q)) return 0.95;
    if (t.contains(q)) return 0.90;
    if (q.contains(t)) return 0.85;

    // Token level matching
    final qTokens = q.split(' ').where((s) => s.isNotEmpty).toList();
    final tTokens = t.split(' ').where((s) => s.isNotEmpty).toList();

    if (qTokens.isEmpty || tTokens.isEmpty) return 0.0;

    int matchedCount = 0;
    for (final qt in qTokens) {
      bool matched = false;
      for (final tt in tTokens) {
        if (qt == tt || tt.contains(qt) || qt.contains(tt)) {
          matched = true;
          break;
        }
        // Handle Arabic "الـ" difference
        final qtNoAl = qt.startsWith('ال') && qt.length > 3 ? qt.substring(2) : 'ال$qt';
        if (qtNoAl == tt) {
          matched = true;
          break;
        }
        // Handle minor typo with bigram
        if (bigramSimilarity(qt, tt) >= 0.70) {
          matched = true;
          break;
        }
      }
      if (matched) matchedCount++;
    }

    final tokenScore = matchedCount / math.max(qTokens.length, tTokens.length);
    if (tokenScore > 0.4) {
      return tokenScore * 0.85;
    }

    // Overall bigram score for single-word typos (e.g. Meryland vs Merryland)
    final bigram = bigramSimilarity(q, t);
    return bigram >= 0.65 ? bigram * 0.75 : 0.0;
  }
}
