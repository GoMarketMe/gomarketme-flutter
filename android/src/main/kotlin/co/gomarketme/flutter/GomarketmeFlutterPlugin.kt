package co.gomarketme.flutter

import android.content.Context
import android.util.Log
import co.gomarketme.core.GoMarketMeGoogleCore
import co.gomarketme.core.GoMarketMeGoogleCoreConfiguration
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class GomarketmeFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
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
            "initialize" -> initialize(call, result)
            else -> result.notImplemented()
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
