# Spine Flutter 相关的混淆规则
-keep class com.esotericsoftware.spine.** { *; }
-keep class spine_flutter.** { *; }
-dontwarn com.esotericsoftware.spine.**

# 保持Spine相关的native方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保持所有的枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Flutter相关
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 音频播放器
-keep class xyz.luan.audioplayers.** { *; }

# Google Play Core 相关 - 解决Missing classes问题
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.** { *; }

# Flutter Play Store Split Application
-keep class io.flutter.app.FlutterPlayStoreSplitApplication { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# 其他常见的missing classes
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.Unsafe