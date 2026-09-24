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
  gomarketme: ^6.0.0
```

## Usage

GoMarketMe takes only a few lines to set up.

### Step 1: Initialize

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

### Step 2: Sync Purchases (optional but recommended)

After your app completes a purchase through `in_app_purchase`, RevenueCat, Adapty, or another in-app purchase provider, call:

```dart
await goMarketMeSDK.syncAllTransactions();
```

Call it before completing a purchase when your purchase library controls that step.

### Step 3: Only for iOS consumables

If your iOS app sells consumable in-app purchases, add this key to your app's `ios/Runner/Info.plist`:

```xml
<key>SKIncludeConsumableInAppPurchaseHistory</key>
<true/>
```

That's it. GoMarketMe will automatically attribute and report affiliate sales in real time to your dashboard and your affiliates' dashboards.

## Optional

### Step 4: Referral Codes

Referral codes work alongside affiliate links when a link isn't practical, such as in conversations, podcasts, videos, events, or print.

Enable Referral Codes in one line. Place the referral UI on the first screen users see after installing the app, ideally during onboarding or immediately afterward:

```dart
GoMarketMe().showReferralCodeTrigger()
```

Customize its text, colors, typography, and layout directly in [https://gomarketme.net/marketer/settings#referral-codes](https://gomarketme.net/marketer/settings#referral-codes).

Learn more about [Referral Codes](https://gomarketme.co/referral-codes/).

### Step 5: Programmatic Affiliate Marketing

Programmatic Affiliate Marketing lets your app personalize the user experience based on the affiliate and campaign that referred the user. For example, you can customize onboarding, paywalls, offers, or in-app content.

After awaiting initialization, read `affiliateMarketingData`:

```dart
await goMarketMeSDK.initialize('API_KEY');

final data = goMarketMeSDK.affiliateMarketingData;
if (data != null) {
  debugPrint('Affiliate ID: ${data.affiliate.id}');
  debugPrint('Affiliate %: ${data.saleDistribution.affiliatePercentage}');
  debugPrint('Campaign ID: ${data.campaign.id}');
}
```

Learn more about [Programmatic Affiliate Marketing](https://gomarketme.co/programmatic-affiliate-marketing/).

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
