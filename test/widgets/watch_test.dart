import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lap_tracking/keys.dart';
import 'package:lap_tracking/widgets/watch.dart';

import '../test_util.dart';

void main() {
  testWidgets('render unstarted', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        Watch(
          total: Duration(),
        ),
      ),
    );
    expect(
        find.byKey(Key(Keys.WATCH_TOTAL_TIME)).hitTestable(), findsOneWidget);
    expect(find.byKey(Key(Keys.WATCH_CURRENT_LAP_TIME)), findsNothing);
  });
  testWidgets('render time past', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        Watch(
          total: Duration(minutes: 45, seconds: 20, milliseconds: 980),
        ),
      ),
    );
    final richTextWidget = tester
        .element(find.byKey(Key(Keys.WATCH_TOTAL_TIME)))
        .widget as RichText;

    final actual =
        richTextWidget.text.text + richTextWidget.text.children[0].text;

    expect(actual, "45:20 98");
    expect(find.byKey(Key(Keys.WATCH_CURRENT_LAP_TIME)), findsNothing);
  });
  testWidgets('render current lap', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        Watch(
          total:
              Duration(hours: 1, minutes: 45, seconds: 20, milliseconds: 980),
          currentLap: Duration(seconds: 10, milliseconds: 45),
        ),
      ),
    );
    final richTextWidget = tester
        .element(find.byKey(Key(Keys.WATCH_TOTAL_TIME)))
        .widget as RichText;
    final actual =
        richTextWidget.text.text + richTextWidget.text.children[0].text;
    expect(actual, "1:45 20");
    expect(find.byKey(Key(Keys.WATCH_CURRENT_LAP_TIME)), findsOneWidget);
    expect(find.text("00:10:04"), findsOneWidget);
  });
}
