import 'package:lap_tracking/models/waypoint.dart';

class Lap {
  int index;
  List<Waypoint> path;
  Duration lapTime;
  double distance;
  Duration totalTime;

  Lap(
      {this.path = const [],
      this.lapTime = const Duration(),
      this.distance = 0.0,
      this.totalTime,
      this.index}) {
    this.path = path;
    this.lapTime = lapTime;
    this.distance = distance;
    this.totalTime = totalTime;
    this.index = index;
  }
}
