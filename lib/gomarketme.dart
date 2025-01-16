library gomarketme;

import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class GoMarketMeAffiliateMarketingData {
  final Campaign campaign;
  final Affiliate affiliate;
  final SaleDistribution saleDistribution;
  final String affiliateCampaignCode;
  final String deviceId;
  final String? offerCode;

  GoMarketMeAffiliateMarketingData({
    required this.campaign,
    required this.affiliate,
    required this.saleDistribution,
    required this.affiliateCampaignCode,
    required this.deviceId,
    this.offerCode,
  });

  factory GoMarketMeAffiliateMarketingData.fromJson(Map<String, dynamic> json) {
    return GoMarketMeAffiliateMarketingData(
      campaign: Campaign.fromJson(json['campaign']),
      affiliate: Affiliate.fromJson(json['affiliate']),
      saleDistribution: SaleDistribution.fromJson(json['sale_distribution']),
      affiliateCampaignCode: json['affiliate_campaign_code'] ?? '',
      deviceId: json['device_id'] ?? '',
      offerCode: json['offer_code'],
    );
  }
}

class Campaign {
  final String id;
  final String name;
  final String status;
  final String type;
  final String? publicLinkUrl;

  Campaign({
    required this.id,
    required this.name,
    required this.status,
    required this.type,
    this.publicLinkUrl,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      publicLinkUrl: json['public_link_url'],
    );
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

  Affiliate({
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
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      countryCode: json['country_code'] ?? '',
      instagramAccount: json['instagram_account'] ?? '',
      tiktokAccount: json['tiktok_account'] ?? '',
      xAccount: json['x_account'] ?? '',
    );
  }
}

class SaleDistribution {
  final String platformPercentage;
  final String affiliatePercentage;

  SaleDistribution({
    required this.platformPercentage,
    required this.affiliatePercentage,
  });

  factory SaleDistribution.fromJson(Map<String, dynamic> json) {
    return SaleDistribution(
      platformPercentage: json['platform_percentage'] ?? '',
      affiliatePercentage: json['affiliate_percentage'] ?? '',
    );
  }
}

class GoMarketMe {
  static final GoMarketMe _instance = GoMarketMe._internal();
  static const String sdkType = 'Flutter';
  static const String sdkVersion = '2.0.4';
  static const String sdkInitializedKey = 'GOMARKETME_SDK_INITIALIZED';
  static const String sdkAndroidIdKey = 'GOMARKETME_ANDROID_ID';
  static const String sdkInitializationUrl =
      'https://4v9008q1a5.execute-api.us-west-2.amazonaws.com/prod/v1/sdk-initialization';
  static const String systemInfoUrl =
      'https://4v9008q1a5.execute-api.us-west-2.amazonaws.com/prod/v1/mobile/system-info';
  static const String eventUrl =
      'https://4v9008q1a5.execute-api.us-west-2.amazonaws.com/prod/v1/event';
  String _affiliateCampaignCode = '';
  String _deviceId = '';
  String _packageName = '';
  GoMarketMeAffiliateMarketingData? _affiliateMarketingData;
  GoMarketMeAffiliateMarketingData? get affiliateMarketingData =>
      _affiliateMarketingData;

  factory GoMarketMe() => _instance;

  GoMarketMe._internal();

  Future<void> initialize(String apiKey) async {
    try {
      bool isSDKInitialized = await _isSDKInitialized();
      if (!isSDKInitialized) {
        await _postSDKInitialization(apiKey);
      }
      _packageName = (await PackageInfo.fromPlatform()).packageName;
      var systemInfo = await _getSystemInfo();
      _affiliateMarketingData = await _postSystemInfo(systemInfo, apiKey);
      await _addListener(apiKey);
    } catch (e) {
      print('Error initializing GoMarketMe: $e');
    }
  }

  Future<void> _addListener(String apiKey) async {
    InAppPurchase.instance.purchaseStream.listen(
      (purchaseDetailsList) async {
        await _fetchConsolidatedPurchases(purchaseDetailsList, apiKey);
      },
      onDone: () => print('Purchase stream closed'),
      onError: (error) => print('Error in purchase stream: $error'),
    );
  }

  Future<Map<String, dynamic>> _getSystemInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    var deviceData = <String, dynamic>{};
    try {
      if (Platform.isAndroid) {
        _deviceId = await _getAndroidId();
        deviceData = _readAndroidBuildData(
            await deviceInfoPlugin.androidInfo, _deviceId);
      } else if (Platform.isIOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
        _deviceId = deviceData['identifierForVendor'];
      }
    } catch (e) {
      print('Failed to get platform version: $e');
    }

    final windowData = {
      'devicePixelRatio': window.devicePixelRatio,
      'width': window.physicalSize.width,
      'height': window.physicalSize.height
    };

    return {
      'device_info': deviceData,
      'window_info': windowData,
      'time_zone_code': DateTime.now().timeZoneName,
      'language_code': Platform.localeName
    };
  }

