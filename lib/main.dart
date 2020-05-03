import 'dart:async';

import 'package:device_preview/device_preview.dart';
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
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(DevicePreview(
      enabled: false,
      builder: (BuildContext context) => MyApp(),
    ));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
  double distanceFromStartRadius = 6.0;
  LocationOptions locationOptions =
      LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 2);

  TextEditingController distanceFilterController = TextEditingController();
  TextEditingController timeIntervalController = TextEditingController();
  TextEditingController distanceFromStartController = TextEditingController();

  bool isMapView = false;
  String mapStyle = "";

  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static final CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  Timer timer;
  bool showSettings = false;

  @override
  void initState() {
    rootBundle.loadString('assets/map_style.txt').then((string) {
      mapStyle = string;
    });
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

    LatLng latLng = LatLng(currentPosition.latitude, currentPosition.longitude);

    setState(() {
      path.add(currentPosition);
      currentLapPath.add(currentPosition);
      currentSpeed = "${currentPosition.speed.toStringAsFixed(2)}m/s}";
      avarageSpeed = "${avgSpeed.toStringAsFixed(2)}m/s}";
      distance += newDistance;
      distanceFromStart = dfs;
    });

    final CameraPosition pos = CameraPosition(target: latLng, zoom: 17.0);
    final GoogleMapController controller = await _controller.future;

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
    positionStream.resume();
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

  void toggleMapView() {
    setState(() {
      isMapView = !isMapView;
    });
  }

  @override
  Widget build(BuildContext context) {
    //! skriv in ny feature. man ska kunna se simulerade polylines från föregående eller snabbaste varvet. use case är att man ska kunna kolla på dem
    //och jämföra sitt nuvarande arv med det. blir som ghost trail mode typ. vid varje x meter kan man säga hur tidsskillnaden är också?
    //jag börde ha tillräcklig info för att få till det?
    //hitta vilket varj jag vill simulera. kolla på det varvets waypoints som har timestamp.
    //ALT 1.
    //gör om timestamp till Duration from newlapStart. skapa en timer för varje waypoint där den efter den satta duration så läggs
    //den wayponinten till som en point i ghostPolyline
    //ALT 2.
    //skapa en gemensam Timer som efter duration lägger till näsat waypoint. sen kallar den på en ny timer med duration till nästa waypoint osv..
    //tills alla waypoints är slut. då disposar vi timern eller avslutar den på något vis.

    //lägg till detta bara. prioritera firebase integration med att spara routes och profil osv istället.
    //muteknappen blir en inställningsknapp istället kanske. en sån där navbar som kommer ut från vänster. där kan man muta. navigera till sin profil osv.
    //eller så har jag en klassisk bottom navbar "inställningar, hem, profil, stopwatch"
    //steg 1 med routes blir ju bara att man får välja själv vilken route man kört. Kan senare bygga in smartness som ger förlsag och kan ta in andras routes också.
    //men i början får man när man är klar spara som ny route eller välja en befintlig. Senare får vi också validera att den man väljer är rimlig sett till distance osv.
    //man kan se sina highscores på de olika routesen man skapat. man kan se statistik över tid hur man förbättrats etc.
    //man kan starta en ny aktivitet utifrån en route direkt. då får man väglednning(snabbaste varvet ligger där som en polyline redan i någon färg. bra finess till ghost trail också.)

    return Scaffold(
      body: SafeArea(
        child: Column(
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
                    child: LapList(
                      lapListKey: _lapListKey,
                      laps: laps,
                    ),
                  ),
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
                              strokeColor: Colors.yellow.withOpacity(0.5),
                              fillColor: Colors.yellow.withOpacity(0.5),
                              strokeWidth: 1)
                        ].toSet(),
                        zoomControlsEnabled: false,
                        buildingsEnabled: false,
                        zoomGesturesEnabled: true,
                        mapType: MapType.normal,
                        initialCameraPosition: _initialCameraPosition,
                        onMapCreated: (GoogleMapController controller) {
                          if (!_controller.isCompleted) {
                            controller.setMapStyle(mapStyle);
                            _controller.complete(controller);
                          }
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    child: Container(
                      padding: EdgeInsets.only(bottom: 20),
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
