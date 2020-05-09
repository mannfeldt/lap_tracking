import 'dart:async';
import 'dart:ui';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:device_preview/device_preview.dart' as device_preview;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/models/watch_state.dart';
import 'package:lap_tracking/models/waypoint.dart';
import 'package:lap_tracking/widgets/lap_list.dart';
import 'package:lap_tracking/widgets/watch.dart';
import 'package:lap_tracking/widgets/watch_toolbar.dart';
import 'package:flutter/services.dart'
    show DeviceOrientation, SystemChrome, rootBundle;
import 'package:light/light.dart';

enum LightMode { DAYLIGHT, NIGHT, UNDEFINED }

void main() => runApp(device_preview.DevicePreview(
      enabled: false,
      builder: (BuildContext context) => MyApp(),
    ));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
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
  bool voiceOverMuted = false;
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
  double distanceFromStartRadius = 8.0;
  LocationOptions locationOptions =
      LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 1);

  TextEditingController distanceFilterController = TextEditingController();
  TextEditingController timeIntervalController = TextEditingController();
  TextEditingController distanceFromStartController = TextEditingController();

  Light _light;
  StreamSubscription lightStream;
  LightMode lightMode = LightMode.UNDEFINED;

  bool isMapView = false;
  String mapDarkStyle;

  Timer startCountdownTimer;

  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 17,
  );

  Timer timer;
  bool showSettings = false;

  @override
  void initState() {
    rootBundle.loadString('assets/map_style.txt').then((string) {
      mapDarkStyle = string;
    });
    watch = Stopwatch();
    super.initState();
  }

  void onLightData(int luxValue) async {
    if (luxValue > 2000 &&
        (lightMode == LightMode.NIGHT || lightMode == LightMode.UNDEFINED)) {
      GoogleMapController ctrl = await _controller.future;
      if (lightMode == LightMode.DAYLIGHT) {
        ctrl.setMapStyle(null);
      } else {
        ctrl.setMapStyle(mapDarkStyle);
      }
      setState(() {
        lightMode = LightMode.DAYLIGHT;
      });
    }
    if (luxValue <= 2000 &&
        (lightMode == LightMode.DAYLIGHT || lightMode == LightMode.UNDEFINED)) {
      GoogleMapController ctrl = await _controller.future;
      if (lightMode == LightMode.DAYLIGHT) {
        ctrl.setMapStyle(null);
      } else {
        ctrl.setMapStyle(mapDarkStyle);
      }
      setState(() {
        lightMode = LightMode.NIGHT;
      });
    }
  }

  void startLightStream() {
    _light = new Light();
    try {
      lightStream = _light.lightSensorStream.listen(onLightData);
    } on LightException catch (exception) {
      print(exception);
    }
  }

  void onNewPosition(Position position) async {
    Waypoint currentPosition = Waypoint.fromPosition(position);
    Waypoint lastPosition = path[path.length - 1];

    double avgSpeed =
        path.fold(0, (sum, item) => sum + item.speed) / path.length;

    double newDistance = await currentPosition.distanceFrom(lastPosition);
    double dfs = await startPosition.distanceFrom(currentPosition);

    LatLng latLng = LatLng(currentPosition.latitude, currentPosition.longitude);

    setState(() {
      path.add(currentPosition);
      currentLapPath.add(currentPosition);
      currentSpeed = "${currentPosition.speed.toStringAsFixed(2)}m/s}";
      avarageSpeed = "${avgSpeed.toStringAsFixed(2)}m/s}";
      distance += newDistance;
      distanceFromStart = dfs;
    });
    final GoogleMapController controller = await _controller.future;
    double zoom = await controller.getZoomLevel();
    final CameraPosition pos = CameraPosition(target: latLng, zoom: zoom);

    controller.animateCamera(CameraUpdate.newCameraPosition(pos));
    print("distance from start:" + dfs.toString());
    bool lapCompleted = await isBackAtStartPos(currentPosition);

    if (lapCompleted) {
      print("NEW LAP!!!!!");
      startNewLap();
    }
  }

  void startNewLap() async {
    Lap lap = Lap(
      index: laps.length,
      distance: distance - (laps.fold(0, (sum, lap) => sum + lap.distance)),
      path: currentLapPath,
      lapTime: watch.elapsed -
          (laps.fold(Duration(), (sum, lap) => sum + lap.lapTime)),
      totalTime: watch.elapsed,
      speed: currentLapPath.fold(0, (sum, point) => sum + point.speed) /
          currentLapPath.length,
    );
    setState(() {
      laps.add(lap);
      currentLapPath = [];
    });
    _lapListKey.currentState.insertItem(0,
        duration: Duration(milliseconds: laps.length > 1 ? 200 : 600));

    if (!voiceOverMuted) {
      FlutterTts flutterTts = FlutterTts();

      await flutterTts.speak(lap.voiceOver);
    }
  }

  void tick() {
    if (watch.isRunning) {
      timer = Timer(timerTick, tick);
      setState(() {
        totalTime = watch.elapsed;
        if (laps.isNotEmpty) {
          currentLapTime = watch.elapsed -
              (laps.fold(Duration(), (sum, lap) => sum + lap.lapTime));
        }
      });
    }
  }

  @override
  dispose() {
    if (timer != null) {
      timer.cancel();
    }
    if (startCountdownTimer != null) {
      startCountdownTimer.cancel();
    }
    super.dispose();
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
      _initialCameraPosition = CameraPosition(
          target: LatLng(startPosition.latitude, startPosition.longitude),
          zoom: 14.0);
    });
    if (positionStream != null) {
      positionStream.resume();
    }
  }

  Future<bool> onStart() async {
    GeolocationStatus status =
        await Geolocator().checkGeolocationPermissionStatus();
    if (status.value == 0) {
      await Geolocator().getCurrentPosition();
      return false;
    }

    if (watchState == WatchState.unstarted) {
      setState(() {});
      startCountdownTimer = Timer(Duration(seconds: 6), startWatch);

      if (!voiceOverMuted) {
        voiceCountdown();
      }
    } else {
      startWatch();
    }
    return true;
  }

  void voiceCountdown() async {
    FlutterTts flutterTts = FlutterTts();

    await flutterTts.speak("5");
    await Future.delayed(Duration(milliseconds: 1020));
    await flutterTts.speak("4");
    await Future.delayed(Duration(milliseconds: 1020));
    await flutterTts.speak("3");
    await Future.delayed(Duration(milliseconds: 1020));
    await flutterTts.speak("2");
    await Future.delayed(Duration(milliseconds: 1020));
    await flutterTts.speak("1");
    await Future.delayed(Duration(milliseconds: 1020));
    await flutterTts.speak("GO");
  }

  void startWatch() async {
    if (watchState == WatchState.unstarted) {
      if (positionStream == null) {
        var geolocator = Geolocator();
        positionStream =
            geolocator.getPositionStream(locationOptions).listen(onNewPosition);
        positionStream.pause();
        setStartPosition();
      }
      if (lightStream == null) {
        startLightStream();
      }
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
    lightStream.cancel();

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
      lightStream = null;
      isMapView = false;
    });
  }

  void finishEvent() {
    setState(() {
      watchState = WatchState.finished;
    });
  }

  void toggleVoice() {
    setState(() {
      voiceOverMuted = !voiceOverMuted;
    });
  }

  Future<void> toggleMapView() async {
    setState(() {
      isMapView = !isMapView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Visibility(
                visible: isMapView,
                maintainAnimation: true,
                maintainSize: true,
                maintainState: true,
                child: GoogleMap(
                  mapToolbarEnabled: false,
                  //bryt ut google map till egen widget. skulle vara snyggare om mapen är bakom allt kanske? eller iaf om watch är ovanpå mapen?
                  //går väl lätt att fixa med att lägga en stack runt hela appen där mapen kan vara i bakgrunden. och på listview så döljer vi den bara med visible
                  //kan ha map controller osv i den nya widgeten men vi behöver callbacks osv? implementera en changeNotifier/provider nu.
                  polylines: [
                    ...laps.map((l) => l.toPolyline).toList(),
                    Polyline(
                      points: currentLapPath
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      polylineId: PolylineId("current"),
                      endCap: Cap.roundCap,
                      jointType: JointType.mitered,
                      zIndex: laps.length + 1,
                      width: 4,
                      color: Colors.blue,
                    )
                  ].toSet(),
                  circles: [
                    Circle(
                      zIndex: 1000,
                      circleId: CircleId("startPos"),
                      center: _initialCameraPosition.target,
                      radius: distanceFromStartRadius,
                      strokeColor: Colors.blue.shade600,
                      fillColor: Colors.blue.shade300,
                      strokeWidth: 1,
                    )
                  ].toSet(),
                  zoomControlsEnabled: false,
                  buildingsEnabled: false,
                  zoomGesturesEnabled: true,
                  mapType: MapType.normal,
                  initialCameraPosition: _initialCameraPosition,
                  onMapCreated: (GoogleMapController controller) async {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                    }
                  },
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      highlightColor: Colors.white30,
                      onPressed: toggleVoice,
                      icon: Icon(
                        voiceOverMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                    ),
                    if (watchState != WatchState.unstarted)
                      IconButton(
                        highlightColor: Colors.white30,
                        onPressed: toggleMapView,
                        icon: Icon(
                          isMapView ? Icons.list : Icons.map,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                GestureDetector(
                  onDoubleTap: () => setState(() {
                    showSettings = !showSettings;
                  }),
                  child: Watch(
                    total: totalTime,
                    currentLap: currentLapTime,
                    isMapView: isMapView,
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: Visibility(
                          visible: !isMapView,
                          maintainAnimation: true,
                          maintainSize: true,
                          maintainState: true,
                          child: LapList(
                            lapListKey: _lapListKey,
                            laps: laps,
                          ),
                        ),
                      ),
                      Positioned(
                        child: Container(
                          padding: EdgeInsets.only(bottom: 20),
                          alignment: Alignment.bottomCenter,
                          child: WatchToolbar(
                            onReset: resetWatch,
                            onStart: onStart,
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
                              timeInterval:
                                  int.parse(timeIntervalController.text),
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
                              accuracy: locationOptions.accuracy ==
                                      LocationAccuracy.best
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
            if (startCountdownTimer != null && startCountdownTimer.isActive)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    color: Colors.blue.withOpacity(0.2),
                    child: IgnorePointer(
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleAnimatedTextKit(
                              text: ["5", "4", "3", "2", "1", "GO!"],
                              isRepeatingAnimation: false,
                              pause: Duration(milliseconds: 220),
                              textStyle: TextStyle(
                                fontSize: 200.0,
                                letterSpacing: 2,
                              ),
                              duration: Duration(milliseconds: 800),
                              textAlign: TextAlign.center,
                              alignment: AlignmentDirectional.center),
                        ],
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