  Future<void> _postSDKInitialization(String apiKey) async {
    final uri = Uri.parse(sdkInitializationUrl);
    try {
      final response = await http.post(uri,
          headers: {"Content-Type": "application/json", "x-api-key": apiKey});
      if (response.statusCode == 200) {
        _markSDKAsInitialized();
      } else {
        print(
            'Failed to mark SDK as Initialized. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending SDK information to server: $e');
    }
  }

  Future<GoMarketMeAffiliateMarketingData?> _postSystemInfo(
      Map<String, dynamic> data, String apiKey) async {
    GoMarketMeAffiliateMarketingData? output;
    final uri = Uri.parse(systemInfoUrl);
    try {
      data['sdk_type'] = sdkType;
      data['sdk_version'] = sdkVersion;
      data['package_name'] = _packageName;
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json", "x-api-key": apiKey},
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        print('System Info sent successfully');
        output = GoMarketMeAffiliateMarketingData.fromJson(
            json.decode(response.body));
        _affiliateCampaignCode = output.affiliateCampaignCode;
      } else {
        print(
            'Failed to send system info. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending system info to server: $e');
    }
    return output;
  }

  String _generateAndroidId() {
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();

    String getRandomString(int length) {
      return List.generate(
              length, (index) => characters[random.nextInt(characters.length)])
          .join();
    }

    final part1 = getRandomString(4);
    final part2 = getRandomString(6);
    final part3 = getRandomString(3);

    return '$part1.$part2.$part3';
  }

  Future<String> _getAndroidId() async {
    final prefs = await SharedPreferences.getInstance();
    String? androidId = prefs.getString(sdkAndroidIdKey);

    if (androidId != null) {
      return androidId;
    } else {
      androidId = _generateAndroidId();
      await prefs.setString(sdkAndroidIdKey, androidId);

      return androidId;
    }
  }

  static Map<String, dynamic> _readAndroidBuildData(
      AndroidDeviceInfo build, String androidId) {
    return <String, dynamic>{
      'androidId': androidId,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'isPhysicalDevice': build.isPhysicalDevice,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'tags': build.tags,
      'type': build.type,
      'version.baseOS': build.version.baseOS,
      'version.codename': build.version.codename,
      'version.incremental': build.version.incremental,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.release': build.version.release,
      'version.sdkInt': build.version.sdkInt,
      'version.securityPatch': build.version.securityPatch
    };
  }

  static Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'localizedModel': data.localizedModel,
      'model': data.model,
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'utsname_machine': data.utsname.machine,
      'utsname_nodename': data.utsname.nodename,
      'utsname_release': data.utsname.release,
      'utsname_sysname': data.utsname.sysname,
      'utsname_version': data.utsname.version,
    };
  }

  Future<void> _fetchConsolidatedPurchases(
      List<PurchaseDetails> purchaseDetailsList, String apiKey) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        var data = _serializePurchaseDetails(purchase);
        data['products'] = [];
        if (purchase.productID.isNotEmpty) {
          var productResponse = await InAppPurchase.instance
              .queryProductDetails({purchase.productID});
          for (var product in productResponse.productDetails) {
            data['products'].add(_serializeProductDetails(product));
          }
        }
        await _sendEventToServer(json.encode(data), 'purchase', apiKey);
      }
    }
  }

  Future<void> _sendEventToServer(
      String body, String eventType, String apiKey) async {
    final uri = Uri.parse(eventUrl);
    try {
      var response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "x-affiliate-campaign-code": _affiliateCampaignCode,
          "x-device-id": _deviceId,
          "x-event-type": eventType,
          "x-product-type": Platform.operatingSystem,
          "x-source-name": Platform.isAndroid ? 'google_play' : 'app_store',
          "x-api-key": apiKey
        },
        body: body,
      );
      if (response.statusCode == 200) {
        print('${eventType} sent successfully');
      } else {
        print(
            'Failed to send ${eventType}. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending ${eventType} to server: $e');
    }
  }

  Map<String, dynamic> _serializePurchaseDetails(PurchaseDetails purchase) {
    return {
      'packageName': _packageName,
      'productID': purchase.productID,
      'purchaseID': purchase.purchaseID ?? '',
      'transactionDate': purchase.transactionDate ?? '',
      'status': purchase.status.index, // Enum to index
      'verificationData': {
        'localVerificationData':
            purchase.verificationData.localVerificationData,
        'serverVerificationData':
            purchase.verificationData.serverVerificationData,
        'source': purchase.verificationData.source,
      },
      'pendingCompletePurchase': purchase.pendingCompletePurchase,
      'error': purchase.error != null
          ? {
              'code': purchase.error!.code,
              'message': purchase.error!.message,
              'details': purchase.error!.details,
            }
          : {},
      'hashCode': purchase.hashCode
    };
  }

  Map<String, dynamic> _serializeProductDetails(ProductDetails product) {
    return {
      'packageName': _packageName,
      'productID': product.id,
      'productTitle': product.title,
      'productDescription': product.description,
      'productPrice': product.price,
      'productRawPrice': product.rawPrice,
      'productCurrencyCode': product.currencyCode,
      'productCurrencySymbol': product.currencySymbol,
      'hashCode': product.hashCode
    };
  }

  Future<bool> _markSDKAsInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool result = await prefs.setBool(sdkInitializedKey, true);
      return result;
    } catch (e) {
      print('Failed to save SDK initialization: $e');
      return false;
    }
  }

  Future<bool> _isSDKInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.getBool(sdkInitializedKey)!;
    } catch (e) {
      print('Failed to load SDK initialization: $e');
      return false;
    }
  }
}
