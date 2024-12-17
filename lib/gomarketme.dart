library gomarketme;

import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoMarketMe {
  static final GoMarketMe _instance = GoMarketMe._internal();
  String sdkInitializedKey = 'GOMARKETME_SDK_INITIALIZED';
  String _affiliateCampaignCode = '';
  String _deviceId = '';
  static const String sdkInitializationUrl =
      'https://4v9008q1a5.execute-api.us-west-2.amazonaws.com/prod/v1/sdk-initialization';
  static const String systemInfoUrl =
      'https://4v9008q1a5.execute-api.us-west-2.amazonaws.com/prod/v1/mobile/system-info';
  static const String eventUrl =
      'https://4v9008q1a5.execute-api.us-west-2.amazonaws.com/prod/v1/event';

  factory GoMarketMe() => _instance;

  GoMarketMe._internal();

  Future<void> initialize(String apiKey) async {
    try {
      bool isSDKInitialized = await this.isSDKInitialized();
      if (!isSDKInitialized) {
        await _postSDKInitialization(apiKey);
      }
      var systemInfo = await _getSystemInfo();
      await _postSystemInfo(systemInfo, apiKey);
      await _addListener(apiKey);
    } catch (e) {
      print('Error initializing GoMarketMe: $e');
    }
  }

  Future<void> _addListener(String apiKey) async {
    InAppPurchase.instance.purchaseStream.listen(
      (purchaseDetailsList) async {
        if (_affiliateCampaignCode.isNotEmpty) {
          var productIds = await _fetchPurchases(purchaseDetailsList, apiKey);
          await _fetchPurchaseProducts(productIds, apiKey);
        }
      },
      onDone: () => print('Purchase stream closed'),
      onError: (error) => print('Error in purchase stream: $error'),
    );
  }

  static Future<Map<String, dynamic>> _getSystemInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    var deviceData = <String, dynamic>{};
    try {
      if (Platform.isAndroid) {
        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      } else if (Platform.isIOS) {
        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
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
        markSDKAsInitialized();
      } else {
        print(
            'Failed to mark SDK as Initialized. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending SDK information to server: $e');
    }
  }

  Future<void> _postSystemInfo(
      Map<String, dynamic> systemInfo, String apiKey) async {
    final uri = Uri.parse(systemInfoUrl);
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json", "x-api-key": apiKey},
        body: json.encode(systemInfo),
      );
      if (response.statusCode == 200) {
        print('System Info sent successfully');
        var responseData = json.decode(response.body);
        if (responseData.containsKey('affiliate_campaign_code')) {
          _affiliateCampaignCode = responseData['affiliate_campaign_code'];
        }
        if (responseData.containsKey('device_id')) {
          _deviceId = responseData['device_id'];
        }
      } else {
        print(
            'Failed to send system info. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending system info to server: $e');
    }
  }

  static Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'androidId': build.id,
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

  Future<List<String>> _fetchPurchases(
      List<PurchaseDetails> purchaseDetailsList, String apiKey) async {
    var productIds = <String>[];
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _sendEventToServer(
            json.encode(serializePurchaseDetails(purchase)),
            'purchase',
            apiKey);
        if (purchase.productID.isNotEmpty &&
            !productIds.contains(purchase.productID)) {
          productIds.add(purchase.productID);
        }
      }
    }
    return productIds;
  }

  Future<void> _fetchPurchaseProducts(
      List<String> productIds, String apiKey) async {
    var response =
        await InAppPurchase.instance.queryProductDetails(productIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      await _sendEventToServer(
          json.encode({'notFoundIDs': response.notFoundIDs.join(',')}),
          'product',
          apiKey);
    }
    for (var product in response.productDetails) {
      await _sendEventToServer(
          json.encode(serializeProductDetails(product)), 'product', apiKey);
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

  Map<String, dynamic> serializePurchaseDetails(PurchaseDetails purchase) {
    return {
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

  Map<String, dynamic> serializeProductDetails(ProductDetails product) {
    return {
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

  Future<bool> markSDKAsInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool result = await prefs.setBool(sdkInitializedKey, true);
      return result;
    } catch (e) {
      print('Failed to save SDK initialization: $e');
      return false;
    }
  }

  Future<bool> isSDKInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.getBool(sdkInitializedKey)!;
    } catch (e) {
      print('Failed to load SDK initialization: $e');
      return false;
    }
  }
}
