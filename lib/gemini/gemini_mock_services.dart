import 'dart:math';

class MockGeminiService {
  final Random _r = Random();

  final List<String> prefixes = [
    'Hope',
    'Grace',
    'Mercy',
    'Faith',
    'Peace',
    'Divine',
    'Helping Hands',
    'Good Shepherd',
    'Compassion',
    'Restoration',
    'Salvation',
    'Kingdom Care',
    'CarePoint',
    'Harvest Help',
    'New Life',
    'Blessed Home',
  ];

  final Map<String, List<String>> categoryMap = {
    'orphanage': ['Orphanage', 'Children Home'],
    'school': ['School', 'Academy'],
    'shelter': ['Shelter', 'Safe Haven'],
    'juvenile': ['Youth Center'],
    'remand': ['Remand Home'],
    'kitchen': ['Community Kitchen'],
    'church': ['Outreach Ministry'],
    'prison': ['Correctional Center'],
    'food': ['Food Bank'],
    'charity': ['Charity Center'],
    'old': ['Old People\'s Home'],
    'ngo': ['NGO Center'],
    'rehab': ['Rehab Center'],
  };

  bool wantsContact(String text) {
    text = text.toLowerCase();
    return text.contains('phone') ||
        text.contains('contact') ||
        text.contains('number') ||
        text.contains('call');
  }

  String detectCategory(String text) {
    text = text.toLowerCase();

    if (text.contains('orphan')) return 'orphanage';
    if (text.contains('school')) return 'school';
    if (text.contains('shelter')) return 'shelter';
    if (text.contains('juvenile')) return 'juvenile';
    if (text.contains('remand')) return 'remand';
    if (text.contains('kitchen')) return 'kitchen';
    if (text.contains('church')) return 'church';
    if (text.contains('prison')) return 'prison';
    if (text.contains('food')) return 'food';
    if (text.contains('charity')) return 'charity';
    if (text.contains('old')) return 'old';
    if (text.contains('ngo')) return 'ngo';
    if (text.contains('rehab')) return 'rehab';

    return 'charity';
  }

  String extractLocation(String text) {
    final List<String> parts = text.split(' ');
    if (parts.length >= 2) {
      return parts.sublist(parts.length - 2).join(' ');
    }
    return text;
  }

  String randomDistance() {
    final double km = _r.nextDouble() * 9 + 1;
    final int min = _r.nextInt(20) + 5;
    return '${km.toStringAsFixed(1)} km ($min mins)';
  }

  String randomPhone() {
    return '+234 8${_r.nextInt(90) + 10} '
        '${_r.nextInt(900) + 100} '
        '${_r.nextInt(9000) + 1000}';
  }

  String randomName(String category, String location) {
    final String prefix = prefixes[_r.nextInt(prefixes.length)];
    final List<String> suffixList = categoryMap[category] ?? ['Center'];
    final String suffix = suffixList[_r.nextInt(suffixList.length)];
    return '$prefix $suffix, $location';
  }

  Future<String> getSuggestion(String text) async {
    await Future.delayed(const Duration(seconds: 2));

    final String category = detectCategory(text);
    final String location = extractLocation(text);
    final bool needContact = wantsContact(text);

    final List<String> results = [];

    for (int i = 0; i < 2; i++) {
      final String name = randomName(category, location);
      final String dist = randomDistance();

      String line = '- $name - $dist away';

      if (needContact) {
        final String phone = randomPhone();
        line += '\n   Phone: $phone (from internet, may be outdated)';
      }

      results.add(line);
    }

    return 'Here are nearby $category locations:\n\n${results.join('\n\n')}';
  }
}
