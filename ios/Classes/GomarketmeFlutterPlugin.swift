import Flutter
import UIKit
import StoreKit
import GoMarketMeAppleCoreKit

public class GomarketmeFlutterPlugin: NSObject, FlutterPlugin {
    public static let isDebugLoggingEnabled = false
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
        case "getReferralCodeSettings":
            handleReferralCodeSettings(result: result)
        case "showReferralCodeSheet":
            handleReferralCodeSheet(call, result: result)
        case "redeemReferralCode":
            handleRedeemReferralCode(call, result: result)
        case "initialize":
            handleInitialize(call, result: result)
        case "syncAllTransactions":
            handleSyncAllTransactions(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleReferralCodeSettings(result: @escaping FlutterResult) {
        guard let appleCore = core else {
            result(FlutterError(code: "not_initialized", message: "Initialize GoMarketMe first.", details: nil))
            return
        }
        Task {
            do {
                let settings = try await appleCore.referralCodeSettings()
                DispatchQueue.main.async { result(settings) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "referral_settings_failed", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func handleReferralCodeSheet(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let appleCore = core else {
            result(FlutterError(code: "not_initialized", message: "Initialize GoMarketMe first.", details: nil))
            return
        }
        Task { @MainActor in
            do { try await appleCore.showReferralCodeSheet(showTrigger: (call.arguments as? [String: Any])?["showTrigger"] as? Bool ?? false) { result($0) } }
            catch { result(FlutterError(code: "referral_failed", message: error.localizedDescription, details: nil)) }
        }
    }

    private func handleRedeemReferralCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let appleCore = core else {
            result(FlutterError(code: "not_initialized", message: "Initialize GoMarketMe first.", details: nil))
            return
        }
        guard let code = (call.arguments as? [String: Any])?["code"] as? String else {
            result(FlutterError(code: "invalid_arguments", message: "code is required", details: nil))
            return
        }
        Task {
            do { result(try await appleCore.redeemReferralCode(code)) }
            catch { result(Self.referralFlutterError(error)) }
        }
    }

    private static func referralFlutterError(_ error: Error) -> FlutterError {
        let rawCode: String
        let statusCode: Int?
        if let referralError = error as? GoMarketMeReferralError {
            rawCode = referralError.code
            statusCode = referralError.statusCode > 0 ? referralError.statusCode : nil
        } else if let urlError = error as? URLError {
            rawCode = urlError.code == .timedOut ? "timeout" : "network_error"
            statusCode = nil
        } else {
            rawCode = "request_failed"
            statusCode = nil
        }
        let retryable = rawCode == "network_error" || rawCode == "timeout" ||
            statusCode == 408 || statusCode == 425 || statusCode == 429 ||
            (statusCode.map { $0 >= 500 } ?? false)
        return FlutterError(
            code: "referral_code_error",
            message: error.localizedDescription,
            details: [
                "code": rawCode,
                "statusCode": statusCode.map { $0 as Any } ?? NSNull(),
                "isRetryable": retryable
            ]
        )
    }

    private func handleSyncAllTransactions(result: @escaping FlutterResult) {
        guard #available(iOS 15.0, *) else {
            result(
                FlutterError(
                    code: "unsupported_ios",
                    message: "GoMarketMe transaction sync requires iOS 15.0+",
                    details: nil
                )
            )
            return
        }

        guard let appleCore = core else {
            result(
                FlutterError(
                    code: "not_initialized",
                    message: "GoMarketMe SDK must be initialized before syncing transactions",
                    details: nil
                )
            )
            return
        }

        Task {
            let syncResult = await appleCore.syncAllTransactions()

            let response: [String: Any] = [
                "fetchedCount": syncResult.fetchedCount,
                "sentCount": syncResult.sentCount,
                "failedCount": syncResult.failedCount,
                "success": syncResult.success
            ]

            DispatchQueue.main.async {
                result(response)
            }
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
        
        if Self.isDebugLoggingEnabled {
            appleCore.onPurchase = { event in
                debugPrint("[GoMarketMe Flutter iOS] purchase observed by core: \(event.toDictionary())")
            }
            appleCore.onError = { error in
                debugPrint("[GoMarketMe Flutter iOS] core error: \(error.localizedDescription)")
            }
        }

        Task {
            appleCore.stop()
            do {
                let prepared = try await appleCore.prepareAppInstallAttribution(configuration: initialConfiguration)
                appleCore.configure(prepared.configuration)
                appleCore.start()
                self.core = appleCore

                let response: [String: Any] = [
                    "initialized": true,
                    "platform": "ios",
                    "source": prepared.configuration.sourceName,
                    "appInstallRef": prepared.configuration.appInstallRef ?? "",
                    "attributionMode": prepared.configuration.attributionMode ?? "",
                    "affiliateMarketingData": prepared.affiliateMarketingData ?? [:]
                ]

                DispatchQueue.main.async {
                    result(response)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "initialize_failed", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
}
