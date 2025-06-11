import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'lib/app/modules/home/controllers/tiling_window_controller.dart';
import 'lib/app/data/models/window_tile_v2.dart';

void main() {
  group('Calendar MQTT Integration Tests', () {
    late TilingWindowController tilingController;

    setUp(() {
      Get.testMode = true;
      tilingController = TilingWindowController();
      Get.put<TilingWindowController>(tilingController);
    });

    tearDown(() {
      Get.reset();
    });

    test('should create calendar tile via addCalendarTile method', () {
      // Act
      tilingController.addCalendarTile('Test Calendar');

      // Assert
      expect(tilingController.tiles.length, equals(1));
      expect(tilingController.tiles.first.type, equals(TileType.calendar));
      expect(tilingController.tiles.first.name, equals('Test Calendar'));
    });

    test('should create calendar tile with specific ID', () {
      // Act
      tilingController.addCalendarTileWithId('cal-123', 'Calendar with ID');

      // Assert
      expect(tilingController.tiles.length, equals(1));
      expect(tilingController.tiles.first.id, equals('cal-123'));
      expect(tilingController.tiles.first.name, equals('Calendar with ID'));
      expect(tilingController.tiles.first.type, equals(TileType.calendar));
    });

    test('should handle multiple calendar tiles', () {
      // Act
      tilingController.addCalendarTile('Calendar 1');
      tilingController.addCalendarTileWithId('cal-456', 'Calendar 2');

      // Assert
      expect(tilingController.tiles.length, equals(2));
      expect(
          tilingController.tiles
              .where((t) => t.type == TileType.calendar)
              .length,
          equals(2));
    });

    test('should be able to remove calendar tiles by ID', () {
      // Arrange
      tilingController.addCalendarTileWithId(
          'cal-to-remove', 'Removable Calendar');
      expect(tilingController.tiles.length, equals(1));

      // Act - Use existing method to remove tile
      final initialLength = tilingController.tiles.length;
      tilingController.tiles.removeWhere((tile) => tile.id == 'cal-to-remove');

      // Assert
      expect(tilingController.tiles.length, equals(initialLength - 1));
    });
  });
}
