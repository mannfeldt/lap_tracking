import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lap_tracking/models/lap.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

// class PathPoint {
//   double latitude;
//   double longitude;
//   DateTime timeStamp;
//   double speed;
// }

//! nu är det dags att snygga till koden. dela upp i widgets. implementera provider?
// lite testfall.
class _HomeState extends State<Home> {
  //lite problem att ha två klockor? bättre med en och sen får vi dela upp så att varvtiden som visas på currentlap varv 2 och frammåt är:
  //watch.elapsed - laps.fold(lap.time) ja det blir hundra delar som blir fel.
  Stopwatch watch;
  Stopwatch lapWatch;
  String totalTimeString = "00:00:00";
  String lapTimeString = "";

  final timerTick = const Duration(milliseconds: 40);
  bool isPaused = false;
  Position startPosition;
  List<Position> path = [];
  List<Position> currentLapPath = [];
  List<Lap> laps = [];
  StreamSubscription<Position> positionStream;
  String currentSpeed = "";
  String avarageSpeed = "";
  String currentSpeed2 = "";
  String avarageSpeed2 = "";
  double distance = 0.0;
  LocationOptions locationOptions =
      LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 2);
  Lap currentLap;

  TextEditingController distanceFilterController = TextEditingController();
  TextEditingController timeIntervalController = TextEditingController();

  @override
  void initState() {
    watch = Stopwatch();
    lapWatch = Stopwatch();
    currentLap = Lap();
    super.initState();
  }

  String formatTime(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
    } else {
      return "${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}:${((duration.inMilliseconds / 10) % 100).floor().toString().padLeft(2, '0')}";
    }
  }

  void onNewPosition(Position position) async {
    Position lastPosition = path[path.length - 1];

    Duration travelTime = position.timestamp.difference(lastPosition.timestamp);

    double avgSpeed =
        path.fold(0, (sum, item) => sum + item.speed) / path.length;

    double newDistance = await getDistance(lastPosition, position);

    double avgSpeed2 = distance / watch.elapsed.inSeconds;

    double currspeed2 = getSpeedFromDistance(newDistance, travelTime);

    setState(() {
      path.add(position);
      currentLapPath.add(position);
      currentSpeed = "${position.speed.toStringAsFixed(2)}m/s}";
      avarageSpeed = "${avgSpeed.toStringAsFixed(2)}m/s}";
      avarageSpeed2 = "${avgSpeed2.toStringAsFixed(2)}m/s}";
      currentSpeed2 = "${currspeed2.toStringAsFixed(2)}m/s}";

      distance += newDistance;
      currentLap.distance += newDistance;
    });

    double distanceFromStart = await getDistance(position, startPosition);
    print("distance from start:" + distanceFromStart.toString());
    bool lapCompleted = await isBackAtStartPos(position);

    if (lapCompleted) {
      print("NEW LAP!!!!!");
      startNewLap();
    }
  }

  void startNewLap() {
    setState(() {
      laps.add(
        Lap(
          distance: currentLap.distance,
          path: currentLapPath,
          time: lapWatch.elapsed,
        ),
      );
      currentLap = Lap();
    });
    lapWatch.reset();
  }

  void tick() {
    if (watch.isRunning) {
      Timer(timerTick, tick);
      setState(() {
        totalTimeString = formatTime(watch.elapsed);
        if (laps.length > 0) {
          lapTimeString = formatTime(lapWatch.elapsed);
        }
      });
    }
  }

  Future<bool> isBackAtStartPos(Position position) async {
    bool atStartPos = await atSameLocation(position, startPosition);
    bool hasMovedFromStartPos = path.length > 10 &&
        position.timestamp.difference(startPosition.timestamp).inSeconds > 10;
    return hasMovedFromStartPos && atStartPos;
  }

  Future<bool> atSameLocation(Position a, Position b) async {
    double distanceInMeters = await Geolocator()
        .distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
    return distanceInMeters < 5.0;
  }

  Future<double> getDistance(Position a, Position b) async {
    return await Geolocator()
        .distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  Future<double> getSpeedFromPositions(
      Position a, Position b, Duration travelTime) async {
    return (await getDistance(a, b) / (travelTime.inMilliseconds / 1000))
        .roundToDouble();
  }

  double getSpeedFromDistance(double meters, Duration travelTime) {
    return (meters / (travelTime.inMilliseconds / 1000)).roundToDouble();
  }

  void setStartPosition() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      startPosition = position;
      path.add(position);
    });
    positionStream.resume();
  }

  void startwatch() async {
    if (positionStream == null) {
      var geolocator = Geolocator();
      positionStream =
          geolocator.getPositionStream(locationOptions).listen(onNewPosition);
    }

    if (!isPaused) {
      setStartPosition();
    } else {
      setState(() {
        isPaused = false;
      });
    }
    watch.start();
    lapWatch.start();

    tick();
  }

  void stopWatch() {
    watch.stop();
    lapWatch.stop();

    setState(() {
      isPaused = true;
    });
    positionStream.pause();
  }

  void resetWatch() {
    watch.reset();
    lapWatch.reset();
    setState(() {
      isPaused = false;
      totalTimeString = "00:00:00";
      lapTimeString = "";
      laps = [];
      currentLap = Lap();
      path = [];
      startPosition = null;

      currentSpeed = "";
      avarageSpeed = "";
      currentSpeed2 = "";
      avarageSpeed2 = "";
      distance = 0.0;
      positionStream = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              totalTimeString,
              style: Theme.of(context).textTheme.display3,
            ),
            Text(
              lapTimeString,
              style: Theme.of(context).textTheme.display1,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (!watch.isRunning)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      color: Colors.green,
                      onPressed: startwatch,
                      child: Text(isPaused ? "Resume" : "Start"),
                    ),
                  ),
                if (watch.isRunning)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      color: Colors.red,
                      onPressed: stopWatch,
                      child: Text("Stop"),
                    ),
                  ),
                if (isPaused)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RaisedButton(
                      onPressed: resetWatch,
                      child: Text("Reset"),
                    ),
                  ),
              ],
            ),
            Text("points: " + path.length.toString()),
            Text("distance: " + distance.toStringAsFixed(2) + "m"),
            Text("speed1 current: " +
                currentSpeed +
                " avarage: " +
                avarageSpeed),
            Text("speed2 current: " +
                currentSpeed2 +
                " avarage: " +
                avarageSpeed2),
            SizedBox(
              height: 50,
            ),
            Text("Location options: dist>" +
                locationOptions.distanceFilter.toString() +
                " time>" +
                locationOptions.timeInterval.toString()),
            SizedBox(
              height: 15,
            ),
            TextField(
              decoration: InputDecoration(labelText: "distanceFilter"),
              controller: distanceFilterController,
              keyboardType: TextInputType.number,
              onChanged: (String value) {
                setState(() {
                  locationOptions = LocationOptions(
                    accuracy: LocationAccuracy.best,
                    distanceFilter: int.parse(distanceFilterController.text),
                    timeInterval: locationOptions.timeInterval,
                  );
                });
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: "timeInterval"),
              controller: timeIntervalController,
              keyboardType: TextInputType.number,
              onChanged: (String value) {
                setState(() {
                  locationOptions = LocationOptions(
                    accuracy: LocationAccuracy.best,
                    distanceFilter: locationOptions.distanceFilter,
                    timeInterval: int.parse(timeIntervalController.text),
                  );
                });
              },
            ),
            RaisedButton(
              color: Colors.green,
              onPressed: () {
                setState(() {
                  locationOptions = LocationOptions(
                    accuracy: locationOptions.accuracy == LocationAccuracy.best
                        ? LocationAccuracy.high
                        : LocationAccuracy.best,
                    distanceFilter: locationOptions.distanceFilter,
                    timeInterval: locationOptions.timeInterval,
                  );
                });
              },
              child: Text(locationOptions.accuracy == LocationAccuracy.best
                  ? "best"
                  : "high"),
            ),
            Container(
              height: 100,
              child: ListView(
                children: laps
                    .map((lap) => Text(
                        "${formatTime(lap.time)} ${lap.distance.toStringAsFixed(2)}m"))
                    .toList(),
              ),
            ),
          ],
        ),
        // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
