import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/models/watch_state.dart';
import 'package:lap_tracking/models/waypoint.dart';
import 'package:lap_tracking/widgets/lap_list.dart';
import 'package:lap_tracking/widgets/watch.dart';
import 'package:lap_tracking/widgets/watch_toolbar.dart';

void main() => runApp(DevicePreview(
      enabled: false,
      builder: (BuildContext context) => MyApp(),
    ));

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromRGBO(21, 28, 28, 1),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
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

class _HomeState extends State<Home> {
  final GlobalKey<AnimatedListState> _lapListKey =
      GlobalKey<AnimatedListState>();

  Stopwatch watch;

  Duration totalTime = Duration();
  Duration currentLapTime;

  WatchState watchState = WatchState.unstarted;

  final timerTick = const Duration(milliseconds: 40);
  Waypoint startPosition;
  List<Waypoint> path = [];
  List<Waypoint> currentLapPath = [];
  List<Lap> laps = [];
  StreamSubscription<Position> positionStream;
  String currentSpeed = "";
  String avarageSpeed = "";
  double distanceFromStart = 0.0;
  double distance = 0.0;
  double distanceFromStartRadius = 5.0;
  LocationOptions locationOptions =
      LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 2);

  TextEditingController distanceFilterController = TextEditingController();
  TextEditingController timeIntervalController = TextEditingController();
  TextEditingController distanceFromStartController = TextEditingController();

  bool showSettings = false;

  @override
  void initState() {
    watch = Stopwatch();
    super.initState();
  }

  void onNewPosition(Position position) async {
    Waypoint currentPosition = Waypoint.fromPosition(position);
    Waypoint lastPosition = path[path.length - 1];

    double avgSpeed =
        path.fold(0, (sum, item) => sum + item.speed) / path.length;

    double newDistance = await currentPosition.distanceFrom(lastPosition);
    double dfs = await startPosition.distanceFrom(currentPosition);
    setState(() {
      path.add(currentPosition);
      currentLapPath.add(currentPosition);
      currentSpeed = "${currentPosition.speed.toStringAsFixed(2)}m/s}";
      avarageSpeed = "${avgSpeed.toStringAsFixed(2)}m/s}";
      distance += newDistance;
      distanceFromStart = dfs;
    });

    print("distance from start:" + dfs.toString());
    bool lapCompleted = await isBackAtStartPos(currentPosition);

    if (lapCompleted) {
      print("NEW LAP!!!!!");
      startNewLap();
    }
  }

  void startNewLap() {
    setState(() {
      laps.add(
        Lap(
          index: laps.length,
          distance: distance - (laps.fold(0, (sum, lap) => sum + lap.distance)),
          path: currentLapPath,
          lapTime: watch.elapsed -
              (laps.fold(Duration(), (sum, lap) => sum + lap.lapTime)),
          totalTime: watch.elapsed,
          speed: currentLapPath.fold(0, (sum, point) => sum + point.speed) /
              currentLapPath.length,
        ),
      );
      currentLapPath = [];
    });
    _lapListKey.currentState.insertItem(0,
        duration: Duration(milliseconds: laps.length > 1 ? 200 : 600));
  }

  void tick() {
    if (watch.isRunning) {
      Timer(timerTick, tick);
      setState(() {
        totalTime = watch.elapsed;
        if (laps.isNotEmpty) {
          currentLapTime = watch.elapsed -
              (laps.fold(Duration(), (sum, lap) => sum + lap.lapTime));
        }
      });
    }
  }

  Future<bool> isBackAtStartPos(Waypoint waypoint) async {
    bool atStartPos = await atSameLocation(waypoint, startPosition);
    bool hasMovedFromStartPos = currentLapPath.length > 10;
    return hasMovedFromStartPos && atStartPos;
  }

  Future<bool> atSameLocation(Waypoint a, Waypoint b) async {
    double distanceInMeters = await Geolocator()
        .distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
    return distanceInMeters < distanceFromStartRadius;
  }

  void setStartPosition() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    Waypoint waypoint = Waypoint.fromPosition(position);
    setState(() {
      startPosition = waypoint;
      path.add(waypoint);
    });
    positionStream.resume();
  }

  void startWatch() async {
    if (watchState == WatchState.unstarted) {
      if (positionStream == null) {
        var geolocator = Geolocator();
        positionStream =
            geolocator.getPositionStream(locationOptions).listen(onNewPosition);
      }
      setStartPosition();
    }

    watch.start();
    tick();
    setState(() {
      watchState = WatchState.running;
    });
  }

  void stopWatch() {
    watch.stop();
    setState(() {
      watchState = WatchState.stopped;
    });
    positionStream.pause();
  }

  void resetWatch() {
    if (watchState == WatchState.running) {
      stopWatch();
    }
    watch.reset();

    laps.forEach(
      (lap) => _lapListKey.currentState.removeItem(
        0,
        (context, animation) => Container(),
      ),
    );
    setState(() {
      watchState = WatchState.unstarted;
      totalTime = Duration();
      currentLapTime = null;
      laps = [];
      path = [];
      currentLapPath = [];
      startPosition = null;
      currentSpeed = "";
      avarageSpeed = "";
      distance = 0.0;
      positionStream = null;
    });
  }

  void finishEvent() {
    setState(() {
      watchState = WatchState.finished;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            GestureDetector(
              onDoubleTap: () => setState(() {
                showSettings = !showSettings;
              }),
              child: Watch(
                total: totalTime,
                currentLap: currentLapTime,
              ),
            ),
            Expanded(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: LapList(
                      lapListKey: _lapListKey,
                      laps: laps,
                    ),
                  ),
                  Positioned(
                    child: Container(
                      padding: EdgeInsets.only(bottom: 15),
                      alignment: Alignment.bottomCenter,
                      child: WatchToolbar(
                        onReset: resetWatch,
                        onStart: startWatch,
                        onStop: stopWatch,
                        onFinish: finishEvent,
                        onLap: startNewLap,
                        state: watchState,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showSettings)
              Column(
                children: <Widget>[
                  Text("points: " + path.length.toString()),
                  Text("distance: " + distance.toStringAsFixed(2) + "m"),
                  Text("fromStart: " +
                      distanceFromStart.toStringAsFixed(2) +
                      "m"),
                  Text("speed1 current: " +
                      currentSpeed +
                      " avarage: " +
                      avarageSpeed),
                  TextField(
                    decoration: InputDecoration(
                        labelText: "distanceFilter",
                        labelStyle: TextStyle(color: Colors.white)),
                    controller: distanceFilterController,
                    keyboardType: TextInputType.number,
                    onChanged: (String value) {
                      setState(() {
                        locationOptions = LocationOptions(
                          accuracy: LocationAccuracy.best,
                          distanceFilter:
                              int.parse(distanceFilterController.text),
                          timeInterval: locationOptions.timeInterval,
                        );
                      });
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                        labelText: "timeInterval",
                        labelStyle: TextStyle(color: Colors.white)),
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
                  TextField(
                    decoration: InputDecoration(
                        labelText: "distance from start",
                        labelStyle: TextStyle(color: Colors.white)),
                    controller: distanceFromStartController,
                    keyboardType: TextInputType.number,
                    onChanged: (String value) {
                      setState(() {
                        distanceFromStartRadius = double.tryParse(value);
                      });
                    },
                  ),
                  RaisedButton(
                    color: Colors.green,
                    onPressed: () {
                      setState(() {
                        locationOptions = LocationOptions(
                          accuracy:
                              locationOptions.accuracy == LocationAccuracy.best
                                  ? LocationAccuracy.high
                                  : LocationAccuracy.best,
                          distanceFilter: locationOptions.distanceFilter,
                          timeInterval: locationOptions.timeInterval,
                        );
                      });
                    },
                    child: Text(
                        locationOptions.accuracy == LocationAccuracy.best
                            ? "best"
                            : "high"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
