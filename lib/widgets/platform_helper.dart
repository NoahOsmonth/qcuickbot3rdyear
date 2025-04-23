// This file conditionally exports the correct PlatformHelper implementation.

export '../utils/_platform_helper_stub.dart' // Stub implementation (web)
    if (dart.library.io) '../utils/_platform_helper_io.dart'; // IO implementation (mobile/desktop)
