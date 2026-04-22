plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {

    namespace = "com.vocabo.vocabofinalapp"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {

        applicationId = "com.vocabo.vocabofinalapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {

        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {

    implementation(platform("com.google.firebase:firebase-bom:34.10.0"))

    implementation("com.google.firebase:firebase-analytics")

}
