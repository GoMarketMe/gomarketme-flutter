import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomarketme/gomarketme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('co.gomarketme/core');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final sdk = GoMarketMe();
  final response = <String, dynamic>{
    'initialized': true,
    'appInstallRef': 'random-install',
    'attributionMode': 'LinksOnly',
  };
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'install identity replaces legacy device ID in returned attribution',
    () {
      final data = GoMarketMeAffiliateMarketingData.fromJson({
        'affiliate_campaign_code': 'campaign',
        'app_install_ref': 'random-install',
        'device_id': 'legacy-device',
        'campaign': {},
        'affiliate': {},
        'sale_distribution': {},
      })!;
      expect(data.appInstallRef, 'random-install');
      expect(data.deviceId, isEmpty);
      expect(data.toJson()['app_install_ref'], 'random-install');
      expect(data.toJson().containsKey('device_id'), isFalse);
      expect(
        GoMarketMeAffiliateMarketingData.fromJson({
          'affiliate_campaign_code': '',
          'app_install_ref': 'random-install',
        }),
        isNull,
      );
    },
  );

  test('legacy attribution data remains readable', () {
    final data = GoMarketMeAffiliateMarketingData.fromJson({
      'affiliate_campaign_code': 'campaign',
      'device_id': 'old-device',
    })!;
    expect(data.appInstallRef, isNull);
    expect(data.deviceId, 'old-device');
  });

  test(
    'each initialize refreshes mode and settings with the 6.0.2 observation',
    () async {
      var calls = 0;
      var settingsCalls = 0;
      var notifications = 0;
      void changed() {
        notifications++;
      }

      sdk.addListener(changed);
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getReferralCodeSettings') {
          settingsCalls++;
          return {'marketer_settings': {}};
        }
        expect(call.arguments['sdkType'], 'Flutter');
        expect(call.arguments['sdkVersion'], '6.0.2');
        expect(call.arguments['isProduction'], false);
        calls++;
        return {
          ...response,
          'attributionMode': calls == 1
              ? 'LinksAndReferralCodes'
              : 'ReferralCodesOnly',
        };
      });
      await sdk.initialize('test');
      await sdk.referralCodeSettings();
      await sdk.referralCodeSettings();
      expect((sdk.attributionMode == 'ReferralCodesOnly'), false);
      await sdk.initialize('test');
      await sdk.referralCodeSettings();
      expect(calls, 2);
      expect(settingsCalls, 2);
      expect(notifications, 2);
      expect((sdk.attributionMode == 'ReferralCodesOnly'), true);
      expect(sdk.appInstallRef, 'random-install');
      sdk.removeListener(changed);
    },
  );

  test('concurrent initialization is coalesced', () async {
    var calls = 0;
    final result = Completer<Map<String, dynamic>>();
    messenger.setMockMethodCallHandler(channel, (_) {
      calls++;
      return result.future;
    });
    final first = sdk.initialize('test');
    final second = sdk.initialize('test');
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    result.complete(response);
    await Future.wait([first, second]);
  });

  test('failed configuration is not ready and can be retried', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {...response, 'attributionMode': 'unknown'},
    );
    await expectLater(sdk.initialize('test'), throwsStateError);
    expect(sdk.isInitialized, false);
    messenger.setMockMethodCallHandler(channel, (_) async => response);
    await sdk.initialize('test');
    expect(sdk.isInitialized, true);
  });

  test('app resume refreshes configuration', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return response;
    });
    await sdk.initialize('test');
    sdk.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 2);
  });
}
