import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api.dart';
import '../clock.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/bookable_card.dart';
import '../widgets/clash_dialog.dart';
import '../widgets/chat_header.dart';
import '../widgets/chip.dart';
import '../widgets/composer.dart';
import '../widgets/message_pieces.dart';
import '../widgets/slot_picker.dart';
import 'bus_page.dart';
import 'healthcare_page.dart';

const _welcomeChips = ["What's on today?"];
const studentName = 'Alex';

class ChatScreen extends StatefulWidget {
  final VoidCallback onGoHome;

  const ChatScreen({
    super.key,
    required this.onGoHome,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiClient();
  final _scrollController = ScrollController();
  final _welcomeInputController = TextEditingController();

  final List<ChatMessage> _items = [];

  String? _bookingCardId;
  final Map<String, ProposalStatus> _proposalStatus = {};
  bool _sending = false;
  bool _errored = false;
  bool _loadingHistory = true;
  String? _lastFailedMessage;

  @override
  void initState() {
    super.initState();
    _api.fetchNow().catchError((_) => DateTime.now());
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _api.fetchHistory();
      setState(() {
        _items.insertAll(0, history);
        _loadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      // Backend not reachable yet — fall back to an empty conversation.
      setState(() => _loadingHistory = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _welcomeInputController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _items.add(ChatMessage(text: text, fromAgent: false));
      _sending = true;
      _errored = false;
    });
    _scrollToBottom();

    try {
      final reply = await _api.sendMessage(text);
      setState(() {
        _items.add(reply);
        _sending = false;
      });
    } catch (_) {
      setState(() {
        _sending = false;
        _errored = true;
        _lastFailedMessage = text;
      });
    }
    _scrollToBottom();
  }

  IconData _cardIcon(String kind) => switch (kind) {
        'clinic' => LucideIcons.stethoscope,
        'facility' => LucideIcons.landmark,
        'bus' => LucideIcons.bus,
        _ => LucideIcons.doorOpen,
      };

  String _proposalKey(Map<String, dynamic> c) => '${c['action']}|${c['id']}|${c['date']}|${c['time']}';

  Future<Map<String, dynamic>> _bookProposal(String action, String id, String date, String time) {
    return bookWithClashCheck(context, (force) => switch (action) {
          'room' => _api.bookRoom(id, date: date, time: time, force: force),
          'facility' => _api.bookFacility(id, date: date, time: time, force: force),
          _ => _api.bookClinicSlot(id, force: force),
        });
  }

  Future<void> _confirmProposal(Map<String, dynamic> c) async {
    final key = _proposalKey(c);
    setState(() => _proposalStatus[key] = ProposalStatus.booking);
    String text;
    var ok = false;
    try {
      final res = await _bookProposal(c['action'], c['id'], c['date'], c['time']);
      ok = res['success'] == true;
      text = ok
          ? 'Booked: ${c['title']} on ${c['date']} at ${c['time']}.'
          : (res['cancelled'] == true ? 'OK, I did not book it.' : res['message'] as String);
    } catch (_) {
      text = "Couldn't complete that booking. Please try again.";
    }
    setState(() {
      _proposalStatus[key] = ok ? ProposalStatus.booked : ProposalStatus.idle;
      _items.add(ChatMessage(text: text, fromAgent: true));
    });
    _scrollToBottom();
  }

  Future<void> _changeProposal(Map<String, dynamic> c) async {
    if (c['action'] == 'clinic') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => HealthcarePage(onBack: () => Navigator.of(ctx).pop())),
      );
      return;
    }
    final now = await _api.fetchNow();
    if (!mounted) return;
    final picked = await pickDateTime(context, now, resourceId: c['id'], name: c['title']);
    if (picked == null) return;
    final key = _proposalKey(c);
    setState(() => _proposalStatus[key] = ProposalStatus.booking);
    String text;
    var ok = false;
    try {
      final res = await _bookProposal(c['action'], c['id'], picked.$1, picked.$2);
      ok = res['success'] == true;
      text = ok
          ? 'Booked: ${c['title']} on ${picked.$1} at ${picked.$2}.'
          : (res['cancelled'] == true ? 'OK, I did not book it.' : res['message'] as String);
    } catch (_) {
      text = "Couldn't complete that booking. Please try again.";
    }
    setState(() {
      _proposalStatus[key] = ok ? ProposalStatus.booked : ProposalStatus.idle;
      _items.add(ChatMessage(text: text, fromAgent: true));
    });
    _scrollToBottom();
  }

