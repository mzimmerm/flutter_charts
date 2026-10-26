import com.android.build.api.dsl.ApplicationExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// This section used to be 'android {...}' but android was shown deprecated.
extensions.getByType<ApplicationExtension>().apply {
    namespace = "com.example.flutter_charts"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.flutter_charts"
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"
    }

    compileSdkMinor = 0
    buildToolsVersion = "37.0.0"
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }
}

flutter {
    source = "../.."
}
