class ExpenseCategorizerService {
  ExpenseCategorizerService._();
  static final instance = ExpenseCategorizerService._();

  static const _rules = <String, List<String>>{
    'Food': ['food','restaurant','cafe','coffee','pizza','burger','lunch','dinner','breakfast','grocery','groceries','mart','mcdonald','kfc'],
    'Transport': ['uber','careem','taxi','bus','train','fuel','petrol','diesel','parking','transport','metro'],
    'Education': ['school','college','university','course','book','tuition','exam','stationery','education'],
    'Shopping': ['shop','shopping','clothes','shoes','amazon','daraz','mall','store'],
    'Entertainment': ['netflix','spotify','cinema','movie','game','concert','entertainment'],
    'Bills': ['bill','electric','electricity','gas','water','internet','wifi','mobile','phone','rent','subscription'],
    'Savings': ['save','saving','savings','deposit','investment'],
  };

  String? suggest(String description) {
    final text = description.trim().toLowerCase();
    if (text.length < 3) return null;
    String? best;
    var bestScore = 0;
    for (final entry in _rules.entries) {
      var score = 0;
      for (final keyword in entry.value) {
        if (text.contains(keyword)) score += keyword.length;
      }
      if (score > bestScore) { bestScore = score; best = entry.key; }
    }
    return bestScore > 0 ? best : null;
  }
}
