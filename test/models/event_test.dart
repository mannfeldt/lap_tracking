import 'package:flutter_test/flutter_test.dart';
import 'package:lap_tracking/models/event.dart';
import 'package:lap_tracking/models/lap.dart';

void main() {
  test('distance', () {
    expect(
      Event(laps: [
        Lap(distance: 1.15),
        Lap(distance: 150),
        Lap(distance: 1150),
        Lap(distance: 1234.56)
      ]).distance,
      2535.71,
    );
  });
}
