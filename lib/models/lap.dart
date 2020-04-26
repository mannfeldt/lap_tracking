import 'package:lap_tracking/models/waypoint.dart';

class Lap {
  int index;
  List<Waypoint> path;
  Duration lapTime;
  double distance;
  double speed;
  Duration totalTime;

  Lap(
      {this.path = const [],
      this.lapTime = const Duration(),
      this.distance = 0.0,
      this.totalTime,
      this.index,
      this.speed}) {
    this.path = path;
    this.lapTime = lapTime;
    this.distance = distance;
    this.totalTime = totalTime;
    this.index = index;
    this.speed = speed;
  }
  String get speedVisual => "${(speed * 3.6).toStringAsFixed(2)} km/h";
  String get distanceVisual {
    String distanceString = distance.toStringAsFixed(0);
    if (distanceString.length < 4) {
      return "$distanceString m";
    }
    String m = distanceString.substring(distanceString.length - 3);
    String km = distanceString.substring(0, distanceString.length - 3);
    return "$km $m m";
  }
}
