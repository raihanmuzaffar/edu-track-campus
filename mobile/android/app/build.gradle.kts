plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseApplicationId =
    providers.environmentVariable("EDUTRACK_ANDROID_APPLICATION_ID").orNull?.trim().orEmpty()
val releaseSigningVariables = listOf(
    "EDUTRACK_ANDROID_KEYSTORE_PATH",
    "EDUTRACK_ANDROID_KEYSTORE_PASSWORD",
    "EDUTRACK_ANDROID_KEY_ALIAS",
    "EDUTRACK_ANDROID_KEY_PASSWORD",
)
val releaseSigningValues = releaseSigningVariables.associateWith { name ->
    providers.environmentVariable(name).orNull?.takeIf { it.isNotBlank() }
}
val missingReleaseSigningVariables =
    releaseSigningValues.filterValues { it == null }.keys
val hasReleaseSigningConfiguration = missingReleaseSigningVariables.isEmpty()
val releaseBuildRequested =
    gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }

if (releaseSigningValues.values.any { it != null } && !hasReleaseSigningConfiguration) {
    throw GradleException(
        "Incomplete Android release signing configuration; missing environment variables: " +
            missingReleaseSigningVariables.joinToString(),
    )
}

if (releaseBuildRequested) {
    val requiredVariables = mutableListOf<String>()
    if (releaseApplicationId.isEmpty() ||
        !Regex("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+")
            .matches(releaseApplicationId) ||
        releaseApplicationId == "com.example.mobile"
    ) {
        requiredVariables += "EDUTRACK_ANDROID_APPLICATION_ID"
    }
    if (!hasReleaseSigningConfiguration) {
        requiredVariables += missingReleaseSigningVariables
    }
    if (requiredVariables.isNotEmpty()) {
        throw GradleException(
            "Android release build blocked; provide valid production configuration: " +
                requiredVariables.distinct().joinToString(),
        )
    }
}

val releaseKeystorePath = releaseSigningValues["EDUTRACK_ANDROID_KEYSTORE_PATH"]
if (releaseKeystorePath != null && !file(releaseKeystorePath).isFile) {
    throw GradleException("Configured Android release keystore file was not found.")
}

android {
    namespace = "com.example.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = releaseApplicationId.ifEmpty { "com.example.mobile" }
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

    signingConfigs {
        if (hasReleaseSigningConfiguration) {
            create("release") {
                storeFile = file(releaseKeystorePath!!)
                storePassword = releaseSigningValues["EDUTRACK_ANDROID_KEYSTORE_PASSWORD"]
                keyAlias = releaseSigningValues["EDUTRACK_ANDROID_KEY_ALIAS"]
                keyPassword = releaseSigningValues["EDUTRACK_ANDROID_KEY_PASSWORD"]
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigningConfiguration) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = null
            }
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
