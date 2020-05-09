import 'package:flutter_test/flutter_test.dart';
import 'package:lap_tracking/utils/time_util.dart';

void main() {
  test('formatLapItemTime', () async {
    expect(
      TimeUtil.formatLapItemTime(Duration()),
      "00:00:00",
    );
    expect(
      TimeUtil.formatLapItemTime(
          Duration(hours: 1, minutes: 1, seconds: 1, milliseconds: 100)),
      "01:01:01",
    );
    expect(
      TimeUtil.formatLapItemTime(Duration(milliseconds: 1234567890)),
      "342:56:07",
    );
    expect(
      TimeUtil.formatLapItemTime(Duration(milliseconds: 1000)),
      "00:01:00",
    );
    expect(
      TimeUtil.formatLapItemTime(Duration(milliseconds: 3600000)),
      "01:00:00",
    );
    expect(
      TimeUtil.formatLapItemTime(Duration(milliseconds: 3599990)),
      "59:59:99",
    );
  });
  test('formatWatchTime', () async {
    expect(
      TimeUtil.formatWatchTime(Duration()),
      "0 00",
    );
    expect(
      TimeUtil.formatWatchTime(
          Duration(hours: 1, minutes: 1, seconds: 1, milliseconds: 100)),
      "1:01 01",
    );
    expect(
      TimeUtil.formatWatchTime(Duration(milliseconds: 1234567890)),
      "342:56 07",
    );
    expect(
      TimeUtil.formatWatchTime(Duration(milliseconds: 1000)),
      "1 00",
    );
    expect(
      TimeUtil.formatWatchTime(Duration(milliseconds: 3600000)),
      "1:00 00",
    );
    expect(
      TimeUtil.formatWatchTime(
          Duration(minutes: 10, seconds: 1, milliseconds: 100)),
      "10:01 10",
    );
    expect(
      TimeUtil.formatWatchTime(Duration(milliseconds: 3599990)),
      "59:59 99",
    );
  });
}
