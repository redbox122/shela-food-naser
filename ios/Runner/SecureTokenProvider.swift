import Flutter
import UIKit

/// SecureTokenProvider - iOS implementation for loading MyFatoorah tokens
/// This class provides a method channel to securely deliver payment gateway tokens
/// to the Flutter application without hardcoding them in Dart code.
class SecureTokenProvider: NSObject, FlutterPlugin {
    
    static let channelName = "secure_tokens"
    
    /// Register the plugin with the Flutter engine
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = SecureTokenProvider()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    /// Handle method calls from Flutter
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getLiveToken":
            result(getLiveToken())
        case "getTestToken":
            result(getTestToken())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Get MyFatoorah Live Token from Info.plist
    private func getLiveToken() -> String {
        guard let token = Bundle.main.object(
            forInfoDictionaryKey: "MYFATOORAH_LIVE_TOKEN"
        ) as? String, !token.isEmpty else {
            print("❌ [SecureTokenProvider] Live token not found in Info.plist")
            return ""
        }
        print("✅ [SecureTokenProvider] Live token loaded successfully")
        return token
    }
    
    /// Get MyFatoorah Test Token from Info.plist
    private func getTestToken() -> String {
        guard let token = Bundle.main.object(
            forInfoDictionaryKey: "MYFATOORAH_TEST_TOKEN"
        ) as? String, !token.isEmpty else {
            print("❌ [SecureTokenProvider] Test token not found in Info.plist")
            return ""
        }
        print("✅ [SecureTokenProvider] Test token loaded successfully")
        return token
    }
}

