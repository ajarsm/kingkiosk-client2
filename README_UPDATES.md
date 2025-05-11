# Flutter GetX Kiosk Updates

## Issues Addressed

### 1. Audio Playback Persistence
**Problem:** Audio continued to play even after closing audio tiles.
**Fix:** Implemented playback control that automatically pauses media when tiles are closed.

### 2. Tiling Mode Improvements
**Problem:** Tiling mode toggle didn't properly reposition windows.
**Fix:** Added proper layout rebuild when toggling between floating and tiled modes, ensuring windows snap to the tiling grid according to layout rules.

### 3. Dark Mode Persistence
**Problem:** Dark mode setting only worked in the settings screen but not across the app.
**Fix:** Implemented a centralized ThemeService that properly manages theme state across the entire application.

### 4. Auto-hiding Toolbar
**Problem:** Toolbar was always visible, taking up screen space.
**Fix:** Created an auto-hiding toolbar that shows on hover/touch and hides after 3 seconds of inactivity.

## Implementation Details

### SwayWM-like Tiling Window Manager
- Implemented a binary tree layout similar to i3/Sway window managers
- Windows can be arranged in horizontal or vertical splits
- Support for both tiling and floating modes
- Proper redistribution of space when windows are closed

### WebView/Media State Persistence
- Created singleton managers to maintain instances of WebViews and media players
- Content state (scroll position, playback position, etc.) is preserved during window movements and resizes
- Proper cleanup when content is no longer needed

### Theme Management
- Centralized theme management through a ThemeService
- Proper initialization of theme on app startup
- Consistent theme application across the entire app
- Theme persists between app restarts

### Responsive UI Improvements
- Auto-hiding toolbar with smooth animations
- Better window title bars with responsive controls
- Improved media player controls that adapt to available space

## How to Run

Use the provided script to run the application:

```bash
chmod +x update_and_run.sh
./update_and_run.sh
```

## Future Improvements

- Window grouping for better organization
- Saved layout presets
- Grid snapping in floating mode
- Fullscreen mode for focused content