import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lap_tracking/keys.dart';
import 'package:lap_tracking/models/watch_state.dart';
import 'package:lap_tracking/widgets/watch_toolbar.dart';

import '../test_util.dart';

void main() {
  testWidgets('render unstarted', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        WatchToolbar(
          state: WatchState.unstarted,
        ),
      ),
    );
    expect(
        find.byKey(Key(Keys.START_STOP_BUTTON)).hitTestable(), findsOneWidget);
    expect(find.byKey(Key(Keys.RESET_BUTTON)).hitTestable(), findsNothing);
    expect(find.byKey(Key(Keys.LAP_BUTTON)).hitTestable(), findsNothing);
    expect(find.byKey(Key(Keys.FINISH_BUTTON)).hitTestable(), findsNothing);
  });
  testWidgets('render running', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        WatchToolbar(
          state: WatchState.running,
        ),
      ),
    );
    expect(
        find.byKey(Key(Keys.START_STOP_BUTTON)).hitTestable(), findsOneWidget);
    expect(find.byKey(Key(Keys.RESET_BUTTON)).hitTestable(), findsOneWidget);
    expect(find.byKey(Key(Keys.LAP_BUTTON)).hitTestable(), findsOneWidget);
    expect(find.byKey(Key(Keys.FINISH_BUTTON)).hitTestable(), findsNothing);
  });
  testWidgets('render stopped', (WidgetTester tester) async {
    await tester.pumpWidget(
      TestUtil.wrapWidget(
        WatchToolbar(
          state: WatchState.stopped,
        ),
      ),
    );
    expect(
        find.byKey(Key(Keys.START_STOP_BUTTON)).hitTestable(), findsOneWidget);
    expect(find.byKey(Key(Keys.RESET_BUTTON)).hitTestable(), findsOneWidget);
    expect(find.byKey(Key(Keys.LAP_BUTTON)).hitTestable(), findsNothing);
    expect(find.byKey(Key(Keys.FINISH_BUTTON)).hitTestable(), findsOneWidget);
  });
}
