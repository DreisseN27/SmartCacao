import 'package:permission_handler/permission_handler.dart' as ph;

/// Utility class for managing app permissions
class PermissionUtils {
  /// Request camera permission at runtime
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await ph.Permission.camera.request();
      print('Camera permission status: ${status.isDenied ? 'Denied' : status.isPermanentlyDenied ? 'Permanently Denied' : 'Granted'}');
      return status.isGranted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Request storage permissions at runtime (optional for this app)
  static Future<bool> requestStoragePermission() async {
    try {
      final status = await ph.Permission.storage.request();
      print('Storage permission status: ${status.isDenied ? 'Denied' : status.isPermanentlyDenied ? 'Permanently Denied' : 'Granted'}');
      return status.isGranted;
    } catch (e) {
      print('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Request all necessary permissions for the app
  /// Returns true if camera permission is granted (camera is essential)
  static Future<bool> requestAllPermissions() async {
    try {
      print('Requesting camera permission...');
      final cameraStatus = await ph.Permission.camera.request();
      print('Camera permission result: $cameraStatus');
      
      // Camera is essential, storage is optional
      if (cameraStatus.isDenied) {
        print('Camera permission was denied');
        return false;
      } else if (cameraStatus.isPermanentlyDenied) {
        print('Camera permission is permanently denied - need to open app settings');
        return false;
      }
      
      print('Camera permission granted successfully');
      // Try to request storage but don't fail if it's denied
      try {
        await ph.Permission.storage.request();
      } catch (e) {
        print('Storage permission request failed (non-critical): $e');
      }
      
      return true;
    } catch (e) {
      print('Error in requestAllPermissions: $e');
      return false;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    final status = await ph.Permission.camera.status;
    return status.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    final status = await ph.Permission.storage.status;
    return status.isGranted;
  }

  /// Open app settings for permission configuration
  static Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
}
