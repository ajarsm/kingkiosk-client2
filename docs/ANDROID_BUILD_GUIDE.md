# Building for Android

## Common Issues and Solutions

### Namespace Not Specified Error

If you encounter the following error when building for Android:

```
A problem occurred configuring project ':image_gallery_saver'.
> Could not create an instance of type com.android.build.api.variant.impl.LibraryVariantBuilderImpl.
   > Namespace not specified. Specify a namespace in the module's build file
```

This is due to the `image_gallery_saver` plugin not being updated to work with newer versions of the Android Gradle Plugin.

### JVM Target Error

If you encounter an error related to Kotlin JVM target:

```
Error while evaluating property 'compilerOptions.jvmTarget' of task ':image_gallery_saver:compileDebugKotlin'.
> Failed to calculate the value of property 'jvmTarget'.
   > Unknown Kotlin JVM target: 21
```

This is because your JDK version (likely JDK 21) is newer than what the plugin supports.

### General Solution:

1. Run the patch script included in the project:

```bash
./apply_plugin_patches.sh
```

2. This script fixes multiple issues:
   - Adds the required namespace to the plugin's build.gradle file
   - Sets an appropriate JVM target for Kotlin compilation
   - Updates the Kotlin version to be compatible

3. You can then build for Android normally:

```bash
flutter run
```

### Quick Fix:

Use our convenience script that handles all these steps:

```bash
./run_android.sh
```

### Advanced Troubleshooting:

If you're still experiencing issues, we've included a troubleshooting script:

```bash
./troubleshoot_plugins.sh
```

This script will:
- Analyze your plugins for common issues
- Apply fixes where possible
- Provide detailed diagnostic information

## Screenshot Functionality on Android

The screenshot functionality on Android requires:

1. Storage permissions for Android 10 (API 29) and below
2. Media access permissions for Android 11 (API 30) and above

These are handled automatically by the app. Screenshots are saved to:
- The device's media/photos gallery
- The app's internal storage directory

## Manual Building Steps

If you prefer to handle the build process manually:

1. Apply the plugin patches:
   ```bash
   ./apply_plugin_patches.sh
   ```

2. Clean the project:
   ```bash
   flutter clean
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```
