
![GoMarketMe](https://static.gomarketme.net/assets/gmm-icon.png "GoMarketMe")

# GoMarketMe

[![License: MIT][license_badge]][license_link]

## Installation 💻

**❗ In order to start using GoMarketMe, you must install this SDK in your app.**

Run this command:

```sh
flutter pub add gomarketme
```

This will add a line like this to your package's pubspec.yaml (and run an implicit dart pub get):

```yaml
dependencies:
  gomarketme: ^2.0.3
```

---

## Usage 🚀

### Initialization

To initialize GoMarketMe, import the `gomarketme` package and create a new instance of `GoMarketMe`:

```dart
import 'package:gomarketme/gomarketme.dart';

GoMarketMeAffiliateMarketingData? goMarketMe;

Future<void> main() async {

  final goMarketMeSDK = GoMarketMe();
  await goMarketMeSDK.initialize('API_KEY');

  // Access the optional affiliate marketing data after initialization
  goMarketMe = goMarketMeSDK.affiliateMarketingData;

  runApp(const MyApp());
}
```

Make sure to replace API_KEY with your actual GoMarketMe API key. You can find it on the product onboarding page and under Profile > API Key.