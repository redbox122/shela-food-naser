# ========================================
# MyFatoorah SDK ProGuard Rules
# ========================================

# Keep all MyFatoorah classes and members
-keep class com.myfatoorah.** { *; }
-keep interface com.myfatoorah.** { *; }
-keep enum com.myfatoorah.** { *; }

-keep class com.myfatoorahflutter.** { *; }
-keep interface com.myfatoorahflutter.** { *; }
-keep enum com.myfatoorahflutter.** { *; }

# Keep MyFatoorah SDK from being obfuscated
-dontwarn com.myfatoorah.**
-dontwarn com.myfatoorahflutter.**

# Keep all methods and fields
-keepclassmembers class com.myfatoorah.** { *; }
-keepclassmembers class com.myfatoorahflutter.** { *; }

# Keep MyFatoorah SDK extended/implemented classes
-keep class * extends com.myfatoorah.** { *; }
-keep class * implements com.myfatoorah.** { *; }
-keep class * extends com.myfatoorahflutter.** { *; }
-keep class * implements com.myfatoorahflutter.** { *; }

# Keep MyFatoorah SDK reflection usage
-keepclassmembers class * {
    @com.myfatoorah.** *;
    @com.myfatoorahflutter.** *;
}

# Keep MyFatoorah SDK callback methods
-keepclassmembers class * {
    public void onPaymentResult(...);
    public void onPaymentSuccess(...);
    public void onPaymentFailure(...);
    public void onInitiatePaymentResult(...);
    public void onExecutePaymentResult(...);
    public void onSendPaymentResult(...);
    public void onGetPaymentStatusResult(...);
    public void onDirectPaymentResult(...);
    public void onSessionInitiated(...);
    public void onCardViewLoaded(...);
    public void onApplePayResult(...);
}

# ========================================
# Firebase Core & Cloud Messaging (CRITICAL for notifications)
# ========================================

# Keep all Firebase classes
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }
-keep enum com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Firebase Messaging (FCM) - CRITICAL for push notifications
-keep class com.google.firebase.messaging.** { *; }
-keep interface com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-dontwarn com.google.firebase.messaging.**
-dontwarn com.google.firebase.iid.**

# Keep FCM Service and Receiver classes
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class * extends com.google.firebase.iid.FirebaseInstanceIdService { *; }

# Keep Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }
-dontwarn com.google.firebase.analytics.**

# Keep Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-keep interface com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**
-keepattributes SourceFile,LineNumberTable

# Keep Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-dontwarn com.google.firebase.auth.**

# Keep Google Play Services (required by Firebase)
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep GMS Tasks (required by Firebase async operations)
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.tasks.**

# Keep Firebase Installation ID
-keep class com.google.firebase.installations.** { *; }
-dontwarn com.google.firebase.installations.**

# ========================================
# Flutter Firebase Plugins (CRITICAL for notifications)
# ========================================

# Keep Flutter Firebase Core plugin
-keep class io.flutter.plugins.firebase.** { *; }
-keep class io.flutter.plugins.firebasecore.** { *; }
-dontwarn io.flutter.plugins.firebase.**

# Keep Flutter Firebase Messaging plugin (CRITICAL)
-keep class io.flutter.plugins.firebasemessaging.** { *; }
-keep interface io.flutter.plugins.firebasemessaging.** { *; }
-dontwarn io.flutter.plugins.firebasemessaging.**

# Keep Flutter Local Notifications plugin (CRITICAL)
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep interface com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep notification-related Android classes
-keep class android.app.NotificationManager { *; }
-keep class android.app.NotificationChannel { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# Keep Firebase Crashlytics plugin
-keep class io.flutter.plugins.firebasecrashlytics.** { *; }
-dontwarn io.flutter.plugins.firebasecrashlytics.**

# Keep Firebase Auth plugin
-keep class io.flutter.plugins.firebaseauth.** { *; }
-dontwarn io.flutter.plugins.firebaseauth.**

# ========================================
# Third-party Dependencies
# ========================================

# Keep Gson/JSON serialization
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Keep all model classes used by MyFatoorah
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep Retrofit/OkHttp classes (MyFatoorah uses these for networking)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-keep interface okio.** { *; }

# Keep Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# Handle missing Google Play Core classes (Flutter deferred components)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ========================================
# Flutter-specific ProGuard Rules
# ========================================

# Keep Flutter engine classes
-keep class io.flutter.** { *; }

# Keep Flutter platform channels
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }

# Keep Flutter method channels
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodCall *;
}

# Keep Flutter event channels
-keepclassmembers class * {
    @io.flutter.plugin.common.EventChannel$EventSink *;
}

# Keep Flutter basic message channels
-keepclassmembers class * {
    @io.flutter.plugin.common.BasicMessageChannel$MessageHandler *;
}

# Keep Flutter method call handlers
-keepclassmembers class * {
    public void onMethodCall(io.flutter.plugin.common.MethodCall, io.flutter.plugin.common.MethodChannel$Result);
}

# Keep Flutter app classes (modern Flutter)
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }
-keep class * extends io.flutter.embedding.android.FlutterFragmentActivity { *; }

# ========================================
# Global ProGuard Rules
# ========================================

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve all annotations and reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations