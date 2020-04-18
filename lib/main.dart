import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

// class PathPoint {
//   double latitude;
//   double longitude;
//   DateTime timeStamp;
//   double speed;
// }

class _MyHomePageState extends State<MyHomePage> {
  Stopwatch watch;
  String totalTimeString = "00:00:00";
  final timerTick = const Duration(milliseconds: 40);
  bool isPaused = false;
  Position startPosition;
  List<Position> path = [];
  StreamSubscription<Position> positionStream;

  @override
  void initState() {
    var geolocator = Geolocator();
    var locationOptions =
        LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 1);
    positionStream =
        geolocator.getPositionStream(locationOptions).listen(onNewPosition);
    positionStream.pause();
    watch = Stopwatch();

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
    //Position lastPosition = path[path.length - 1];

    // Duration travelTime = position.timestamp.difference(lastPosition.timestamp);

    // double distance = await getDistance(lastPosition, position);
    // double speed =
    //     await getSpeedFromPositions(lastPosition, position, travelTime);
    // double speed2 = getSpeedFromDistance(distance, travelTime);
    // double speed3 = position.speed;
    // print("-------------------------------------------------------------");

    // print("distance: " + distance.toString());
    // print("speed: " + speed.toString());
    // print("speed2: " + speed2.toString());
    // print("speed3: " + speed3.toString());
    //testa vilke av dessa som är mest pålitilg. ta minst 10st och gör ett avarage..
//! någon bug där den är paused själva geolocation lyssnaren. kör jag inte resume rätt?
    setState(() {
      path.add(position);
    });

    double distanceFromStart = await getDistance(position, startPosition);
    print("distance from start:" + distanceFromStart.toString());
    bool lapCompleted = await isBackAtStartPos(position);
    if (lapCompleted) {
      stopWatch();
    }
  }

  void tick() {
    if (watch.isRunning) {
      Timer(timerTick, tick);
      setState(() {
        totalTimeString = formatTime(watch.elapsed);
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
      positionStream.resume();
    });
  }

  void startwatch() async {
    if (!isPaused) {
      setStartPosition();
    } else {
      setState(() {
        isPaused = false;
        positionStream.resume();
      });
    }
    watch.start();
    tick();
  }

  void stopWatch() {
    watch.stop();
    setState(() {
      isPaused = true;
      positionStream.pause();
    });
  }

  void resetWatch() {
    watch.reset();
    setState(() {
      isPaused = false;
      totalTimeString = "00:00:00";
      positionStream.pause();
      path = [];
      startPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              totalTimeString,
              style: Theme.of(context).textTheme.display1,
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(path.length.toString()),
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
                  )
              ],
            )
          ],
        ),
        // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
