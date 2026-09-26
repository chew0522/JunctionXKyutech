class ChatMessage {
  final String text;
  final bool fromAgent;
  final DateTime time;
  // Tappable shortcuts for a short list of options the agent just presented (e.g.
  // which room to book) — see agent.py's offer_choices tool. Null/empty for most
  // messages; the student can still type instead of tapping one.
  final List<String>? choices;
  // Detail cards for bookable options — see agent.py's offer_bookings tool.
  final List<Map<String, dynamic>>? cards;

  ChatMessage({required this.text, required this.fromAgent, DateTime? time, this.choices, this.cards})
      : time = time ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        fromAgent: json['role'] == 'agent',
        time: DateTime.parse(json['time']),
        choices: (json['choices'] as List?)?.cast<String>(),
        cards: (json['cards'] as List?)?.cast<Map<String, dynamic>>(),
      );
}
