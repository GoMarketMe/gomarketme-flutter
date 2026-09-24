import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoMarketMeAffiliateMarketingData {
  final Campaign campaign;
  final Affiliate affiliate;
  final SaleDistribution saleDistribution;
  final String affiliateCampaignCode;
  final String deviceId;
  final String? offerCode;
  final String? referralCode;

  const GoMarketMeAffiliateMarketingData({
    required this.campaign,
    required this.affiliate,
    required this.saleDistribution,
    required this.affiliateCampaignCode,
    required this.deviceId,
    this.offerCode,
    this.referralCode,
  });

  static GoMarketMeAffiliateMarketingData? fromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null || json.isEmpty) {
      return null;
    }

    return GoMarketMeAffiliateMarketingData(
      campaign: Campaign.fromJson(_asMap(json['campaign'])),
      affiliate: Affiliate.fromJson(_asMap(json['affiliate'])),
      saleDistribution: SaleDistribution.fromJson(
        _asMap(json['sale_distribution']),
      ),
      affiliateCampaignCode: _asString(json['affiliate_campaign_code']),
      deviceId: _asString(json['device_id']),
      offerCode: json['offer_code']?.toString(),
      referralCode: json['referral_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'campaign': campaign.toJson(),
      'affiliate': affiliate.toJson(),
      'sale_distribution': saleDistribution.toJson(),
      'affiliate_campaign_code': affiliateCampaignCode,
      'device_id': deviceId,
      'offer_code': offerCode,
      'referral_code': referralCode,
    };
  }
}

class Campaign {
  final String id;
  final String name;
  final String status;
  final String type;
  final String? publicLinkUrl;

  const Campaign({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    this.publicLinkUrl,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: _asString(json['id']),
      name: _asString(json['name']),
      status: _asString(json['status']),
      type: _asString(json['type']),
      publicLinkUrl: json['public_link_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'status': status,
      'type': type,
      'public_link_url': publicLinkUrl,
    };
  }
}

class Affiliate {
  final String id;
  final String firstName;
  final String lastName;
  final String countryCode;
  final String instagramAccount;
  final String tiktokAccount;
  final String xAccount;

  const Affiliate({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.countryCode,
    required this.instagramAccount,
    required this.tiktokAccount,
    required this.xAccount,
  });

  factory Affiliate.fromJson(Map<String, dynamic> json) {
    return Affiliate(
      id: _asString(json['id']),
      firstName: _asString(json['first_name']),
      lastName: _asString(json['last_name']),
      countryCode: _asString(json['country_code']),
      instagramAccount: _asString(json['instagram_account']),
      tiktokAccount: _asString(json['tiktok_account']),
      xAccount: _asString(json['x_account']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'country_code': countryCode,
      'instagram_account': instagramAccount,
      'tiktok_account': tiktokAccount,
      'x_account': xAccount,
    };
  }
}

class SaleDistribution {
  final String platformPercentage;
  final String affiliatePercentage;

  const SaleDistribution({
    required this.platformPercentage,
    required this.affiliatePercentage,
  });

