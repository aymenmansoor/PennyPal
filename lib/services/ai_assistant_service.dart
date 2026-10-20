import '../models/budget.dart';
import '../models/savings_goal.dart';
import '../models/transaction_entry.dart';
import 'user_preferences_service.dart';

class AssistantReply {
  final String text;
  final List<String> suggestions;
  const AssistantReply(this.text, {this.suggestions = const []});
}

class AiAssistantService {
  AiAssistantService._();
  static final instance = AiAssistantService._();
  String? _topic;
  String? _lastAnswer;

  void reset() { _topic = null; _lastAnswer = null; }

  Future<AssistantReply> reply(String question, {required List<TransactionEntry> transactions, required List<Budget> budgets, required List<SavingsGoal> goals}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final q = question.trim().toLowerCase();
    final money = UserPreferencesService.instance.money;
    final now = DateTime.now();
    final monthTx = transactions.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
    final income = monthTx.where((t) => t.type == 'income').fold<double>(0, (a,b) => a+b.amount);
    final expense = monthTx.where((t) => t.type == 'expense').fold<double>(0, (a,b) => a+b.amount);

    AssistantReply done(String topic, String text, [List<String> next = const []]) {
      _topic = topic; _lastAnswer = text; return AssistantReply(text, suggestions: next);
    }

    final simpler = q.contains('simple') || q.contains('easier') || q.contains("don't understand") || q.contains('dont understand') || q.contains('explain again');
    if (simpler && _topic != null) {
      switch (_topic) {
        case 'goal': return done('goal', 'Sure — 1) Open Goals. 2) Tap New goal. 3) Type what you are saving for. 4) Enter the target amount and date. 5) Tap Save goal. Then update your savings whenever you add money.', ['Show my goals','How much should I save monthly?']);
        case 'budget': return done('budget', 'A budget is simply the maximum you plan to spend. Open More → Budgets, choose Overall or a category, enter your monthly limit, then save it.', ['How close am I to my budget?']);
        case 'expense': return done('expense', 'Open Home → Expense, enter the amount, choose the category, then tap Save expense.', ['How do categories work?']);
        case 'month': return done('month', 'This month: money in is ${money.format(income)}, money out is ${money.format(expense)}, so your recorded balance change is ${money.format(income-expense)}.', ['Where did I spend most?']);
        default: return AssistantReply(_lastAnswer ?? 'Tell me which part you want simplified.');
      }
    }

    if (q.contains('dark mode') || q.contains('theme') || q.contains('appearance')) {
      return done('theme', 'Open More → Appearance, then choose Light, Dark, or System. System follows your device theme.');
    }
    if (q.contains('goal')) {
      if (q.contains('my goal') || q.contains('show')) {
        if (goals.isEmpty) return done('goal', 'You do not have an active savings goal yet.', ['Create a goal']);
        final active = goals.where((g) => g.status == 'active').toList();
        if (active.isEmpty) return done('goal', 'All of your saved goals are completed or archived. You can open Goals to view history.', ['Create a new goal']);
        final g = active.first;
        return done('goal', '${g.name} is ${(g.progress*100).toStringAsFixed(0)}% complete. You have ${money.format(g.currentAmount)} saved and ${money.format(g.remaining)} left.', ['How much should I save monthly?']);
      }
      return done('goal', 'Open Goals and tap New goal. Enter a name, target amount, what you have already saved, a target date, and an optional monthly contribution. PennyPal will calculate progress and estimated completion.', ['Explain that more simply','Show my goals']);
    }
    if (q.contains('budget')) {
      final current = budgets.where((b) => b.month == '${now.year}-${now.month.toString().padLeft(2,'0')}' && b.category == 'Overall').toList();
      if (q.contains('close') || q.contains('left') || q.contains('remaining')) {
        if (current.isEmpty) return done('budget', 'You have not set an Overall budget for this month yet.', ['How do I create a budget?']);
        final limit = current.first.limitAmount;
        return done('budget', expense <= limit ? 'You have used ${(expense/limit*100).clamp(0,999).toStringAsFixed(0)}% of your monthly budget. ${money.format(limit-expense)} remains.' : 'You are ${money.format(expense-limit)} over your monthly budget.', ['Where did I spend most?']);
      }
      return done('budget', 'Open More → Budgets. Set an Overall monthly limit, then add category limits such as Food or Transport if useful. PennyPal warns you as you approach a limit.', ['Explain that more simply','How close am I to my budget?']);
    }
    if (q.contains('expense') && (q.contains('add') || q.contains('record') || q.contains('log') || q.contains('where'))) {
      return done('expense', 'From Home, tap Expense. Enter the amount, choose or accept a suggested category, add a description/date, and tap Save expense.', ['Explain that more simply']);
    }
    if (q.contains('income') && (q.contains('add') || q.contains('record') || q.contains('log') || q.contains('where'))) {
      return done('income', 'From Home, tap Income. Enter the amount, source/category, optional note and date, then save it.');
    }
    if (q.contains('where') || q.contains('largest') || q.contains('breakdown') || q.contains('spend most')) {
      final by = <String,double>{};
      for (final t in monthTx.where((t) => t.type == 'expense')) { by[t.category] = (by[t.category] ?? 0) + t.amount; }
      if (by.isEmpty) return done('month', 'You have no expenses recorded this month yet.');
      final rows = by.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
      return done('month', 'Your largest recorded expense category this month is ${rows.first.key} at ${money.format(rows.first.value)}. Open Reports & insights for the full breakdown.', ['How am I doing this month?']);
    }
    if (q.contains('this month') || q.contains('how am i') || q.contains('balance')) {
      return done('month', 'This month you recorded ${money.format(income)} income and ${money.format(expense)} expenses. Your recorded net change is ${money.format(income-expense)}.', ['Where did I spend most?','How close am I to my budget?']);
    }
    if (q.contains('report') || q.contains('insight') || q.contains('trend')) {
      return done('reports', 'Open More → Reports & insights. You can compare income and expenses, see category distribution, monthly trends, average spending and savings performance.');
    }
    if (q.contains('category') || q.contains('categor')) {
      return done('category', 'When you describe an expense, PennyPal can suggest a category such as Food or Transport. You stay in control and can change the suggestion before saving. Custom categories are under More → Custom categories.');
    }
    if (q.contains('help') || q.contains('what can you')) {
      return done('help', 'I can explain PennyPal, summarize your recorded monthly spending, check budget progress, describe your savings goals, and give educational budgeting guidance. I do not move money or provide professional financial advice.', ['How am I doing this month?','How do I create a goal?','How close am I to my budget?']);
    }
    return AssistantReply('I did not quite understand that. Try asking about your monthly spending, a budget, a savings goal, reports, categories, or how to use a PennyPal screen.', suggestions: const ['How am I doing this month?','How do I create a goal?','How do I add an expense?']);
  }
}
