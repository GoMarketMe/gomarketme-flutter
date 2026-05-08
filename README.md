<div align="center">
	<img src="https://static.gomarketme.net/assets/gmm-icon.png" alt="GoMarketMe"/>
	<br>
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
  gomarketme: ^5.0.2
```

## Usage

### ⚙️ Basic Integration

To initialize GoMarketMe, import the `gomarketme` package and initialize the SDK with your API key:

```dart
import 'package:flutter/widgets.dart';
import 'package:gomarketme/gomarketme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoMarketMe().initialize('API_KEY'); // Initialize with your API key

  runApp(const MyApp());
}
```

No further steps needed. The SDK automatically attributes and reports your affiliate sales in real time.

### ⚙️ OR - Advanced Integration ([Programmatic Affiliate Marketing](https://gomarketme.co/programmatic-affiliate-marketing/))

Use this approach for more advanced scenarios, such as:

- Affiliate-aware paywalls: Offer exclusive pricing or promotions to users acquired through affiliate campaigns.
- Personalized onboarding: For example, a social or fitness app can automatically make new users follow the influencer who referred them, strengthening engagement and maximizing the affiliate's impact.

```dart
import 'package:flutter/material.dart';
import 'package:gomarketme/gomarketme.dart';

final goMarketMeSDK = GoMarketMe();

GoMarketMeAffiliateMarketingData? affiliateData;

void _initializeGoMarketMe(String apiKey) async {
  await goMarketMeSDK.initialize(apiKey);

  affiliateData = goMarketMeSDK.affiliateMarketingData;

  if (affiliateData != null) {
    debugPrint('Affiliate ID: ${affiliateData?.affiliate.id}');
    debugPrint(
      'Affiliate %: ${affiliateData?.saleDistribution.affiliatePercentage}',
    );
    debugPrint('Campaign ID: ${affiliateData?.campaign.id}');
  } else {
    debugPrint('No GoMarketMe affiliate data found.');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _initializeGoMarketMe('API_KEY'); // Initialize with your API key

  runApp(const MyApp());
}
```

Make sure to replace `API_KEY` with your actual GoMarketMe API key. You can find it on the product onboarding page and under **Profile > API Key**.

## Support

If you run into any issues, please reach out to us at [integrations@gomarketme.co](mailto:integrations@gomarketme.co) or visit [https://gomarketme.co](https://gomarketme.co).

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
