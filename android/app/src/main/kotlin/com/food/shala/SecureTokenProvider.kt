package com.food.shala

import android.content.Context
import com.food.shala.BuildConfig
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SecureTokenProvider(private val context: Context) : MethodCallHandler {
    
    companion object {
        const val CHANNEL_NAME = "secure_tokens"
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getLiveToken" -> {
                val token = BuildConfig.MYFATOORAH_LIVE_TOKEN
                if (token.isNotEmpty()) {
                    result.success(token)
                } else {
                    result.error("TOKEN_NOT_FOUND", "Live token not configured", null)
                }
            }
            "getTestToken" -> {
                val token = BuildConfig.MYFATOORAH_TEST_TOKEN
                if (token.isNotEmpty()) {
                    result.success(token)
                } else {
                    result.error("TOKEN_NOT_FOUND", "Test token not configured", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
