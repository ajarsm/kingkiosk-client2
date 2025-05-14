import 'package:flutter/material.dart';
import 'window_tile_v2.dart';

enum SplitDirection {
  horizontal,   // Split left/right
  vertical,     // Split top/bottom
}

enum TilePosition {
  only,         // The only tile in a container
  first,        // First tile in split (left or top)
  second,       // Second tile in split (right or bottom)
}

/// Represents a node in the tiling layout tree
class TilingNode {
  // If this is a split node, it has these properties:
  SplitDirection? splitDirection;
  TilingNode? firstChild;
  TilingNode? secondChild;
  double splitRatio; // 0.0-1.0, position of the split (default 0.5 = middle)
  
  // If this is a leaf node (contains a window), it has these properties:
  WindowTile? content;
  
  // All nodes have these properties
  Rect bounds = Rect.zero; // Position and size within the parent container
  
  /// Creates a node containing a window tile
  TilingNode.withContent(this.content)
    : splitDirection = null,
      firstChild = null, 
      secondChild = null,
      splitRatio = 0.5;
  
  /// Creates a split node with two children
  TilingNode.withSplit({
    required this.splitDirection,
    required this.firstChild,
    required this.secondChild,
    this.splitRatio = 0.5,
  }) : content = null;
  
  /// Returns true if this is a leaf node (contains content)
  bool get isLeaf => content != null;
  
  /// Returns true if this is a split node (contains children)
  bool get isSplit => splitDirection != null && firstChild != null && secondChild != null;
  
  /// Creates a split with the current content as the first child and the new content as the second
  void splitWith(WindowTile newContent, SplitDirection direction) {
    if (!isLeaf) return; // Can only split leaf nodes
    
    final currentContent = this.content;
    if (currentContent == null) return;
    
    // Create two new nodes with the content
    final first = TilingNode.withContent(currentContent);
    final second = TilingNode.withContent(newContent);
    
    // Update this node to be a split node
    this.content = null;
    this.splitDirection = direction;
    this.firstChild = first;
    this.secondChild = second;
  }
  
  /// Layout the node and its children within the given bounds
  void layout(Rect containerBounds) {
    this.bounds = containerBounds;
    
    if (!isSplit) return;
    
    if (splitDirection == SplitDirection.horizontal) {
      // Horizontal split (left/right)
      final splitPoint = containerBounds.left + containerBounds.width * splitRatio;
      
      firstChild!.layout(Rect.fromLTRB(
        containerBounds.left,
        containerBounds.top,
        splitPoint,
        containerBounds.bottom
      ));
      
      secondChild!.layout(Rect.fromLTRB(
        splitPoint,
        containerBounds.top,
        containerBounds.right,
        containerBounds.bottom
      ));
    } else {
      // Vertical split (top/bottom)
      final splitPoint = containerBounds.top + containerBounds.height * splitRatio;
      
      firstChild!.layout(Rect.fromLTRB(
        containerBounds.left,
        containerBounds.top,
        containerBounds.right,
        splitPoint
      ));
      
      secondChild!.layout(Rect.fromLTRB(
        containerBounds.left,
        splitPoint,
        containerBounds.right,
        containerBounds.bottom
      ));
    }
  }
  
  /// Find the node containing the given window tile
  TilingNode? findNodeWithContent(WindowTile tile) {
    if (isLeaf) {
      return content?.id == tile.id ? this : null;
    }
    
    if (!isSplit) return null;
    
    // Check children
    final inFirst = firstChild!.findNodeWithContent(tile);
    if (inFirst != null) return inFirst;
    
    return secondChild!.findNodeWithContent(tile);
  }
  
  /// Updates content's position and size to match layout bounds
  void updateContentBounds() {
    if (isLeaf && content != null) {
      content!.position = Offset(bounds.left, bounds.top);
      content!.size = Size(bounds.width, bounds.height);
    }
    
    if (isSplit) {
      firstChild!.updateContentBounds();
      secondChild!.updateContentBounds();
    }
  }
  
  /// Remove the given tile and restructure the tree
  bool removeTile(WindowTile tile, TilingNode? parent, [TilePosition? position]) {
    // If this is a leaf with matching content
    if (isLeaf && content?.id == tile.id) {
      if (parent == null) {
        // This is the root node and only tile, just clear the content
        content = null;
      } else {
        // Replace parent with the sibling of this node
        if (position == TilePosition.first) {
          parent.content = parent.secondChild!.content;
          parent.splitDirection = null;
          parent.firstChild = null; 
          parent.secondChild = null;
        } else {
          parent.content = parent.firstChild!.content;
          parent.splitDirection = null;
          parent.firstChild = null;
          parent.secondChild = null;
        }
      }
      return true;
    }
    
    // If this is a split node, check children
    if (isSplit) {
      if (firstChild!.removeTile(tile, this, TilePosition.first)) {
        return true;
      }
      
      if (secondChild!.removeTile(tile, this, TilePosition.second)) {
        return true;
      }
    }
    
    return false;
  }
}

/// Main tiling layout manager
class TilingLayout {
  TilingNode root = TilingNode.withContent(null);
  
  /// Adds a tile to the layout
  void addTile(WindowTile tile, {WindowTile? targetTile, SplitDirection? direction}) {
    if (root.content == null && !root.isSplit) {
      // First tile in the layout
      root.content = tile;
      return;
    }
    
    if (targetTile != null && direction != null) {
      // Find the node containing the target tile
      final targetNode = root.findNodeWithContent(targetTile);
      if (targetNode != null) {
        targetNode.splitWith(tile, direction);
      }
    } else {
      // Default to splitting the last added tile, using alternating directions
      final lastNode = _findDeepestRightNode(root);
      if (lastNode != null && lastNode.isLeaf) {
        final parentDirection = _findNodeParentSplitDirection(root, lastNode);
        // Alternate split direction
        final newDirection = (parentDirection == SplitDirection.horizontal)
            ? SplitDirection.vertical
            : SplitDirection.horizontal;
        lastNode.splitWith(tile, newDirection);
      }
    }
  }
  
  /// Removes a tile from the layout
  void removeTile(WindowTile tile) {
    root.removeTile(tile, null);
  }
  
  /// Applies the layout to the tiles, updating their positions and sizes
  void applyLayout(Rect containerBounds) {
    root.layout(containerBounds);
    root.updateContentBounds();
  }
  
  /// Find the deepest rightmost/bottommost node (for default tile placement)
  TilingNode? _findDeepestRightNode(TilingNode node) {
    if (node.isLeaf) return node;
    if (!node.isSplit) return null;
    
    // Try the second child first (right/bottom)
    final inSecond = _findDeepestRightNode(node.secondChild!);
    if (inSecond != null) return inSecond;
    
    // If no leaf in second child, try the first
    return _findDeepestRightNode(node.firstChild!);
  }
  
  /// Find the split direction of the parent of the given node
  SplitDirection _findNodeParentSplitDirection(TilingNode current, TilingNode target) {
    if (!current.isSplit) return SplitDirection.horizontal;
    
    if (current.firstChild == target || current.secondChild == target) {
      return current.splitDirection!;
    }
    
    // Check children
    if (current.firstChild!.findNodeWithContent(target.content!) != null) {
      return _findNodeParentSplitDirection(current.firstChild!, target);
    }
    
    if (current.secondChild!.findNodeWithContent(target.content!) != null) {
      return _findNodeParentSplitDirection(current.secondChild!, target);
    }
    
    return SplitDirection.horizontal; // Default
  }
}