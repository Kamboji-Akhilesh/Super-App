import 'package:flutter/material.dart';

/// Global navigator key so non-widget code (e.g. notification tap handlers in
/// `main`) can push routes without a [BuildContext].
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
