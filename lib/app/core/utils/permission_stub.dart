/// Permission handler stub for web platform
/// This file provides minimal stub implementations for permission_handler package

// Stub Permission class
class Permission {
  static final Permission photos = Permission._();
  static final Permission storage = Permission._();

  Permission._();

  Future<PermissionStatus> request() async => PermissionStatus.granted;
  Future<PermissionStatus> get status async => PermissionStatus.granted;
}

// Stub PermissionStatus class
class PermissionStatus {
  static final PermissionStatus granted = PermissionStatus._('granted');
  static final PermissionStatus denied = PermissionStatus._('denied');
  static final PermissionStatus permanentlyDenied =
      PermissionStatus._('permanentlyDenied');

  final String _status;
  PermissionStatus._(this._status);

  bool get isGranted => _status == 'granted';
  bool get isDenied => _status == 'denied';
  bool get isPermanentlyDenied => _status == 'permanentlyDenied';
}

// Stub method for opening app settings
Future<bool> openAppSettings() async {
  return false;
}
