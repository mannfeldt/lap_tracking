import 'package:flutter_test/flutter_test.dart';
import 'package:lap_tracking/utils/time_util.dart';

void main() {
  test('formatTime', () async {
    expect(
      TimeUtil.formatTime(Duration()),
      "00:00:00",
    );
    expect(
      TimeUtil.formatTime(
          Duration(hours: 1, minutes: 1, seconds: 1, milliseconds: 100)),
      "01:01:01",
    );
    expect(
      TimeUtil.formatTime(Duration(milliseconds: 1234567890)),
      "342:56:07",
    );
    expect(
      TimeUtil.formatTime(Duration(milliseconds: 1000)),
      "00:01:00",
    );
    expect(
      TimeUtil.formatTime(Duration(milliseconds: 3600000)),
      "01:00:00",
    );
    expect(
      TimeUtil.formatTime(Duration(milliseconds: 3599990)),
      "59:59:99",
    );
  });
}
