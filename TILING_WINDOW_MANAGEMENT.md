# SwayWM-Like Tiling Window Management

This document explains the implementation of a SwayWM-inspired tiling window management system for the Flutter GetX Kiosk application.

## Key Features

1. **Automatic Tiling Layout**: Windows automatically organize into a binary tree layout, similar to i3/Sway window managers
2. **Split Direction Control**: Support for both horizontal and vertical splits
3. **Persistent Window State**: WebView, media and audio content maintain their state during resizes and movements
4. **Dual Mode Support**: Toggle between tiling and floating window modes
5. **State Preservation**: Content doesn't reload when windows are moved or resized

## Implementation Details

### 1. Data Model: Binary Tree Layout

The tiling layout is implemented as a binary tree structure:

- **TilingNode**: A node in the layout tree that can be either:
  - A leaf node containing a window
  - A split node with two child nodes
- **SplitDirection**: Horizontal (left/right) or vertical (top/bottom)
- **TilePosition**: Position of a tile within its parent (first or second)

```dart
class TilingNode {
  // Split node properties
  SplitDirection? splitDirection;
  TilingNode? firstChild;
  TilingNode? secondChild;
  
  // Leaf node property
  WindowTile? content;
  
  // Bounds within the container
  Rect bounds;
}
```

### 2. Layout Algorithm

The layout algorithm recursively divides the available space:

1. Start with the full container area
2. For each split node, divide the space according to the split direction and ratio
3. For leaf nodes, assign the available space to the contained window
4. Update window positions and sizes to match their assigned space

### 3. Content Persistence Mechanisms

#### WebView Persistence

- **WebViewManager**: Singleton manager that maintains WebView instances by URL
- **WebViewData**: Holds controller and state information for each webview
- **AutomaticKeepAliveClientMixin**: Prevents WebView rebuilding when not visible

#### Media Persistence

- **MediaPlayerManager**: Singleton manager that maintains Player instances by URL
- **PlayerWithController**: Holds player, controller, and state information
- **Position tracking**: Saves and restores playback position during lifecycle changes

### 4. User Interface

The UI provides controls for:

- Adding web, video, and audio content
- Splitting windows horizontally or vertically
- Toggling between tiling and floating modes
- Managing window focus

## Usage Guide

### Adding Windows

1. Click the appropriate button (Web, Video, Audio) in the toolbar
2. Enter a name and URL
3. The window will be added to the layout according to the current mode:
   - In tiling mode: Split the selected window
   - In floating mode: Add as a floating window

### Window Operations

#### Tiling Mode

- **Split Horizontally**: Creates a left/right split with the new window
- **Split Vertically**: Creates a top/bottom split with the new window
- **Close Window**: Removes the window and redistributes space

#### Floating Mode

- **Drag**: Move windows by dragging their title bar
- **Resize**: Adjust window size using the resize handle

### Mode Switching

Toggle between tiling and floating mode using the mode button in the toolbar.

## Technical Benefits

1. **Memory Efficiency**: Reuse of WebView and media player instances
2. **Performance**: Reduced rebuilds and reloads
3. **User Experience**: Content persists across layout changes
4. **Kiosk Suitability**: Better space utilization for information display

## Future Enhancements

- Nesting ratio adjustment
- Window stacking priorities
- Layout presets and saved configurations
- Fullscreen mode for focused windows