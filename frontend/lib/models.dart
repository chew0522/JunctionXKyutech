class ChatMessage {
  final String text;
  final bool fromAgent;
  final DateTime time;
  // Tappable shortcuts for a short list of options the agent just presented (e.g.
  // which room to book) — see agent.py's offer_choices tool. Null/empty for most
  // messages; the student can still type instead of tapping one.
  final List<String>? choices;

  ChatMessage({required this.text, required this.fromAgent, DateTime? time, this.choices})
      : time = time ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        fromAgent: json['role'] == 'agent',
        time: DateTime.parse(json['time']),
        choices: (json['choices'] as List?)?.cast<String>(),
      );
}

class NudgePill {
  final String icon;
  final String text;

  NudgePill({required this.icon, required this.text});

  factory NudgePill.fromJson(Map<String, dynamic> json) =>
      NudgePill(icon: json['icon'], text: json['text']);
}

class NudgeButton {
  final String label;
  final String style; // "primary" or "secondary"

  NudgeButton({required this.label, required this.style});

  factory NudgeButton.fromJson(Map<String, dynamic> json) =>
      NudgeButton(label: json['label'], style: json['style']);
}

class Nudge {
  final String id;
  final String title;
  final String body;
  final List<NudgePill> pills;
  final List<NudgeButton> buttons;
  final DateTime time;
  bool resolved = false;
  String? chosenLabel;

  Nudge({
    required this.id,
    required this.title,
    required this.body,
    required this.pills,
    required this.buttons,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  factory Nudge.fromJson(Map<String, dynamic> json) => Nudge(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        pills: (json['pills'] as List).map((p) => NudgePill.fromJson(p)).toList(),
        buttons: (json['buttons'] as List).map((b) => NudgeButton.fromJson(b)).toList(),
      );
}
