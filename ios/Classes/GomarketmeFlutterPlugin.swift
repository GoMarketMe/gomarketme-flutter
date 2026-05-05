import Flutter
import UIKit
import StoreKit
import GoMarketMeAppleCoreKit

public class GomarketmeFlutterPlugin: NSObject, FlutterPlugin {
    private var core: GoMarketMeAppleCore?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "co.gomarketme/core",
            binaryMessenger: registrar.messenger()
        )

        let instance = GomarketmeFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 15.0, *) else {
            result(
                FlutterError(
                    code: "unsupported_ios",
                    message: "GoMarketMe core requires iOS 15.0+",
                    details: nil
                )
            )
            return
        }

        guard let args = call.arguments as? [String: Any] else {
            result(
                FlutterError(
                    code: "invalid_arguments",
                    message: "initialize arguments are required",
                    details: nil
                )
            )
            return
        }

        guard let apiKey = args["apiKey"] as? String,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result(
                FlutterError(
                    code: "invalid_arguments",
                    message: "apiKey is required",
                    details: nil
                )
            )
            return
        }

        let initialConfiguration = GoMarketMeAppleCoreConfiguration(
            apiKey: apiKey,
            sdkType: args["sdkType"] as? String ?? "Flutter",
            sdkVersion: args["sdkVersion"] as? String,
            isProduction: args["isProduction"] as? Bool
        )

        let appleCore = core ?? GoMarketMeAppleCore()
        appleCore.onPurchase = { event in
            debugPrint("[GoMarketMe Flutter iOS] purchase observed by core: \(event.toDictionary())")
        }
        appleCore.onError = { error in
            debugPrint("[GoMarketMe Flutter iOS] core error: \(error.localizedDescription)")
        }

        Task {
            let prepared = await appleCore.prepareAttribution(configuration: initialConfiguration)
            appleCore.configure(prepared.configuration)
            appleCore.start()
            self.core = appleCore

            let response: [String: Any] = [
                "initialized": true,
                "platform": "ios",
                "source": prepared.configuration.sourceName,
                "affiliateMarketingData": prepared.affiliateMarketingData ?? [:]
            ]

            DispatchQueue.main.async {
                result(response)
            }
        }
    }
}
