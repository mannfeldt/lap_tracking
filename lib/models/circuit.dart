import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/models/waypoint.dart';

class Circuit {
  String name;
  List<Lap> topLaps;
  List<Waypoint> path;
  double distance;

  Circuit({this.name, this.topLaps, this.path, this.distance}) {
    this.name = name;
    this.topLaps = topLaps;
    this.path = path;
    this.distance = distance;
  }
}
