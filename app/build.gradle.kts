plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "vn.edu.vhu.ltdd.detai1"
    compileSdk {
        version = release(37)
    }

    defaultConfig {
        applicationId = "vn.edu.vhu.ltdd.detai1"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            optimization {
                enable = false
            }
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")

    implementation("androidx.recyclerview:recyclerview:1.4.0")

    implementation("com.squareup.retrofit2:retrofit:2.11.0")

    implementation("com.squareup.retrofit2:converter-gson:2.11.0")

    implementation("com.github.PhilJay:MPAndroidChart:v3.1.0")
    implementation("com.google.android.material:material:1.11.0")
}