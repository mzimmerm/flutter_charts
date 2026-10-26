plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "com.example.flutter_charts"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.flutter_charts"
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"
    }
    compileOptions {
        targetCompatibility = JavaVersion.VERSION_17
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
