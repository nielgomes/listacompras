# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /opt/android-sdk-linux/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguard
# include property in your /project.properties file.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keepattributes Signature
-keepattributes *Annotation*

# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.FlutterActivity { *; }
-keep class io.flutter.embedding.** { *; }

# Prevent R8 from removing Firebase services
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Keep Firebase JSON parsing
-keepattributes InnerClasses, EnclosingMethod
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.auth.** { *; }

# Google Play Core / Dynamic Delivery (não usado, mas Flutter inclui referências)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.splitinstall.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
