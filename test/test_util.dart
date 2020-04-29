import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TestUtil {
  static Widget wrapWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }
}
