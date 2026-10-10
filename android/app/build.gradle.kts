plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ru.shray77.vetos"
    compileSdk = flutter.compileSdkVersion
    // NDK для чистого Flutter не нужен: версия совпадает со стаб-метаданными
    // SDK (ndk/28.2.13676358/source.properties) — flutter-плагин видит её
    // «установленной» и не втыкает синтетический cmake/не качает NDK ~2.5 ГБ.
    // На машине с полноценным SDK flutter сам доустановит нужный NDK.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ru.shray77.vetos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // R8-минификация выключена: для sideload-APK выигрыш мал,
            // а на слабых сборочных машинах R8 выедает память (3.9 ГБ RAM).
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Сборка без полного NDK: по пути ndk/<ver>/.../bin лежат шимы
    // llvm-strip/llvm-objcopy/llvm-readelf → multiarch GNU binutils
    // (apt-get download binutils-multiarch; см. README «Как собрать»).
    // Без стриппинга APK раздувается до ~500 МБ, со стриппингом — ~56 МБ.
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
