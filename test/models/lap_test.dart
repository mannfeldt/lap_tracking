import 'package:flutter_test/flutter_test.dart';
import 'package:lap_tracking/models/lap.dart';

void main() {
  test('speedVisual', () {
    expect(
      Lap(speed: 10.05).speedVisual,
      "36.18 km/h",
    );
    expect(
      Lap(speed: 1).speedVisual,
      "3.60 km/h",
    );
    expect(
      Lap(speed: 1).speedVisual,
      "3.60 km/h",
    );
    expect(
      Lap(speed: 12.234654).speedVisual,
      "44.04 km/h",
    );
    expect(
      Lap(speed: 0.0).speedVisual,
      "0.00 km/h",
    );
  });
  test('distanceVisual', () {
    expect(
      Lap(distance: 10.50).distanceVisual,
      "11 m",
    );
    expect(
      Lap(distance: 10.499).distanceVisual,
      "10 m",
    );
    expect(
      Lap(distance: 10.0).distanceVisual,
      "10 m",
    );
    expect(
      Lap(distance: 10050.0).distanceVisual,
      "10 050 m",
    );
  });
  test('voiceOver', () {
    expect(
      Lap(
        index: 0,
        distance: 100.0,
        speed: 10.0,
        lapTime:
            Duration(hours: 2, minutes: 15, seconds: 10, milliseconds: 900),
      ).voiceOver,
      "100 meters completed in 2 hours 15 minutes 10 seconds. Average speed 36.00 kilometers per hour",
    );
    expect(
      Lap(
        index: 0,
        distance: 10050.0,
        speed: 20.5,
        lapTime: Duration(hours: 2),
      ).voiceOver,
      "10050 meters completed in 2 hours  . Average speed 73.80 kilometers per hour",
    );
    expect(
      Lap(
        index: 1,
        distance: 100.0,
        speed: 10.0,
        lapTime:
            Duration(hours: 2, minutes: 15, seconds: 10, milliseconds: 900),
      ).voiceOver,
      "Lap 2 completed in 2 hours 15 minutes 10 seconds. Average speed 36.00 kilometers per hour",
    );
    expect(
      Lap(
        index: 2,
        distance: 90.0,
        speed: 20.5,
        lapTime: Duration(hours: 2),
      ).voiceOver,
      "Lap 3 completed in 2 hours  . Average speed 73.80 kilometers per hour",
    );
    expect(
      Lap(
        index: 3,
        distance: 80.75,
        speed: 15.5,
        lapTime: Duration(hours: 2, seconds: 30),
      ).voiceOver,
      "Lap 4 completed in 2 hours  30 seconds. Average speed 55.80 kilometers per hour",
    );
    expect(
      Lap(
        index: 4,
        distance: 50.0,
        speed: 0.0,
        lapTime: Duration(seconds: 30),
      ).voiceOver,
      "Lap 5 completed in   30 seconds. Average speed 0.00 kilometers per hour",
    );
  });
}
