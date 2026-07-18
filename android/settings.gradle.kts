pluginManagement {
    val flutterSdkPath =
        run {
            val localPropertiesFile = file("local.properties")

            require(localPropertiesFile.exists()) {
                "android/local.properties bulunamadı. " +
                    "'flutter.sdk' yolunu içeren dosyayı oluştur."
            }

            val properties = java.util.Properties()

            localPropertiesFile.inputStream().use { stream ->
                properties.load(stream)
            }

            requireNotNull(properties.getProperty("flutter.sdk")) {
                "flutter.sdk android/local.properties içinde tanımlı değil."
            }
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

    // Flutter 3.38 için AGP 8 hattında kalıyoruz.
    id("com.android.application") version "8.11.1" apply false

    // KGP 2.2.20, AGP 8.11.1 ile resmî olarak uyumludur.
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false

    id("com.google.gms.google-services") version "4.5.0" apply false
}

include(":app")