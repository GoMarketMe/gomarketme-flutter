import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GoMarketMeAffiliateMarketingData {
  final Campaign campaign;
  final Affiliate affiliate;
  final SaleDistribution saleDistribution;
  final String affiliateCampaignCode;
  final String deviceId;
  final String? offerCode;

  const GoMarketMeAffiliateMarketingData({
    required this.campaign,
    required this.affiliate,
    required this.saleDistribution,
    required this.affiliateCampaignCode,
    required this.deviceId,
    this.offerCode,
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

class GoMarketMe {
  static final GoMarketMe _instance = GoMarketMe._internal();
  static const MethodChannel _methodChannel = MethodChannel(
    'co.gomarketme/core',
  );

  static const String _sdkType = 'Flutter';
  static const String _sdkVersion = '5.0.2';

  bool _isInitializing = false;
  bool _isInitialized = false;
  GoMarketMeAffiliateMarketingData? _affiliateMarketingData;

  factory GoMarketMe() => _instance;

  GoMarketMe._internal();

  bool get isInitialized => _isInitialized;

  GoMarketMeAffiliateMarketingData? get affiliateMarketingData =>
      _affiliateMarketingData;

  Future<void> initialize(String apiKey) async {
    final trimmedApiKey = apiKey.trim();

    if (trimmedApiKey.isEmpty) {
      _log('Initialization skipped because apiKey is empty.');
      return;
    }

    if (_isInitialized || _isInitializing) {
      _log(
        'Initialization skipped because SDK is already initialized or initializing.',
      );
      return;
    }

    _isInitializing = true;

    try {
      final result = await _methodChannel
          .invokeMethod<dynamic>('initialize', <String, dynamic>{
            'apiKey': trimmedApiKey,
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
    } catch (error, stackTrace) {
      _log('Error initializing GoMarketMe: $error');
      _log(stackTrace.toString());
    } finally {
      _isInitializing = false;
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[GoMarketMe] $message');
    }
  }
}

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

String _asString(dynamic value) => value?.toString() ?? '';
