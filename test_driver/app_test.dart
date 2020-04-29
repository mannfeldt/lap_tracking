import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:lap_tracking/keys.dart';

class Waypoint {
  double longitude;
  double latitude;
  double altitude;
  double speed;
  Waypoint({this.latitude, this.longitude, this.speed, this.altitude}) {
    this.longitude = longitude;
    this.latitude = latitude;
    this.speed = speed;
    this.altitude = altitude;
  }
}

void main() {
  final String adbPath =
      'C:/Users/emilm/AppData/Local/Android/Sdk/platform-tools/adb.exe';

  Future<void> createPath(List<Waypoint> path, Duration interval) async {
    for (Waypoint point in path) {
      String input =
          '${point.longitude} ${point.latitude} 1.0 12 ${point.speed}';
      print(input);
      await Process.run(adbPath, ['emu', 'geo', 'fix', input]);
      await Future.delayed(interval);
    }
  }

  group('app', () {
    final totalTimeTextFinder = find.byValueKey(Keys.WATCH_TOTAL_TIME);
    final currentLapTimeTextFinder =
        find.byValueKey(Keys.WATCH_CURRENT_LAP_TIME);
    final startStopButtonFinder = find.byValueKey(Keys.START_STOP_BUTTON);
    final resetButtonFinder = find.byValueKey(Keys.RESET_BUTTON);
    final lapButtonFinder = find.byValueKey(Keys.LAP_BUTTON);

    SerializableFinder lapTitleFinder(int index) {
      return find.byValueKey(Keys.lapListItem(index));
    }

    FlutterDriver driver;

    setUpAll(() async {
      final Map<String, String> envVars = Platform.environment;

      print(envVars['ANDROID_HOME']);

      await Process.run(adbPath, [
        'shell',
        'pm',
        'grant',
        'com.example.lap_tracking',
        'android.permission.ACCESS_FINE_LOCATION'
      ]);
      await Process.run(adbPath, [
        'shell',
        'pm',
        'grant',
        'com.example.lap_tracking',
        'android.permission.ACCESS_COARSE_LOCATION'
      ]);

      await Process.run(adbPath, [
        'emu',
        'geo',
        'fix',
        '16.51761953762901 59.37445968372966 11 12 13'
      ]);

      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test('starts at 0', () async {
      expect(await driver.getText(totalTimeTextFinder), "00:00:00");
    });

    test('start stop watch', () async {
      await driver.tap(startStopButtonFinder);
      await Future.delayed(Duration(milliseconds: 2500));
      await driver.tap(startStopButtonFinder);
      String totalTimePast = await driver.getText(totalTimeTextFinder);
      expect(totalTimePast.contains("00:02:"), true);
      await driver.tap(startStopButtonFinder);
      await Future.delayed(Duration(milliseconds: 2000));
      await driver.tap(startStopButtonFinder);
      totalTimePast = await driver.getText(totalTimeTextFinder);
      expect(totalTimePast.contains("00:04:"), true);
    });
    test('reset', () async {
      await driver.tap(resetButtonFinder);
      String totalTimePast = await driver.getText(totalTimeTextFinder);
      expect(totalTimePast, "00:00:00");
    });
    test('do manual laps', () async {
      await driver.tap(startStopButtonFinder);
      await Future.delayed(Duration(milliseconds: 2500));

      await driver.tap(lapButtonFinder);
      await Future.delayed(Duration(milliseconds: 2500));
      await driver.tap(startStopButtonFinder);

      String totalTimePast = await driver.getText(totalTimeTextFinder);
      String currentLapTimePast =
          await driver.getText(currentLapTimeTextFinder);
      String lapItemTitle = await driver.getText(
        find.descendant(
          of: lapTitleFinder(0),
          matching: find.byValueKey(Keys.LAP_LIST_ITEM_TITLE),
        ),
      );

      expect(totalTimePast.contains("00:05:"), true);
      expect(currentLapTimePast.contains("00:02:"), true);
      expect(lapItemTitle.contains("#1    00:02:"), true);

      await driver.tap(startStopButtonFinder);
      await Future.delayed(Duration(milliseconds: 2500));
      await driver.tap(lapButtonFinder);
      expect(await isPresent(lapTitleFinder(1), driver), true);

      await Future.delayed(Duration(milliseconds: 2000));
      await driver.tap(lapButtonFinder);
      expect(await isPresent(lapTitleFinder(2), driver), true);

      await Future.delayed(Duration(milliseconds: 2000));
      await driver.tap(lapButtonFinder);
      expect(await isPresent(lapTitleFinder(3), driver), true);

      await Future.delayed(Duration(milliseconds: 2000));
      await driver.tap(startStopButtonFinder);
    });
    test(
      'do automatic laps',
      () async {
        await driver.tap(resetButtonFinder);
        await createPath(
          [
            Waypoint(
              latitude: 59.373900,
              longitude: 16.519100,
              speed: 4.0,
            ),
          ],
          Duration(milliseconds: 1000),
        );
        await Future.delayed(Duration(milliseconds: 1000));
        await driver.tap(startStopButtonFinder);

        await createPath(
          [
            Waypoint(
              latitude: 59.37367871298749,
              longitude: 16.519485947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37337871298749,
              longitude: 16.519785947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37317871298749,
              longitude: 16.519985947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37287871298749,
              longitude: 16.520985947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37257871298749,
              longitude: 16.522985947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37237871298749,
              longitude: 16.523985947693707,
              speed: 4.0,
            ),
            //vänder tillbaka
            Waypoint(
              latitude: 59.37257871298749,
              longitude: 16.522985947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37257871298749,
              longitude: 16.522985947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37287871298749,
              longitude: 16.520985947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37317871298749,
              longitude: 16.519985947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37337871298749,
              longitude: 16.519785947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.37367871298749,
              longitude: 16.519485947693707,
              speed: 4.0,
            ),
            Waypoint(
              latitude: 59.373900,
              longitude: 16.519100,
              speed: 4.0,
            ),
          ],
          Duration(milliseconds: 2000),
        );
        // expect(await isPresent(lapTitleFinder(0), driver), false);

        //return to start
        await createPath(
          [
            Waypoint(
              latitude: 59.373900,
              longitude: 16.519100,
              speed: 4.0,
            ),
          ],
          Duration(milliseconds: 2000),
        );
        await Future.delayed(Duration(seconds: 10));

        expect(await isPresent(lapTitleFinder(0), driver), true);
      },
      timeout: Timeout(Duration(minutes: 5)),
    );
  });
}

Future<bool> isPresent(SerializableFinder byValueKey, FlutterDriver driver,
    {Duration timeout = const Duration(seconds: 1)}) async {
  try {
    await driver.waitFor(byValueKey, timeout: timeout);
    return true;
  } catch (exception) {
    return false;
  }
}
