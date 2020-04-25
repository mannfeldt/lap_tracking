import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/models/watch_state.dart';
import 'package:lap_tracking/models/waypoint.dart';
import 'package:lap_tracking/widgets/lap_list.dart';
import 'package:lap_tracking/widgets/watch.dart';
import 'package:lap_tracking/widgets/watch_toolbar.dart';

void main() => runApp(MyApp());

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

//! nu är det dags att snygga till koden. dela upp i widgets. implementera provider?
//!widgets:
//- mainWatch (total time, current lap time, speed, distance) egen för speed distance?
//- lapList
// - lapListItem (visa avg speed på varvet)
//- watchToolbar/controllbar
//- plotMap(annat namn?) kan visas / döljas i stopwatch vyn.
//- när man avslutat och klickar på spara så kommer man till en ny sida där man anger mer uppgifter. väljer en circut kanske osv. ser mapen
//man kanske kan redigera, ta bort waypoints som är maerkade som osäkre/konstiga och räkna om allt.

//nästa steg dela upp i flera screens med bootom navbar och login sida. Home - Stopwatch - settings/stats

class _HomeState extends State<Home> {
  //lite problem att ha två klockor? bättre med en och sen får vi dela upp så att varvtiden som visas på currentlap varv 2 och frammåt är:
  //watch.elapsed - laps.fold(lap.time) ja det blir hundra delar som blir fel.
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
  double distance = 0.0;
  LocationOptions locationOptions =
      LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 2);

  TextEditingController distanceFilterController = TextEditingController();
  TextEditingController timeIntervalController = TextEditingController();

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

    setState(() {
      path.add(currentPosition);
      currentLapPath.add(currentPosition);
      currentSpeed = "${currentPosition.speed.toStringAsFixed(2)}m/s}";
      avarageSpeed = "${avgSpeed.toStringAsFixed(2)}m/s}";
      distance += newDistance;
    });

    double distanceFromStart =
        await startPosition.distanceFrom(currentPosition);
    print("distance from start:" + distanceFromStart.toString());
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
        ),
      );
    });
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
    return distanceInMeters < 5.0;
  }

  double getSpeedFromDistance(double meters, Duration travelTime) {
    return (meters / (travelTime.inMilliseconds / 1000)).roundToDouble();
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
    setState(() {
      watchState = WatchState.unstarted;
      totalTime = Duration();
      currentLapTime = null;
      laps = [];
      path = [];
      startPosition = null;
      currentSpeed = "";
      avarageSpeed = "";
      distance = 0.0;
      positionStream = null;
    });
  }

  void finishEvent() {
    stopWatch();
    setState(() {
      watchState = WatchState.finished;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Watch(
              total: totalTime,
              currentLap: currentLapTime,
            ),
            WatchToolbar(
              onReset: resetWatch,
              onStart: startWatch,
              onStop: stopWatch,
              onFinish: finishEvent,
              onLap: startNewLap,
              state: watchState,
            ),
            Text("points: " + path.length.toString()),
            Text("distance: " + distance.toStringAsFixed(2) + "m"),
            Text("speed1 current: " +
                currentSpeed +
                " avarage: " +
                avarageSpeed),
            SizedBox(
              height: 50,
            ),
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
            LapList(
              laps: laps,
            ),
          ],
        ),
      ),
    );
  }
}
