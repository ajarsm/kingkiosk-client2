# Flutter State Management and Build Lifecycle Issues

## Common Error: "setState() or markNeedsLayout() called during build"

### What causes this error?
This error occurs when a Flutter widget attempts to update its state while it's still being built. Flutter's rendering pipeline has a specific order of operations:

1. Build phase: Widgets are constructed and their build methods are called
2. Layout phase: The widget sizes and positions are calculated
3. Paint phase: The widgets are actually drawn to the screen

Changing state during the build phase disrupts this flow and can cause inconsistent UI behavior or infinite rebuilds.

### How we fixed this in our code:

1. **Converted GetView to StatefulWidget**:
   - Changed `TilingWindowView` from a `GetView` to a `StatefulWidget` with a proper `State` class
   - This gives us more control over the widget lifecycle

2. **Using didChangeDependencies**:
   - Implemented `didChangeDependencies()` to handle layout changes
   - This method is called when dependencies (like MediaQuery) change
   - It's a safe place to update state without triggering build errors

3. **Checking for actual changes**:
   - Added `setContainerBoundsIfChanged` to only update when dimensions actually change
   - This prevents unnecessary rebuilds and state updates

4. **Using `Future.microtask`**:
   - For operations that truly need to happen after a build completes
   - Pushes the state change to the end of the current event loop

### Example Fix:

Instead of:
```dart
@override
Widget build(BuildContext context) {
  // THIS CAUSES ERRORS:
  controller.setContainerBounds(Rect.fromLTWH(0, 0, context.width, context.height));
  // ...rest of build
}
```

We now use:
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // This is safe:
  final screenSize = MediaQuery.of(context).size;
  controller.setContainerBoundsIfChanged(
    Rect.fromLTWH(0, 0, screenSize.width, screenSize.height)
  );
}
```

### Other Areas We Fixed:

1. **Auto-hiding toolbar**:
   - Simplified the widget structure to avoid overflow errors
   - Removed nested Column widgets that were trying to fit into a 5px container

2. **Dialogs and Navigation**:
   - Using `Future.microtask()` for dialog showing and navigation
   - This ensures the operations happen after the current build cycle completes

### General Best Practices:

1. Never call setState() inside build()
2. Use StatefulWidget and proper lifecycle methods
3. Defer state changes with Future.microtask() when needed
4. Prefer conditional rebuilds (only update when truly needed)
5. For controller-based patterns like GetX, implement safety checks
6. Consider using keys for widgets that need specific identity across rebuilds