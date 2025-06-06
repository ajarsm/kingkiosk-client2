# Camera Resolution Management Testing Guide

## Overview
The camera resolution management system has been implemented to automatically switch between 300x300 (person detection) and 720p (SIP calls) resolutions.

## Test Scenarios

### 1. Manual Testing via Debug Interface
1. Open the app and navigate to Settings
2. Go to "Person Detection Debug" section
3. Look for the camera resolution controls
4. Test the following buttons:
   - **"Upgrade to 720p"** - Should switch camera to 720p mode
   - **"Downgrade to 300x300"** - Should switch camera to 300x300 mode
5. Observe the status display showing current resolution mode

### 2. Automatic Resolution Switching During SIP Calls
1. Configure SIP settings with a valid SIP server
2. Register with the SIP server
3. Make a SIP call (either to AI assistant or another SIP endpoint)
4. **Expected behavior:**
   - When call starts: Camera should automatically upgrade to 720p
   - When call ends: Camera should automatically downgrade to 300x300

### 3. Integration Points
- **SIP Call Start**: `CallStateEnum.CALL_INITIATION` triggers `upgradeTo720p()`
- **SIP Call End**: `CallStateEnum.ENDED` triggers `downgradeTo300x300()`
- **Manual Hangup**: `hangUp()` method triggers `downgradeTo300x300()`

## Log Messages to Watch For
```
📹 Camera upgraded to 720p for SIP call
📹 Camera downgraded to 300x300 for person detection
⚠️ Failed to upgrade camera to 720p for SIP call
⚠️ Failed to downgrade camera to 300x300 after call
🎥 FrameCapturePlugin: Capturing from WebRTC texture ... (300x300)
🎥 FrameCapturePlugin: Capturing from WebRTC texture ... (1280x720)
```

## Technical Implementation
- **PersonDetectionService**: Added reactive `RxBool isUpgradedTo720p` 
- **SipService**: Integrated camera resolution management in call state handlers
- **CameraPreviewWidget**: Enhanced with `CameraResolutionMode` enum
- **PersonDetectionDebugWidget**: Added manual testing controls

## Resolution Modes
- **300x300**: Optimized for ML person detection processing
- **720p (1280x720)**: High quality for SIP video calls
- **Preview (1280x720)**: HD preview for settings UI

## Status
✅ Core resolution switching implemented
✅ SIP integration completed  
✅ Debug controls available
✅ GetX reactive system fixed
🔧 Ready for testing
