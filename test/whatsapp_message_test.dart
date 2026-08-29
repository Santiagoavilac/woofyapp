import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:woofy/features/partners/data/money.dart';
import 'package:woofy/features/partners/data/partner_models.dart';
import 'package:woofy/features/partners/data/whatsapp_message.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('normalizePhone', () {
    test('adds the Bolivian country code to an 8 digit number', () {
      expect(WhatsappMessage.normalizePhone('70123456'), '59170123456');
    });

    test('strips spaces, dashes, parentheses and the plus sign', () {
      expect(WhatsappMessage.normalizePhone('+591 70-123456'), '59170123456');
      expect(WhatsappMessage.normalizePhone('(591) 70 123 456'), '59170123456');
      expect(WhatsappMessage.normalizePhone('591-70123456'), '59170123456');
    });

    test('keeps a number that already carries the country code', () {
      expect(WhatsappMessage.normalizePhone('59170123456'), '59170123456');
    });

    test('drops the national trunk zero', () {
      expect(WhatsappMessage.normalizePhone('070123456'), '59170123456');
    });

    test('rejects anything that is not a plausible Bolivian number', () {
      expect(WhatsappMessage.normalizePhone(null), isNull);
      expect(WhatsappMessage.normalizePhone(''), isNull);
      expect(WhatsappMessage.normalizePhone('sin numero'), isNull);
      expect(WhatsappMessage.normalizePhone('7012345'), isNull);
      expect(WhatsappMessage.normalizePhone('701234567'), isNull);
      expect(WhatsappMessage.normalizePhone('5917012345'), isNull);
    });
  });

  group('buildUri', () {
    test('points at wa.me with the encoded message', () {
      final uri = WhatsappMessage.buildUri(
        phone: '70123456',
        message: 'Hola & chau',
      );

      expect(uri, isNotNull);
      expect(uri!.host, 'wa.me');
      expect(uri.path, '/59170123456');
      // El texto viaja codificado; si el `&` se colara crudo cortaría el query.
      expect(uri.toString(), contains('Hola%20%26%20chau'));
      expect(uri.queryParameters['text'], 'Hola & chau');
    });

    test('returns null when the phone is unusable', () {
      expect(WhatsappMessage.buildUri(phone: null, message: 'Hola'), isNull);
    });
  });

  group('orderText', () {
    test('lists each line with its total and closes with the order total', () {
      final text = WhatsappMessage.orderText(
        partnerName: 'Partner Santa Cruz',
        lines: const [
          (name: 'Alimento Premium', quantity: 2, unitPriceCents: 15000),
          (name: 'Collar', quantity: 1, unitPriceCents: 4550),
        ],
        totalCents: 34550,
      );

      expect(text, contains('Partner Santa Cruz'));
      expect(text, contains('2x Alimento Premium'));
      expect(text, contains(Money.fromCents(30000)));
      expect(text, contains('1x Collar'));
      expect(text, contains(Money.fromCents(4550)));
      expect(text, contains('Total: ${Money.fromCents(34550)}'));
    });
  });

  group('reservationText', () {
    test('carries service, price and pet', () {
      final text = WhatsappMessage.reservationText(
        partnerName: 'Partner Santa Cruz',
        serviceName: 'Baño para perro',
        priceCents: 7000,
        scheduledFor: DateTime(2026, 9, 3, 15, 30),
        petName: 'Kira',
      );

      expect(text, contains('Baño para perro'));
      expect(text, contains(Money.fromCents(7000)));
      expect(text, contains('Kira'));
      expect(text, contains('15:30'));
    });
  });

  group('mapsUri', () {
    test('searches by name, address and city', () {
      const vet = Partner(
        id: 'v1',
        name: 'Partner Santa Cruz',
        slug: 'vet',
        address: 'Av. Siempre Viva 123',
        city: 'Santa Cruz',
      );

      final uri = WhatsappMessage.mapsUri(vet);
      expect(
        uri.queryParameters['query'],
        'Partner Santa Cruz, Av. Siempre Viva 123, Santa Cruz',
      );
    });
  });

  group('Money', () {
    test('formats cents without ever touching floating point sums', () {
      expect(Money.fromCents(0), contains('0,00'));
      expect(Money.fromCents(15000), contains('150,00'));
      expect(Money.fromCents(4550), contains('45,50'));
      expect(Money.fromCents(1), contains('0,01'));
    });
  });
}
