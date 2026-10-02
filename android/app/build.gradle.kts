import com.android.build.api.instrumentation.AsmClassVisitorFactory
import com.android.build.api.instrumentation.ClassContext
import com.android.build.api.instrumentation.ClassData
import com.android.build.api.instrumentation.FramesComputationMode
import com.android.build.api.instrumentation.InstrumentationParameters
import com.android.build.api.instrumentation.InstrumentationScope
import java.util.Properties
import org.objectweb.asm.ClassVisitor
import org.objectweb.asm.MethodVisitor
import org.objectweb.asm.Opcodes

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing, from android/key.properties (never committed):
//   storeFile=/path/to/upload.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
// Without it, release builds are signed with the debug key so they still
// run locally; they cannot be published.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keyProperties.getProperty("storeFile") != null

android {
    namespace = "xyz.olaifaglory.stitch"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "xyz.olaifaglory.stitch"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    sourceSets {
        // The engine tests read the same media corpus as the iOS tests.
        getByName("androidTest") {
            assets.srcDir("../../test_media")
        }
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("No android/key.properties: release build signed with the debug key.")
                signingConfigs.getByName("debug")
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

// Media3 compositing APIs are @UnstableApi: pin exactly and re-verify
// behavior before upgrading.
val media3 = "1.11.1"

dependencies {
    implementation("androidx.media3:media3-transformer:$media3")
    implementation("androidx.media3:media3-effect:$media3")
    implementation("androidx.media3:media3-common:$media3")
    implementation("androidx.media3:media3-exoplayer:$media3")
    implementation("androidx.exifinterface:exifinterface:1.4.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
}

// The integration_test plugin asks for androidx.test 1.2+, which resolves to
// releases that predate Android 12 manifest rules. Use current ones throughout.
configurations.all {
    resolutionStrategy.force(
        "androidx.test:runner:1.7.0",
        "androidx.test:rules:1.7.0",
        "androidx.test:core:1.7.0",
        "androidx.test:monitor:1.8.0",
        "androidx.test.espresso:espresso-core:3.7.0",
    )
}

// Media3 1.11.1's preview player (CompositionPlayer) stops for good when
// playback flows into a sequence item whose first audio frame starts before
// the item: AudioGraphInputAudioSink hands AudioGraphInput a negative
// positionOffsetUs, which fails checkArgument(positionOffsetUs >= 0).
// Phone recordings trigger it at almost every clip boundary: their AAC
// audio starts slightly before 0 (encoder delay in the edit list), and cuts
// mid-file land inside an audio frame. Exports are not affected (each item
// gets a fresh loader that drops those samples).
//
// This clamps that offset to 0 in AudioGraphInputAudioSink.handleBuffer, so
// such an item's sound starts at the item's start, late by at most one
// audio frame (about 23 ms). Remove it once Media3 handles this itself;
// EngineTests.previewPlaysAcrossClipBoundaries checks the behaviour, and
// -Pstitch.noAudioClamp=true builds without the patch to compare.
abstract class ClampAudioOffset : AsmClassVisitorFactory<InstrumentationParameters.None> {
    override fun isInstrumentable(classData: ClassData): Boolean =
        classData.className == "androidx.media3.transformer.AudioGraphInputAudioSink"

    override fun createClassVisitor(
        classContext: ClassContext,
        nextClassVisitor: ClassVisitor,
    ): ClassVisitor = object : ClassVisitor(Opcodes.ASM9, nextClassVisitor) {
        override fun visitMethod(
            access: Int,
            name: String?,
            descriptor: String?,
            signature: String?,
            exceptions: Array<out String>?,
        ): MethodVisitor {
            val method = super.visitMethod(access, name, descriptor, signature, exceptions)
            if (name != "handleBuffer") return method
            return object : MethodVisitor(Opcodes.ASM9, method) {
                override fun visitMethodInsn(
                    opcode: Int,
                    owner: String?,
                    name: String?,
                    descriptor: String?,
                    isInterface: Boolean,
                ) {
                    // Both calls take positionOffsetUs as their last (long)
                    // argument, on top of the stack: replace it with
                    // max(it, 0).
                    val clamps = owner == "androidx/media3/transformer/AudioGraphInput" &&
                        (name == "onMediaItemChanged" || name == "flush") &&
                        descriptor?.endsWith("J)V") == true
                    if (clamps) {
                        super.visitInsn(Opcodes.LCONST_0)
                        super.visitMethodInsn(
                            Opcodes.INVOKESTATIC, "java/lang/Math", "max", "(JJ)J", false,
                        )
                    }
                    super.visitMethodInsn(opcode, owner, name, descriptor, isInterface)
                }
            }
        }
    }
}

androidComponents {
    onVariants { variant ->
        if (project.findProperty("stitch.noAudioClamp") == "true") return@onVariants
        variant.instrumentation.transformClassesWith(
            ClampAudioOffset::class.java,
            InstrumentationScope.ALL,
        ) {}
        variant.instrumentation.setAsmFramesComputationMode(
            FramesComputationMode.COMPUTE_FRAMES_FOR_INSTRUMENTED_METHODS,
        )
    }
}
