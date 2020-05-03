import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/widgets/lap_list.dart';
import 'package:lap_tracking/widgets/lap_list_item.dart';

import '../test_util.dart';

void main() {
  final GlobalKey<AnimatedListState> _lapListKey =
      GlobalKey<AnimatedListState>();
  testWidgets('render empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        LapList(
          laps: [],
        ),
      ),
    );

    expect(find.byType(LapListItem), findsNothing);
  });
  testWidgets('render one item', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        LapList(
          lapListKey: _lapListKey,
          laps: [
            Lap(
              lapTime: Duration(seconds: 10),
              totalTime: Duration(seconds: 15),
              speed: 10.0,
              distance: 20.0,
              index: 0,
            )
          ],
        ),
      ),
    );
    _lapListKey.currentState.insertItem(0);
    await tester.pumpAndSettle();
    expect(find.byType(LapListItem), findsOneWidget);
  });
  testWidgets('render multiple items', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        LapList(
          lapListKey: _lapListKey,
          laps: [
            Lap(
              lapTime: Duration(seconds: 10),
              totalTime: Duration(seconds: 15),
              speed: 10.0,
              distance: 20.0,
              index: 0,
            ),
            Lap(
              lapTime: Duration(seconds: 10),
              totalTime: Duration(seconds: 15),
              speed: 10.0,
              distance: 20.0,
              index: 0,
            ),
            Lap(
              lapTime: Duration(seconds: 10),
              totalTime: Duration(seconds: 15),
              speed: 10.0,
              distance: 20.0,
              index: 0,
            )
          ],
        ),
      ),
    );
    _lapListKey.currentState.insertItem(0);
    _lapListKey.currentState.insertItem(0);
    _lapListKey.currentState.insertItem(0);

    await tester.pumpAndSettle();

    expect(find.byType(LapListItem), findsNWidgets(3));
  });
}
