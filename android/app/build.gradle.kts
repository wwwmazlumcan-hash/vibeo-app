import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Keystore properties — CI'da environment variable'dan, yerel geliştirmede key.properties'ten okunur
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.vibeo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            // CI: environment variables; Yerel: key.properties
            val ksFile = System.getenv("KEYSTORE_PATH")
                ?: keystoreProperties["storeFile"] as String?
            if (ksFile != null) {
                storeFile = file(ksFile)
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                    ?: keystoreProperties["storePassword"] as String? ?: ""
                keyAlias = System.getenv("KEY_ALIAS")
                    ?: keystoreProperties["keyAlias"] as String? ?: ""
                keyPassword = System.getenv("KEY_PASSWORD")
                    ?: keystoreProperties["keyPassword"] as String? ?: ""
            }
        }
    }

    defaultConfig {
        applicationId = "com.vibeo.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Keystore varsa release signing, yoksa debug (local test)
            val ksFile = System.getenv("KEYSTORE_PATH")
                ?: keystoreProperties["storeFile"] as String?
            signingConfig = if (ksFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
