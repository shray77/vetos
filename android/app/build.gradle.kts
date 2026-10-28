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
        applicationId = "ru.shray77.vetos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Запинено осознанно (Task 179): flutter.minSdkVersion плавает со сменой
        // Flutter SDK. Сиблинги (ветвойс/ветэко) уже на 24 — все три приложения
        // заявляют одно и то же: Android 4/5/6 получает вежливый отказ установки,
        // а не краш-обзор «на 1 звезду».
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Подпись из env (задаётся в CI: secrets KEYSTORE_*). Локальные сборки
            // без env прозрачно падают обратно на debug-ключ — flutter run --release работает.
            val ksPath = System.getenv("KEYSTORE_FILE")
            if (ksPath != null && file(ksPath).exists()) {
                storeFile = file(ksPath)
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Release-подпись когда keystore доступен (CI), иначе debug для локальной разработки.
            val ksPath = System.getenv("KEYSTORE_FILE")
            val hasReleaseKey = ksPath != null && file(ksPath).exists()
            signingConfig = if (hasReleaseKey) signingConfigs.getByName("release")
                            else signingConfigs.getByName("debug")
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