  factory SaleDistribution.fromJson(Map<String, dynamic> json) {
    return SaleDistribution(
      platformPercentage: _asString(json['platform_percentage']),
      affiliatePercentage: _asString(json['affiliate_percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'platform_percentage': platformPercentage,
      'affiliate_percentage': affiliatePercentage,
    };
  }
}

class GoMarketMeTransactionSyncResult {
  final int fetchedCount;
  final int sentCount;
  final int failedCount;
  final bool success;

  const GoMarketMeTransactionSyncResult({
    required this.fetchedCount,
    required this.sentCount,
    required this.failedCount,
    required this.success,
  });

  factory GoMarketMeTransactionSyncResult.fromJson(Map<String, dynamic> json) {
    return GoMarketMeTransactionSyncResult(
      fetchedCount: _asInt(json['fetchedCount']),
      sentCount: _asInt(json['sentCount']),
      failedCount: _asInt(json['failedCount']),
      success: _asBool(json['success']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fetchedCount': fetchedCount,
      'sentCount': sentCount,
      'failedCount': failedCount,
      'success': success,
    };
  }
}

class GoMarketMe {
  static final GoMarketMe _instance = GoMarketMe._internal();
  static const MethodChannel _methodChannel = MethodChannel(
    'co.gomarketme/core',
  );

  static const String _sdkType = 'Flutter';
  static const String _sdkVersion = '6.0.0';

  bool _isInitialized = false;
  Future<void>? _initializationFuture;
  GoMarketMeAffiliateMarketingData? _affiliateMarketingData;
  Future<Map<String, dynamic>>? _referralCodeSettingsFuture;

  factory GoMarketMe() => _instance;

  GoMarketMe._internal();

  bool get isInitialized => _isInitialized;

  GoMarketMeAffiliateMarketingData? get affiliateMarketingData =>
      _affiliateMarketingData;

  Future<void> initialize(String apiKey) {
    final trimmedApiKey = apiKey.trim();

    if (trimmedApiKey.isEmpty) {
      _log('Initialization skipped because apiKey is empty.');
      return Future<void>.value();
    }

    if (_isInitialized) {
      _log('Initialization skipped because SDK is already initialized.');
      return Future<void>.value();
    }

    final pending = _initializationFuture;
    if (pending != null) return pending;

    final initialization = _initialize(trimmedApiKey);
    _initializationFuture = initialization;
    return initialization;
  }

  Future<void> _initialize(String apiKey) async {
    try {
      final result = await _methodChannel
          .invokeMethod<dynamic>('initialize', <String, dynamic>{
            'apiKey': apiKey,
            'sdkType': _sdkType,
            'sdkVersion': _sdkVersion,
            'isProduction': kReleaseMode,
          });

      if (result is Map) {
        final resultMap = result.map<String, dynamic>(
          (dynamic key, dynamic value) => MapEntry(key.toString(), value),
        );
        _affiliateMarketingData = GoMarketMeAffiliateMarketingData.fromJson(
          _asMap(resultMap['affiliateMarketingData']),
        );
      }

      _isInitialized = true;
      _referralCodeSettingsFuture = null;
    } catch (error, stackTrace) {
      _initializationFuture = null;
      _log('Error initializing GoMarketMe: $error');
      _log(stackTrace.toString());
    }
  }

  /// Loads and caches the marketer's complete referral-code UI settings.
  Future<Map<String, dynamic>> referralCodeSettings() async {
    if (!_isInitialized) {
      final initialization = _initializationFuture;
      if (initialization != null) await initialization;
    }
    if (!_isInitialized) {
      throw StateError(
        'Initialize GoMarketMe before loading referral settings.',
      );
    }
    return _referralCodeSettingsFuture ??= _loadReferralCodeSettings();
  }

  Future<Map<String, dynamic>> _loadReferralCodeSettings() async {
    try {
      final response = await _methodChannel.invokeMethod<dynamic>(
        'getReferralCodeSettings',
      );
      return _asMap(response);
    } catch (_) {
      // A temporary network failure must not poison the settings cache for the
      // lifetime of the app. A later trigger can try the endpoint again.
      _referralCodeSettingsFuture = null;
      rethrow;
    }
  }

  /// Returns the remotely configured referral-code trigger for placement in a
  /// Flutter widget tree. Tapping it opens the native referral sheet.
  Widget showReferralCodeTrigger({
    Key? key,
    ValueChanged<GoMarketMeAffiliateMarketingData?>? onResult,
    ValueChanged<Object>? onError,
  }) {
    return GoMarketMeReferralCodeTrigger(
      key: key,
      onResult: onResult,
      onError: onError,
    );
  }

  /// Opens the configured referral sheet. Returns null when dismissed without applying.
  Future<GoMarketMeAffiliateMarketingData?> showReferralCodeSheet({
    bool showTrigger = false,
  }) async {
    if (!_isInitialized) {
      final initialization = _initializationFuture;
      if (initialization != null) await initialization;
    }
    if (!_isInitialized) {
      throw StateError(
        'Initialize GoMarketMe before showing the referral sheet.',
      );
    }
    final response = await _methodChannel.invokeMethod<dynamic>(
      'showReferralCodeSheet',
      {'showTrigger': showTrigger},
    );
    if (response == null) return null;
    final data = GoMarketMeAffiliateMarketingData.fromJson(_asMap(response));
    _affiliateMarketingData = data;
    return data;
  }

  Future<GoMarketMeTransactionSyncResult> syncAllTransactions() async {
    if (!_isInitialized) {
      final initialization = _initializationFuture;
      if (initialization != null) await initialization;
    }
    if (!_isInitialized) {
      throw StateError(
        'GoMarketMe SDK must be initialized before syncing transactions.',
      );
    }

    final result = await _methodChannel.invokeMethod<dynamic>(
      'syncAllTransactions',
    );

    return GoMarketMeTransactionSyncResult.fromJson(_asMap(result));
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[GoMarketMe] $message');
    }
  }
}

/// A remotely configured button or link that opens the referral-code sheet.
///
/// Prefer `GoMarketMe().showReferralCodeTrigger()` in app layouts.
class GoMarketMeReferralCodeTrigger extends StatefulWidget {
  const GoMarketMeReferralCodeTrigger({super.key, this.onResult, this.onError});

  final ValueChanged<GoMarketMeAffiliateMarketingData?>? onResult;
  final ValueChanged<Object>? onError;

  @override
  State<GoMarketMeReferralCodeTrigger> createState() =>
      _GoMarketMeReferralCodeTriggerState();
}

class _GoMarketMeReferralCodeTriggerState
    extends State<GoMarketMeReferralCodeTrigger> {
  static const Map<String, dynamic> _defaults = <String, dynamic>{
    'triggerType': 'link',
    'triggerText': 'Have a referral code?',
    'triggerAlignment': 'center',
    'triggerFontSize': 15.0,
    'triggerFontWeight': '500',
    'triggerLinkColor': '#1F2937',
    'triggerLinkUnderline': false,
    'triggerButtonBackground': '#3B82F6',
    'triggerButtonTextColor': '#FFFFFF',
    'triggerButtonBorder': '#3B82F6',
    'triggerButtonBorderWidth': 1.0,
    'triggerButtonBorderRadius': 10.0,
    'triggerButtonPaddingHorizontal': 16.0,
    'triggerButtonPaddingVertical': 10.0,
  };

  late final Future<Map<String, dynamic>> _settings = _loadSettings();
  bool _opening = false;

  Future<Map<String, dynamic>> _loadSettings() async {
    try {
      final response = await GoMarketMe().referralCodeSettings();
      final marketer = _asMap(response['marketer_settings']);
      final defaults = _asMap(response['default_settings']);
      return <String, dynamic>{
        ..._defaults,
        ...(marketer.isNotEmpty ? marketer : defaults),
      };
    } catch (error) {
      GoMarketMe._log('Unable to load referral trigger settings: $error');
      return _defaults;
    }
  }

  Future<void> _openSheet() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final result = await GoMarketMe().showReferralCodeSheet();
      widget.onResult?.call(result);
    } catch (error) {
      GoMarketMe._log('Unable to open referral code sheet: $error');
      widget.onError?.call(error);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _settings,
      builder: (context, snapshot) {
        // The trigger's type, copy, size, and colors all come from the remote
        // configuration. Rendering defaults while that request is in flight
        // causes a visible link-to-button (or style) flash.
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final settings = snapshot.data ?? _defaults;
        final isLink = settings['triggerType'] == 'link';
        final radius = BorderRadius.circular(
          _number(settings['triggerButtonBorderRadius'], 10),
        );
        final textStyle = TextStyle(
          color: _color(
            settings[isLink ? 'triggerLinkColor' : 'triggerButtonTextColor'],
            isLink ? const Color(0xFF1F2937) : Colors.white,
          ),
          fontFamily: settings['family']?.toString(),
          fontSize: _number(settings['triggerFontSize'], 15, minimum: 10),
          fontWeight: _fontWeight(settings['triggerFontWeight']),
          decoration: isLink && settings['triggerLinkUnderline'] == true
              ? TextDecoration.underline
              : TextDecoration.none,
        );
        final trigger = Semantics(
          button: true,
          enabled: !_opening,
          child: Material(
            color: isLink
                ? Colors.transparent
                : _color(
                    settings['triggerButtonBackground'],
                    const Color(0xFF3B82F6),
                  ),
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: isLink
                  ? BorderSide.none
                  : BorderSide(
                      color: _color(
                        settings['triggerButtonBorder'],
                        const Color(0xFF3B82F6),
                      ),
                      width: _number(settings['triggerButtonBorderWidth'], 1),
                    ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _opening ? null : _openSheet,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: isLink
                      ? EdgeInsets.zero
                      : EdgeInsets.symmetric(
                          horizontal: _number(
                            settings['triggerButtonPaddingHorizontal'],
                            16,
                          ),
                          vertical: _number(
                            settings['triggerButtonPaddingVertical'],
                            10,
                          ),
                        ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      settings['triggerText']?.toString() ??
                          'Have a referral code?',
                      style: textStyle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        return Align(
          alignment: switch (settings['triggerAlignment']) {
            'left' => Alignment.centerLeft,
            'right' => Alignment.centerRight,
            _ => Alignment.center,
          },
          child: AnimatedOpacity(
            opacity: _opening ? 0.6 : 1,
            duration: const Duration(milliseconds: 150),
            child: trigger,
          ),
        );
      },
    );
  }
}

double _number(
  dynamic value,
  double fallback, {
  double minimum = 0,
  double maximum = 200,
}) {
  final parsed = value is num && value.isFinite
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  return (parsed ?? fallback).clamp(minimum, maximum).toDouble();
}

Color _color(dynamic value, Color fallback) {
  final raw = value?.toString().replaceFirst('#', '');
  if (raw == null || (raw.length != 6 && raw.length != 8)) return fallback;
  final parsed = int.tryParse(raw, radix: 16);
  if (parsed == null) return fallback;
  if (raw.length == 6) return Color(0xFF000000 | parsed);
  final rgb = int.parse(raw.substring(0, 6), radix: 16);
  final alpha = int.parse(raw.substring(6), radix: 16);
  return Color((alpha << 24) | rgb);
}

FontWeight _fontWeight(dynamic value) => switch (value?.toString()) {
  '100' => FontWeight.w100,
  '200' => FontWeight.w200,
  '300' => FontWeight.w300,
  '400' || 'normal' => FontWeight.w400,
  '500' => FontWeight.w500,
  '600' => FontWeight.w600,
  '700' || 'bold' => FontWeight.w700,
  '800' => FontWeight.w800,
  '900' => FontWeight.w900,
  _ => FontWeight.w500,
};

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (dynamic key, dynamic mapValue) => MapEntry(key.toString(), mapValue),
    );
  }

  return <String, dynamic>{};
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  return value?.toString().toLowerCase() == 'true';
}

String _asString(dynamic value) => value?.toString() ?? '';
