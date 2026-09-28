import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomarketme/gomarketme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('co.gomarketme/core');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final affiliate = <String, dynamic>{
    'affiliate_campaign_code': 'campaign',
    'device_id': 'device',
    'campaign': <String, dynamic>{'id': 'campaign'},
    'affiliate': <String, dynamic>{'id': 'creator'},
    'sale_distribution': <String, dynamic>{},
    'referral_code': 'FRIEND20',
  };

  test(
    'referral result updates public data; cancellation and errors preserve it',
    () async {
      await expectLater(GoMarketMe().showReferralCodeSheet(), throwsStateError);
      final initialization = Completer<Map<String, dynamic>>();
      var sheetCalls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'initialize') return initialization.future;
        expect(call.method, 'showReferralCodeSheet');
        sheetCalls += 1;
        expect(call.arguments, {'showTrigger': true});
        return affiliate;
      });
      final initializationFuture = GoMarketMe().initialize('test-key');
      final resultFuture = GoMarketMe().showReferralCodeSheet(
        showTrigger: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(sheetCalls, 0);
      initialization.complete({'initialized': true});
      await initializationFuture;
      final result = await resultFuture;
      expect(sheetCalls, 1);
      expect(result?.affiliate.id, 'creator');
      expect(result?.referralCode, 'FRIEND20');
      expect(result?.toJson()['referral_code'], 'FRIEND20');
      expect(GoMarketMe().affiliateMarketingData, same(result));

      messenger.setMockMethodCallHandler(channel, (_) async => null);
      expect(await GoMarketMe().showReferralCodeSheet(), isNull);
      expect(GoMarketMe().affiliateMarketingData, same(result));

      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'referral_failed');
      });
      await expectLater(
        GoMarketMe().showReferralCodeSheet(),
        throwsA(isA<PlatformException>()),
      );
      expect(GoMarketMe().affiliateMarketingData, same(result));

      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
          code: 'referral_code_error',
          message: 'Referral request failed (invalid_code, HTTP 422).',
          details: <String, dynamic>{
            'code': 'invalid_code',
            'statusCode': 422,
            'isRetryable': false,
          },
        );
      });
      await expectLater(
        GoMarketMe().redeemReferralCode('NOT-A-CODE'),
        throwsA(
          isA<GoMarketMeReferralCodeException>()
              .having(
                (error) => error.code,
                'code',
                GoMarketMeReferralCodeErrorCode.invalidCode,
              )
              .having((error) => error.rawCode, 'rawCode', 'invalid_code')
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.isRetryable, 'isRetryable', false),
        ),
      );
      expect(GoMarketMe().affiliateMarketingData, same(result));
      messenger.setMockMethodCallHandler(channel, null);
    },
  );

  test(
    'programmatic redemption returns metadata and updates public data',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'initialize')
          return <String, dynamic>{'initialized': true};
        expect(call.method, 'redeemReferralCode');
        expect(call.arguments, <String, dynamic>{'code': 'JAKE10'});
        return <String, dynamic>{
          ...affiliate,
          'campaign': <String, dynamic>{
            'id': 'campaign',
            'metadata': <String, dynamic>{'paywall_variant': 'creator-offer'},
          },
          'affiliate': <String, dynamic>{
            'id': 'creator',
            'metadata': <String, dynamic>{
              'profile_image_url': 'https://example.com/jake.jpg',
            },
          },
          'affiliate_campaign': <String, dynamic>{
            'metadata': <String, dynamic>{
              'offers': <String, dynamic>{
                'ios': <String, dynamic>{
                  'monthly': <String, dynamic>{'code': 'MONTHLY10'},
                },
              },
            },
          },
          'referral_code': 'JAKE10',
        };
      });
      await GoMarketMe().initialize('test-key');
      final result = await GoMarketMe().redeemReferralCode('JAKE10');
      expect(result.campaign.metadata['paywall_variant'], 'creator-offer');
      expect(
        result.affiliate.metadata['profile_image_url'],
        'https://example.com/jake.jpg',
      );
      expect(
        ((result.affiliateCampaign.metadata['offers'] as Map)['ios']
            as Map)['monthly'],
        <String, dynamic>{'code': 'MONTHLY10'},
      );
      expect(GoMarketMe().affiliateMarketingData, same(result));
      messenger.setMockMethodCallHandler(channel, null);
    },
  );

  testWidgets('configured referral trigger opens the native sheet', (
    tester,
  ) async {
    var sheetCalls = 0;
    var settingsCalls = 0;
    Object? triggerError;
    GoMarketMeAffiliateMarketingData? delivered;
    final settings = Completer<Map<String, dynamic>>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
          return <String, dynamic>{'initialized': true};
        case 'getReferralCodeSettings':
          settingsCalls += 1;
          return settings.future;
        case 'showReferralCodeSheet':
          sheetCalls += 1;
          expect(call.arguments, {'showTrigger': false});
          return affiliate;
      }
      fail('Unexpected method ${call.method}');
    });
    await GoMarketMe().initialize('test-key');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoMarketMe().showReferralCodeTrigger(
            onResult: (result) => delivered = result,
            onError: (error) => triggerError = error,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(settingsCalls, 1);
    expect(triggerError, isNull);
    expect(find.text('Have a referral code?'), findsNothing);
    expect(find.byType(InkWell), findsNothing);

    settings.complete(<String, dynamic>{
      'default_settings': <String, dynamic>{},
      'marketer_settings': <String, dynamic>{
        'triggerType': 'button',
        'triggerText': 'Use a creator code',
        'triggerAlignment': 'right',
        'triggerButtonBackground': '#123456',
        'triggerButtonTextColor': '#FFFFFF',
        'triggerButtonBorder': '#654321',
        'triggerButtonBorderWidth': 2,
        'triggerButtonBorderRadius': 11,
        'triggerButtonPaddingHorizontal': 18,
        'triggerButtonPaddingVertical': 9,
        'triggerFontSize': 16,
        'triggerFontWeight': '600',
      },
    });
    await tester.pumpAndSettle();
    expect(triggerError, isNull);

    expect(find.text('Have a referral code?'), findsNothing);
    expect(find.text('Use a creator code'), findsOneWidget);
    expect(
      tester.widget<Align>(find.byType(Align).last).alignment,
      Alignment.centerRight,
    );
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('Use a creator code'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, const Color(0xFF123456));

    await tester.tap(find.text('Use a creator code'));
    await tester.pumpAndSettle();
    expect(sheetCalls, 1);
    expect(delivered?.referralCode, 'FRIEND20');
    messenger.setMockMethodCallHandler(channel, null);
  });
}
