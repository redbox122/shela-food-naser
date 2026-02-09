package com.food.shala

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val EDGE_TO_EDGE_CHANNEL = "edge_to_edge"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge for Android 15+ compatibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register secure token provider
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SecureTokenProvider.CHANNEL_NAME)
        channel.setMethodCallHandler(SecureTokenProvider(this))
        
        // Register edge-to-edge channel
        val edgeToEdgeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EDGE_TO_EDGE_CHANNEL)
        edgeToEdgeChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableEdgeToEdge" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
                            WindowCompat.setDecorFitsSystemWindows(window, false)
                            result.success(true)
                        } else {
                            // Keep the legacy behavior for pre-Android 15 devices
                            WindowCompat.setDecorFitsSystemWindows(window, true)
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("EDGE_TO_EDGE_ERROR", "Failed to enable edge-to-edge", e.message)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
