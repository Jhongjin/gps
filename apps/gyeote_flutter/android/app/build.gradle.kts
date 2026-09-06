plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.gyeote.gyeote"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.gyeote.gyeote"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

android.testOptions {
    unitTests.isReturnDefaultValues = true
    // 위젯이 실제로 무엇을 그리는지 보려면 리소스가 필요하다. Robolectric 이
    // 에뮬레이터 없이 JVM 에서 프레임워크를 돌린다.
    unitTests.isIncludeAndroidResources = true
}

// Robolectric 이 리소스를 읽으려면 유닛테스트 패키징이 Flutter 에셋 병합 뒤에
// 와야 한다. Flutter Gradle 플러그인이 그 의존을 선언하지 않아서 Gradle 9 의
// 검증이 빌드를 막는다. 여기서 명시한다.
listOf("Debug", "Release").forEach { variant ->
    tasks.matching { it.name == "package${variant}UnitTestForUnitTest" }
        .configureEach { dependsOn("copyFlutterAssets$variant") }
}

dependencies {
    implementation("com.google.android.gms:play-services-location:21.3.0")
    testImplementation("junit:junit:4.13.2")
    // org.json 은 안드로이드 런타임에만 있다. JVM 단위 테스트에서는 스텁이
    // 예외를 던지므로 실제 구현을 넣어 준다.
    testImplementation("org.json:json:20240303")
    // 이 워크스테이션의 유일한 JDK 가 Android Studio 의 JBR 25 다. Robolectric 은
    // 클래스를 ASM 으로 계측하는데, 4.14.1 이 쓰는 ASM 9.7 은 클래스 파일
    // major 69(=Java 25)를 읽지 못하고 전부 IllegalArgumentException 으로 죽는다.
    // JDK 를 내리는 대신 계측기를 올린다.
    testImplementation("org.robolectric:robolectric:4.16.1")
    testImplementation("androidx.test:core:1.6.1")
    // Robolectric 4.16.1 은 ASM 9.8 을 끌고 오는데, 그건 Java 25 를 막 지원하기
    // 시작한 버전이다. 여유를 두고 명시적으로 올린다.
    testImplementation("org.ow2.asm:asm:9.10.1")
    testImplementation("org.ow2.asm:asm-commons:9.10.1")
}
