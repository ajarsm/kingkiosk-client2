/// Web stub for dart:io
/// This file provides minimal stub implementations for features used from dart:io

// Stub Platform class
class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isWeb => true;
  static String get operatingSystem => 'web';
}

// Stub File class
class File {
  final String path;

  File(this.path);

  Future<bool> exists() async => false;
  Future<File> writeAsBytes(List<int> bytes) async => this;
}

// Stub Directory class
class Directory {
  final String path;

  Directory(this.path);

  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}
