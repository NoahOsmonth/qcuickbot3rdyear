// IO implementation for non-web platforms
import 'dart:io';

class PlatformHelper {
  static bool get isWeb => false;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}
