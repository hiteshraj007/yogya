# ─── Yogya ProGuard Rules ───────────────────────────────────
# Keep rules for R8/ProGuard code shrinking in release builds.

# ─── Flutter ───
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ─── Firebase ───
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ─── Google Sign-In ───
-keep class com.google.android.gms.auth.** { *; }

# ─── Gson (used by Firebase) ───
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# ─── Sentry (when added) ───
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# ─── General Android ───
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep R class fields
-keepclassmembers class **.R$* {
    public static <fields>;
}
