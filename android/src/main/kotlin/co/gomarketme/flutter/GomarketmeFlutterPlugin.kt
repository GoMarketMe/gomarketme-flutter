package co.gomarketme.flutter

import android.content.Context
import android.app.Activity
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import android.util.Log
import co.gomarketme.core.GoMarketMeGoogleCore
import co.gomarketme.core.GoMarketMeGoogleCoreConfiguration
import co.gomarketme.core.GoMarketMeReferralException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class GomarketmeFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private var activity: Activity? = null
    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private var core: GoMarketMeGoogleCore? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        core?.stop()
        core = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getReferralCodeSettings" -> getReferralCodeSettings(result)
            "showReferralCodeSheet" -> showReferralCodeSheet(call, result)
            "redeemReferralCode" -> redeemReferralCode(call, result)
            "initialize" -> initialize(call, result)
            "syncAllTransactions" -> syncAllTransactions(result)
            else -> result.notImplemented()
        }
    }

    private fun getReferralCodeSettings(result: MethodChannel.Result) {
        val googleCore = core
        if (googleCore == null) {
            result.error("not_initialized", "Initialize GoMarketMe first.", null)
            return
        }
        scope.launch {
            try { result.success(googleCore.referralCodeSettings()) }
            catch (error: Exception) { result.error("referral_settings_failed", error.message, null) }
        }
    }

    private fun showReferralCodeSheet(call: MethodCall, result: MethodChannel.Result) {
        val googleCore = core
        val host = activity
        if (googleCore == null || host == null) {
            result.error("unavailable", "Initialize GoMarketMe and attach an Activity first.", null)
            return
        }
        scope.launch {
            try { googleCore.showReferralCodeSheet(host, call.argument<Boolean>("showTrigger") ?: false) { result.success(it) } }
            catch (error: Exception) { result.error("referral_failed", error.message, null) }
        }
    }

    private fun redeemReferralCode(call: MethodCall, result: MethodChannel.Result) {
        val googleCore = core
        if (googleCore == null) {
            result.error("not_initialized", "Initialize GoMarketMe first.", null)
            return
        }
        val code = call.argument<String>("code")
        if (code == null) {
            result.error("invalid_arguments", "code is required", null)
            return
        }
        scope.launch {
            try { result.success(googleCore.redeemReferralCode(code)) }
            catch (error: Exception) {
                val rawCode = when (error) {
                    is GoMarketMeReferralException -> error.code
                    is java.net.SocketTimeoutException -> "timeout"
                    is java.io.IOException -> "network_error"
                    else -> "request_failed"
                }
                val statusCode = (error as? GoMarketMeReferralException)
                    ?.statusCode
                    ?.takeIf { it > 0 }
                val isRetryable = rawCode == "network_error" || rawCode == "timeout" ||
                    statusCode == 408 || statusCode == 425 || statusCode == 429 ||
                    (statusCode != null && statusCode >= 500)
                result.error(
                    "referral_code_error",
                    error.message,
                    mapOf(
                        "code" to rawCode,
                        "statusCode" to statusCode,
                        "isRetryable" to isRetryable
                    )
                )
            }
        }
    }

    private fun syncAllTransactions(result: MethodChannel.Result) {
        val googleCore = core

        if (googleCore == null) {
            result.error(
                "not_initialized",
                "GoMarketMe SDK must be initialized before syncing transactions",
                null
            )
            return
        }

        scope.launch {
            try {
                val syncResult = googleCore.sendCurrentPurchasesWithResult()

                result.success(
                    mapOf(
                        "fetchedCount" to syncResult.fetchedCount,
                        "sentCount" to syncResult.sentCount,
                        "failedCount" to syncResult.failedCount,
                        "success" to syncResult.success
                    )
                )
            } catch (throwable: Throwable) {
                result.error("sync_all_transactions_failed", throwable.message, null)
            }
        }
    }

    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        val apiKey = call.argument<String>("apiKey")?.trim()
        if (apiKey.isNullOrEmpty()) {
            result.error("invalid_arguments", "apiKey is required", null)
            return
        }

        val initialConfig = GoMarketMeGoogleCoreConfiguration(
            apiKey = apiKey,
            sdkType = call.argument<String>("sdkType") ?: "Flutter",
            sdkVersion = call.argument("sdkVersion"),
            isProduction = call.argument("isProduction")
        )

        val googleCore = core ?: GoMarketMeGoogleCore(context)

        if (isDebugLoggingEnabled) {
            googleCore.onPurchase = { event -> Log.d(TAG, "purchase observed by core: ${event.toMap()}") }
            googleCore.onError = { throwable -> Log.e(TAG, "core error", throwable) }
        }

        scope.launch {
            try {
                val prepared = googleCore.prepareAttribution(initialConfig)
                val config = prepared.first
                val affiliateMarketingData = prepared.second

                googleCore.configure(config)
                googleCore.start()
                core = googleCore

                result.success(
                    mapOf(
                        "initialized" to true,
                        "platform" to "android",
                        "source" to config.sourceName,
                        "affiliateMarketingData" to affiliateMarketingData
                    )
                )
            } catch (throwable: Throwable) {
                result.error("initialize_failed", throwable.message, null)
            }
        }
    }

    private companion object {
        const val isDebugLoggingEnabled = false
        const val CHANNEL_NAME = "co.gomarketme/core"
        const val TAG = "GoMarketMeFlutter"
    }
}
