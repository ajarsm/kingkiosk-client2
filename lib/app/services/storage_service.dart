import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  final GetStorage _box = GetStorage();

  StorageService init() {
    return this;
  }

  // Store any type of data
  void write(String key, dynamic value) {
    _box.write(key, value);
  }

  // Read data
  T? read<T>(String key) {
    return _box.read<T>(key);
  }

  // Remove a single key
  void remove(String key) {
    _box.remove(key);
  }

  // Clear all storage
  Future<void> erase() async {
    await _box.erase();
  }

  // Listen to changes on a specific key
  void listenKey(String key, Function(dynamic) callback) {
    _box.listenKey(key, callback);
  }
}