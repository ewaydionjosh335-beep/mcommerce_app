# Android and Project Configuration Fix Plan

This plan addresses critical build and configuration errors identified in `pubspec.yaml`, `android/settings.gradle.kts`, and `android/gradle/wrapper/gradle-wrapper.properties` where invalid or non-existent future versions (e.g., Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20, Dart SDK 3.12.2, Firebase core 4.x/6.x) were specified.

---

## Identified Issues & Corrections

1. **Pubspec SDK & Dependencies (`pubspec.yaml`)**
   - *Issue:* `sdk: ^3.12.2` and high Firebase versions (`firebase_core: ^4.15.0`, `firebase_auth: ^6.7.0`, `cloud_firestore: ^6.10.0`) do not exist and cause pub get failures.
   - *Fix:* Update Dart SDK constraint to `^3.5.0` and use stable current Firebase package versions (`firebase_core: ^3.6.0`, `firebase_auth: ^5.3.1`, `cloud_firestore: ^5.4.4`, `provider: ^6.1.2`, `google_fonts: ^6.2.1`).

2. **Gradle Wrapper (`android/gradle/wrapper/gradle-wrapper.properties`)**
   - *Issue:* `gradle-9.1.0-all.zip` is non-existent.
   - *Fix:* Downgrade to a stable Gradle version compatible with current Android Gradle Plugin, e.g., `gradle-8.8-all.zip`.

3. **Android Plugins & Versions (`android/settings.gradle.kts`)**
   - *Issue:* AGP `9.0.1` and Kotlin `2.3.20` are invalid/non-existent versions.
   - *Fix:* Update plugins to compatible stable versions:
     - `com.android.application`: `8.5.0`
     - `org.jetbrains.kotlin.android`: `1.9.24` (or `2.0.20`)
     - `com.google.gms.google-services`: `4.4.2`

---

## Action Steps

1. **Modify `pubspec.yaml`**:
   - Adjust `environment.sdk` to `^3.5.0`.
   - Adjust dependency versions for `firebase_core`, `firebase_auth`, `cloud_firestore`, `provider`, and `google_fonts`.

2. **Modify `android/gradle/wrapper/gradle-wrapper.properties`**:
   - Set `distributionUrl` to Gradle 8.8 (`gradle-8.8-all.zip`).

3. **Modify `android/settings.gradle.kts`**:
   - Set Android application plugin to `8.5.0`.
   - Set Kotlin plugin to `1.9.24`.
   - Set Google Services plugin to `4.4.2`.

4. **Validation**:
   - Run `flutter pub get`.
   - Run `flutter clean` and build / gradle check.
