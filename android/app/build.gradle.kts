plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.shalimarstore.app.shalimar_store"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion is not needed for pure Dart/Flutter apps without native C++

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            storeFile = file("shalimar-release-key.jks")
            storePassword = "shalimar1988"
            keyAlias = "shalimar"
            keyPassword = "shalimar1988"
        }
    }

    defaultConfig {
        applicationId = "com.shalimarstore.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