  Future<void> _bookCard(Map<String, dynamic> card) async {
    if (card['kind'] == 'bus') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => BusPage(
            onBack: () => Navigator.of(ctx).pop(),
            initialBusId: card['id'],
            initialFromId: card['from_id'],
            initialToId: card['to_id'],
          ),
        ),
      );
      return;
    }
    if (card['kind'] == 'clinic') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => HealthcarePage(onBack: () => Navigator.of(ctx).pop())),
      );
      return;
    }
    final now = await _api.fetchNow();
    if (!mounted) return;
    final picked = await pickDateTime(context, now, resourceId: card['id'], name: card['title']);
    if (picked == null || !mounted) return;
    setState(() => _bookingCardId = card['id']);
    String text;
    try {
      final res = await bookWithClashCheck(
          context,
          (force) => card['kind'] == 'room'
              ? _api.bookRoom(card['id'], date: picked.$1, time: picked.$2, force: force)
              : _api.bookFacility(card['id'], date: picked.$1, time: picked.$2, force: force));
      text = res['success'] == true
          ? '${card['title']} is booked for ${picked.$1} at ${picked.$2}.'
          : (res['cancelled'] == true ? 'OK, I did not book it.' : res['message'] as String);
    } catch (_) {
      text = "Couldn't complete that booking. Please try again.";
    }
    setState(() {
      _bookingCardId = null;
      _items.add(ChatMessage(text: text, fromAgent: true));
    });
    _scrollToBottom();
  }

  void _retryLast() {
    final text = _lastFailedMessage;
    if (text != null) _sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingHistory) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            ChatHeader(onHome: widget.onGoHome),
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
          ],
        ),
      );
    }

    if (_items.isEmpty && !_sending) {
      return _welcomeView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ChatHeader(onHome: widget.onGoHome),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _items.length + (_sending ? 1 : 0) + (_errored ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _items.length) {
                  return _buildTimelineItem(index);
                }
                if (_sending && index == _items.length) {
                  return const ThinkingBubble();
                }
                return _ErrorBubble(onRetry: _retryLast);
              },
            ),
          ),
          Composer(onSend: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(int index) {
    final item = _items[index];
    final showDivider = _shouldShowDivider(index);
    final time = item.time;
    final crossedDay = index == 0 || !_sameDay(time, _timeOf(_items[index - 1]));

    final children = <Widget>[
      if (showDivider) TimeDivider(label: _formatTime(time, showDate: crossedDay)),
      ...[
        // A defensive fallback, not the expected path: the model is instructed to
        // always write real text alongside offer_choices, but LLM output isn't
        // guaranteed — an empty bubble would look broken, so skip it and show only
        // the chips rather than trust that instruction held every time.
        if (item.fromAgent && item.text.trim().isNotEmpty)
          AgentBubble(text: item.text)
        else if (!item.fromAgent)
          UserBubble(text: item.text),
        if (item.fromAgent && (item.cards?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Column(
              children: [
                for (final c in item.cards!) ...[
                  if (c['kind'] == 'proposal')
                    BookingProposalCard(
                      icon: _cardIcon(c['action']),
                      title: c['title'],
                      subtitle: c['subtitle'],
                      status: _proposalStatus[_proposalKey(c)] ?? ProposalStatus.idle,
                      onConfirm: () => _confirmProposal(c),
                      onChange: () => _changeProposal(c),
                    )
                  else
                    BookableResourceCard(
                    icon: _cardIcon(c['kind']),
                    title: c['title'],
                    subtitle: c['subtitle'],
                    available: c['available'] == true,
                    booking: _bookingCardId == c['id'],
                    onBook: () => _bookCard(c),
                    actionLabel: c['kind'] == 'bus' ? 'Track' : 'Book',
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        if (item.fromAgent && (item.choices?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.choices!
                  .map((c) => SuggestionChip(label: c, onTap: _sending ? () {} : () => _sendMessage(c)))
                  .toList(),
            ),
          ),
      ],
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  bool _shouldShowDivider(int index) {
    if (index == 0) return true;
    final prevTime = _timeOf(_items[index - 1]);
    final currTime = _timeOf(_items[index]);
    return currTime.difference(prevTime).inMinutes >= 10 || !_sameDay(prevTime, currTime);
  }

  DateTime _timeOf(ChatMessage item) => item.time;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _formatTime(DateTime time, {bool showDate = false}) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    if (!showDate) return '$hh:$mm';

    final now = demoNow();
    final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
    final datePart = isToday ? 'Today' : _weekdays[time.weekday - 1];
    return '$datePart · $hh:$mm';
  }

  Widget _welcomeView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ChatHeader(onHome: widget.onGoHome, showBorder: false),
            Expanded(
              child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome back, $studentName',
                textAlign: TextAlign.center,
                style: AppText.display.copyWith(fontSize: 30, height: 36 / 30, color: AppColors.text),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  'Ask me anything about campus — rooms, buses, events and what\'s due.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 4, 4, 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.inputLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _welcomeInputController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      style: AppText.body.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: 'Ask anything about campus…',
                        hintStyle: AppText.body.copyWith(fontSize: 16, color: AppColors.textMuted),
                      ),
                      onSubmitted: (text) {
                        if (text.trim().isEmpty) return;
                        _welcomeInputController.clear();
                        _sendMessage(text.trim());
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              final text = _welcomeInputController.text.trim();
                              if (text.isEmpty) return;
                              _welcomeInputController.clear();
                              _sendMessage(text);
                            },
                            child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _welcomeChips.map((c) => SuggestionChip(label: c, onTap: () => _sendMessage(c))).toList(),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.live, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text('Connected to 6 campus services', style: AppText.metaKey.copyWith(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBubble({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AgentBubble(text: "Sorry, I couldn't reach campus services just now. Want to try again?"),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SuggestionChip(label: 'Try again', onTap: onRetry),
        ),
      ],
    );
  }
}
