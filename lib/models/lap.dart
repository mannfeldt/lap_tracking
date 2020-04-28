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

  String get voiceOver {
    String hours = lapTime.inHours > 0 ? "${lapTime.inHours} hours" : "";
    String minutes = (lapTime.inMinutes % 60) > 0
        ? "${(lapTime.inMinutes % 60)} minutes"
        : "";
    String seconds = (lapTime.inSeconds % 60) > 0
        ? "${(lapTime.inSeconds % 60)} seconds"
        : "";
    if (index == 0) {
      return "$distanceVisual completed in $hours $minutes $seconds. Average speed $speedVisual";
    }
    return "Lap ${index + 1} completed in $hours $minutes $seconds. Average speed $speedVisual";
  }
}
