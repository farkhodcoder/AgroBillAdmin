import 'package:agrobilladminpc_web/core/security/idle_guard.dart';
import 'package:agrobilladminpc_web/data/repositories/admin_auth_repository.dart';
import 'package:agrobilladminpc_web/features/auth/widgets/mfa_setup_panel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kirish oqimining tarmoqsiz mantig'i: bosqich tanlash, harakatsizlik
/// taymeri va kod formati.
void main() {
  group('AuthStage — bosqich tanlash', () {
    AuthStage stage({
      bool isStaff = true,
      bool mfaRequired = false,
      bool aal2 = false,
      bool hasFactor = false,
    }) => AdminAuthRepository.stageFor(
      isStaff: isStaff,
      mfaRequired: mfaRequired,
      sessionIsAal2: aal2,
      hasVerifiedFactor: hasFactor,
    );

    test('xodim bo\'lmasa — boshqa hech narsa ahamiyatsiz', () {
      expect(stage(isStaff: false, aal2: true), AuthStage.notAdmin);
    });

    test('2FA majburiy emas va ulanmagan — to\'g\'ridan-to\'g\'ri kiradi', () {
      expect(stage(), AuthStage.ready);
    });

    test('2FA majburiy, ulanmagan — ulash ekrani', () {
      expect(stage(mfaRequired: true), AuthStage.mfaEnroll);
    });

    test('2FA ulangan — majburiy bo\'lmasa ham kod so\'raladi', () {
      expect(stage(hasFactor: true), AuthStage.mfaVerify);
      expect(stage(hasFactor: true, mfaRequired: true), AuthStage.mfaVerify);
    });

    test('kod kiritilgan sessiya (aal2) — tayyor', () {
      expect(
        stage(hasFactor: true, mfaRequired: true, aal2: true),
        AuthStage.ready,
      );
    });
  });

  group('IdleGuard', () {
    final t0 = DateTime(2026, 11, 16, 10);

    test('yozuv yo\'q bo\'lsa muddat o\'tgan hisoblanmaydi', () {
      expect(IdleGuard.isExpired(lastActivityMs: null, now: t0), isFalse);
    });

    test('30 daqiqadan kam — o\'tmagan, 30 daqiqa — o\'tgan', () {
      final last = t0.millisecondsSinceEpoch;
      expect(
        IdleGuard.isExpired(
          lastActivityMs: last,
          now: t0.add(const Duration(minutes: 29, seconds: 59)),
        ),
        isFalse,
      );
      expect(
        IdleGuard.isExpired(
          lastActivityMs: last,
          now: t0.add(const Duration(minutes: 30)),
        ),
        isTrue,
      );
    });

    test('faollik taymerni yangilaydi, sukunat chiqaradi', () {
      var now = t0;
      int? stored;
      var timedOut = 0;

      final guard = IdleGuard(
        onTimeout: () => timedOut++,
        now: () => now,
        read: () => stored,
        write: (v) => stored = v,
        clear: () => stored = null,
      );

      guard.touch(force: true);

      // 20 daqiqadan keyin harakat — sanoq qaytadan boshlanadi.
      now = t0.add(const Duration(minutes: 20));
      guard.touch();
      now = t0.add(const Duration(minutes: 45));
      guard.check();
      expect(timedOut, 0, reason: 'oxirgi faollikdan 25 daqiqa oʻtgan');

      now = t0.add(const Duration(minutes: 51));
      guard.check();
      expect(timedOut, 1);
      expect(stored, isNull, reason: 'chiqishda vaqt tozalanadi');
    });

    test('boshqa tabdagi faollik ham hisobga olinadi', () {
      var now = t0;
      int? stored = t0.millisecondsSinceEpoch;
      var timedOut = 0;

      final guard = IdleGuard(
        onTimeout: () => timedOut++,
        now: () => now,
        read: () => stored,
        write: (v) => stored = v,
        clear: () => stored = null,
      );

      // Bu tabda harakat yo'q, lekin ikkinchi tab `localStorage` ga yozdi.
      now = t0.add(const Duration(minutes: 40));
      stored = t0.add(const Duration(minutes: 35)).millisecondsSinceEpoch;
      guard.check();
      expect(timedOut, 0);
    });

    test('tez-tez harakat har safar yozmaydi', () {
      var now = t0;
      var writes = 0;

      final guard = IdleGuard(
        onTimeout: () {},
        now: () => now,
        read: () => null,
        write: (_) => writes++,
        clear: () {},
      );

      guard.touch(force: true);
      for (var i = 1; i <= 5; i++) {
        now = t0.add(Duration(seconds: i));
        guard.touch();
      }
      expect(writes, 1);

      now = t0.add(const Duration(seconds: 11));
      guard.touch();
      expect(writes, 2);
    });
  });

  group('2FA yordamchilari', () {
    test('kod — aynan 6 ta raqam', () {
      expect(isMfaCode('123456'), isTrue);
      expect(isMfaCode(' 123456 '), isTrue);
      expect(isMfaCode('12345'), isFalse);
      expect(isMfaCode('1234567'), isFalse);
      expect(isMfaCode('12a456'), isFalse);
    });

    test('QR dan data-URI prefiksi olib tashlanadi', () {
      expect(
        AdminAuthRepository.svgFromQr(
          'data:image/svg+xml;utf-8,<svg xmlns="x"></svg>',
        ),
        '<svg xmlns="x"></svg>',
      );
      expect(AdminAuthRepository.svgFromQr('<svg></svg>'), '<svg></svg>');
    });
  });
}
