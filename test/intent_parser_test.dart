import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/features/reminders/models/reply_intent.dart';
import 'package:super_app/features/reminders/nlu/rule_based_intent_parser.dart';

void main() {
  const parser = RuleBasedIntentParser();

  Future<ReplyAction> action(String text, {bool confirm = false}) async =>
      (await parser.parse(text, confirmPhase: confirm)).action;

  group('first call phase', () {
    test('affirmative → do it now', () async {
      expect(await action("okay I'll do it"), ReplyAction.doItNow);
      expect(await action('sure, on it'), ReplyAction.doItNow);
    });

    test('already done → done', () async {
      expect(await action('I already did it'), ReplyAction.done);
    });

    test('postpone phrases → postpone', () async {
      expect(await action('snooze it'), ReplyAction.postpone);
      expect(await action('remind me later'), ReplyAction.postpone);
    });
  });

  group('confirmation phase', () {
    test('yes → done', () async {
      expect(await action('yes done', confirm: true), ReplyAction.done);
    });
    test('not yet → not yet', () async {
      expect(await action('not yet', confirm: true), ReplyAction.notYet);
      expect(await action("no I haven't", confirm: true), ReplyAction.notYet);
    });
  });

  group('time extraction', () {
    test('relative minutes/hours', () {
      final now = DateTime.now();
      final m = parser.extractTime('remind me in 20 minutes')!;
      expect(m.difference(now).inMinutes, inInclusiveRange(19, 21));

      final h = parser.extractTime('in 2 hours')!;
      expect(h.difference(now).inMinutes, inInclusiveRange(119, 121));
    });

    test('"in an hour" and "half an hour"', () {
      final now = DateTime.now();
      expect(parser.extractTime('in an hour')!.difference(now).inMinutes,
          inInclusiveRange(59, 61));
      expect(parser.extractTime('in half an hour')!.difference(now).inMinutes,
          inInclusiveRange(29, 31));
    });

    test('absolute clock time rolls forward if already passed', () {
      final t = parser.extractTime('at 7 am')!;
      expect(t.isAfter(DateTime.now()), isTrue);
      expect(t.minute, 0);
    });

    test('postpone reply carries the parsed time', () async {
      final intent =
          await parser.parse('postpone for 30 minutes', confirmPhase: false);
      expect(intent.action, ReplyAction.postpone);
      expect(intent.postponeTo, isNotNull);
    });
  });
}
