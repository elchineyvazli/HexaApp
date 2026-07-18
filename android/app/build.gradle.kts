import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")

    // Flutter Gradle plugin'i Android ve Kotlin pluginlerinden sonra gelmeli.
    id("dev.flutter.flutter-gradle-plugin")

    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")

val keystoreProperties =
    Properties().apply {
        if (keystorePropertiesFile.exists()) {
            keystorePropertiesFile.inputStream().use { stream ->
                load(stream)
            }
        }
    }

val hasReleaseSigning =
    listOf(
        "storeFile",
        "storePassword",
        "keyAlias",
        "keyPassword",
    ).all { key ->
        !keystoreProperties.getProperty(key).isNullOrBlank()
    }

android {
    namespace = "com.example.hexa_prod"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.hexa_prod"

        // pubspec.yaml ve modern medya paketleriyle aynı taban.
        minSdk = 24

        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias =
                    keystoreProperties.getProperty("keyAlias")

                keyPassword =
                    keystoreProperties.getProperty("keyPassword")

                storeFile =
                    file(
                        keystoreProperties.getProperty("storeFile"),
                    )

                storePassword =
                    keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        debug {
            // Firebase yapılandırmasının applicationId ile eşleşmesi için
            // şimdilik applicationIdSuffix kullanılmıyor.
        }

        release {
            // Play Store öncesinde key.properties mevcut olmalıdır.
            //
            // Şimdilik release derlemelerini engellememek için dosya yoksa
            // debug anahtarına geri döner. Bu paket mağazaya yüklenmemelidir.
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }

            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    val media3Version = "1.10.1"

    // Bütün Media3 modülleri aynı sürümde tutulmalıdır.
    implementation(
        "androidx.media3:media3-transformer:$media3Version",
    )
    implementation(
        "androidx.media3:media3-effect:$media3Version",
    )
    implementation(
        "androidx.media3:media3-common:$media3Version",
    )
}

flutter {
    source = "../.."
}