pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // 'com.android.application' refers to version of Android Gradle Plugin (AGP 9+):
    // From https://www.perplexity.ai/search/ed04fc4a-b788-4fc6-b8fc-07bdcd3c9e41#12
    //    Yes, com.android.application refers to the Android Gradle Plugin (AGP). Specifically:
    //      - com.android.application is the plugin ID for building an Android application (APK).
    //      - com.android.library is the plugin ID for building an Android library (AAR).
    // The latest in 2026-06-12 is NOT 9.5.1 (version of Gradle, see gradle.wrapper.properties) but 9.0.1
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.10" apply false
}

include(":app")
