import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woofy/features/messages/data/message_models.dart';
import 'package:woofy/features/messages/presentation/widgets/date_separator.dart';
import 'package:woofy/features/messages/presentation/widgets/message_bubble.dart';
import 'package:woofy/features/messages/presentation/widgets/thread_card.dart';

void main() {
  group('el corte de día', () {
    final today = DateTime(2026, 8, 30, 15);

    test('hoy y ayer se dicen con palabras, el resto con fecha', () {
      expect(DateSeparator.label(DateTime(2026, 8, 30, 9), now: today), 'Hoy');
      expect(
        DateSeparator.label(DateTime(2026, 8, 29, 23), now: today),
        'Ayer',
      );
      expect(
        DateSeparator.label(DateTime(2026, 8, 12), now: today),
        '12/08/2026',
      );
    });

    test('dos horas del mismo día no cortan, dos días sí', () {
      expect(
        DateSeparator.splits(
          DateTime(2026, 8, 30, 1),
          DateTime(2026, 8, 30, 23),
        ),
        isFalse,
      );
      expect(
        DateSeparator.splits(DateTime(2026, 8, 30, 23), DateTime(2026, 8, 31)),
        isTrue,
      );
    });
  });

  testWidgets('a grouped bubble drops its timestamp', (tester) async {
    final message = _message(id: 'm1', at: DateTime(2026, 8, 30, 14, 5));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MessageBubble(message: message, isMine: false, showTime: false),
              MessageBubble(message: message, isMine: false),
            ],
          ),
        ),
      ),
    );

    // La hora se dice una sola vez por tanda: la burbuja del medio la calla.
    expect(find.text('30/08 14:05'), findsOneWidget);
    expect(find.text('Hola'), findsNWidgets(2));
  });

  testWidgets('an unread thread shows its counter and reads louder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThreadCard(thread: _thread(), unreadCount: 3, onTap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    final preview = tester.widget<Text>(find.text('Nos vemos el sábado'));
    expect(preview.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('a read thread has no counter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ThreadCard(thread: _thread(), onTap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsNothing);
    final preview = tester.widget<Text>(find.text('Nos vemos el sábado'));
    expect(preview.style?.fontWeight, FontWeight.normal);
  });
}

Message _message({required String id, required DateTime at}) => Message(
  id: id,
  threadId: 'thread-1',
  senderId: 'shelter-user',
  body: 'Hola',
  hiddenByAdmin: false,
  createdAt: at,
);

ConversationThread _thread() => ConversationThread(
  id: 'thread-1',
  dogId: 'dog-1',
  shelterId: 'shelter-1',
  adopterId: 'adopter-1',
  status: 'open',
  createdAt: DateTime(2026, 8, 30),
  updatedAt: DateTime(2026, 8, 30),
  dogName: 'Milo',
  shelterName: 'Woofy',
  lastMessagePreview: 'Nos vemos el sábado',
);
