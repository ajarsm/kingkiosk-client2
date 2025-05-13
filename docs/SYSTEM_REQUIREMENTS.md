# System Requirements for Flutter GetX Kiosk

This document outlines the minimum system requirements for running the Flutter GetX Kiosk application on Android tablets.

## Minimum Hardware Requirements

For basic functionality (web views, MQTT monitoring):

- **Android Version**: Android 5.0 (Lollipop) or higher
- **Processor**: Quad-core 1.3 GHz or better
- **RAM**: 1.5 GB or more
- **Storage**: 16 GB (with at least 500 MB free space for the app)
- **Screen**: 7" or larger with 1024x600 resolution or better
- **Network**: Wi-Fi capability (for MQTT connectivity)

## Recommended Hardware Requirements

For smooth performance with multiple web views, video playback, and responsive UI:

- **Android Version**: Android 8.0 (Oreo) or higher
- **Processor**: Octa-core 1.5 GHz or better
- **RAM**: 2 GB or more
- **Storage**: 32 GB (with at least 1 GB free space)
- **Screen**: 8" or larger with 1280x800 resolution or better
- **Network**: Wi-Fi 5 (802.11ac) or better

## Testing on Low-End Devices

If you're planning to deploy on very inexpensive ($50) Android tablets, consider:

1. **Test on actual target hardware** - Performance can vary significantly between devices even with similar specifications
2. **Limit concurrent web views** - Try to show only one web view at a time on lower-end devices
3. **Disable animations** - Consider adding a "low performance mode" that disables animations
4. **Reduce polling frequency** - If using MQTT for frequent updates, consider reducing update intervals
5. **Monitor memory usage** - Use Android Studio's Profiler to track memory consumption during extended use

## Known Compatible Budget Tablets

These budget tablets have been tested and confirmed to work with Flutter GetX Kiosk:

- [Add your test results here once you've verified on specific models]

## How to Test Minimum Requirements

To verify if your app will run on a specific device:

1. Check the device specifications against the minimum requirements
2. Install the APK and test core functionality:
   - Home screen loads properly
   - Web views render correctly
   - MQTT connection works
   - UI responds within an acceptable timeframe
3. Run the app for at least 1 hour to ensure no memory leaks or performance degradation

## Optimizing for Low-End Devices

The Flutter GetX Kiosk application has been designed with performance in mind:

- Web content is the biggest performance factor - simpler websites will perform better
- MQTT connections are lightweight but persistent - ensure stable network connectivity
- Consider using the "kiosk mode" feature to reduce system overhead
- Disable system animations in Android developer options on very low-end devices

## Reporting Compatibility

If you've successfully tested this app on a budget tablet, please consider submitting the device model and specifications to help others.