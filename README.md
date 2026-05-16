<div align="center">
  <img src="https://static.gomarketme.net/assets/gmm-icon.png" alt="GoMarketMe" />
  <br />
  <h1>GoMarketMe Flutter SDK</h1>
  <p>Affiliate marketing for Flutter apps on iOS and Android.</p>
</div>

[![License: MIT][license_badge]][license_link]

## Installation

Run this command:

```bash
flutter pub add gomarketme
```

This will add a line like this to your app's `pubspec.yaml` and run an implicit `flutter pub get`:

```yaml
dependencies:
  gomarketme: ^5.0.4
```

## Usage

GoMarketMe takes only a few lines to set up.

### Step 1/3: Initialize

Import `gomarketme` and initialize the SDK with your GoMarketMe API key.

```dart
import 'package:flutter/widgets.dart';
import 'package:gomarketme/gomarketme.dart';

final goMarketMeSDK = GoMarketMe();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  goMarketMeSDK.initialize('API_KEY');

  runApp(const MyApp());
}
```

Replace `API_KEY` with your actual GoMarketMe API key. You can find it during onboarding or in **Profile > [API Key](https://gomarketme.net/marketer/profile/#account-settings)**.

### Alternative Step 1/3: Programmatic Affiliate Marketing

For apps that want to customize the user experience based on affiliate attribution, initialize GoMarketMe and read affiliate marketing data after initialization.

This enables [Programmatic Affiliate Marketing](https://gomarketme.co/programmatic-affiliate-marketing/), including affiliate-aware paywalls, personalized onboarding, promotions, and custom in-app experiences.

```dart
import 'package:flutter/material.dart';
import 'package:gomarketme/gomarketme.dart';

final goMarketMeSDK = GoMarketMe();
GoMarketMeAffiliateMarketingData? affiliateData;

Future<void> initializeGoMarketMe(String apiKey) async {
  await goMarketMeSDK.initialize(apiKey);

  final data = goMarketMeSDK.affiliateMarketingData;

  if (data == null) {
    debugPrint('No GoMarketMe affiliate data found.');
    return;
  }

  // Maps to GoMarketMe > Affiliates > Export > id column.
  debugPrint('Affiliate ID: ${data.affiliate.id}');

  // Maps to GoMarketMe > Campaigns > [Name] > Affiliate\'s Revenue Split (%).
  debugPrint('Affiliate %: ${data.saleDistribution.affiliatePercentage}');

  // Maps to GoMarketMe > Campaigns > [Name] > id in the URL.
  debugPrint('Campaign ID: ${data.campaign.id}');

  // Use this data to customize onboarding, paywalls, promotions, or in-app experiences.
  affiliateData = data;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeGoMarketMe('API_KEY');

  runApp(const MyApp());
}
```

### Step 2/3: Sync after purchase

After your app completes a purchase through `in_app_purchase`, RevenueCat, Adapty, or another in-app purchase provider, call:

```dart
await goMarketMeSDK.syncAllTransactions();
```

If your purchase library lets you decide when to finish, acknowledge, consume, or complete the transaction, call `syncAllTransactions()` first.

```dart
final purchaseParam = PurchaseParam(productDetails: productDetails);
await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);

// After you receive a successful purchase update:
await goMarketMeSDK.syncAllTransactions();
await InAppPurchase.instance.completePurchase(purchaseDetails);
```

### Step 3/3: iOS consumables only

If your iOS app sells consumable in-app purchases, add this key to your app's `ios/Runner/Info.plist`:

```xml
<key>SKIncludeConsumableInAppPurchaseHistory</key>
<true/>
```

That's it. GoMarketMe automatically attributes and reports affiliate sales.

## Platform Support

| Platform | Support | Notes |
|---|---:|---|
| iOS | ✅ | StoreKit 2, requires iOS 15+ |
| Android | ✅ | Google Play Billing v8.0.0+ |
| Flutter | ✅ | Full support on iOS and Android |

## IAP Provider Compatibility

| Provider | Support | Notes |
|---|---:|---|
| in_app_purchase | ✅ | Full support |
| RevenueCat | ✅ | Supports Apple and Google IAPs |
| Adapty | ✅ | Supports Apple and Google IAPs |

GoMarketMe works alongside `in_app_purchase`, RevenueCat, Adapty, and other IAP providers.

## Support

For integration support, contact [integrations@gomarketme.co](mailto:integrations@gomarketme.co) or visit [https://gomarketme.co](https://gomarketme.co).

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
