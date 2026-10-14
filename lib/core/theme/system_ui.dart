import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android draws edge to edge (enforced from Android 15): the app runs behind a
/// transparent navigation bar, so its icons need a contrast that matches what
/// is behind them. Only the navigation bar is set here; each screen's app bar
/// keeps deciding the status bar.
const SystemUiOverlayStyle lightSurfaceNavBar = SystemUiOverlayStyle(
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: true,
);

/// For a screen whose bottom edge is dark (the camera).
const SystemUiOverlayStyle darkSurfaceNavBar = SystemUiOverlayStyle(
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: true,
);
