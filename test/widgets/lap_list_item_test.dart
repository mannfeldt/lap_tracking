import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lap_tracking/keys.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/widgets/lap_list_item.dart';

import '../test_util.dart';

void main() {
  testWidgets('render item', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        LapListItem(
          Lap(
            lapTime: Duration(seconds: 10),
            totalTime: Duration(seconds: 15),
            speed: 10.0,
            distance: 20.0,
            index: 0,
          ),
        ),
      ),
    );

    expect(find.byKey(Key(Keys.lapListItem(0))), findsOneWidget);
    expect(find.text("#1    00:10:00  00:15:00"), findsOneWidget);
    expect(find.text("20 m"), findsOneWidget);
    expect(find.text("36.00 km/h"), findsOneWidget);
  });
  testWidgets('render lap 10', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        LapListItem(
          Lap(
            lapTime: Duration(seconds: 10),
            totalTime: Duration(seconds: 15),
            speed: 10.0,
            distance: 20.0,
            index: 9,
          ),
        ),
      ),
    );

    expect(find.byKey(Key(Keys.lapListItem(9))), findsOneWidget);
    expect(find.text("#10  00:10:00  00:15:00"), findsOneWidget);
    expect(find.text("20 m"), findsOneWidget);
    expect(find.text("36.00 km/h"), findsOneWidget);
  });
}
