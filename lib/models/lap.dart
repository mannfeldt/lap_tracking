import 'package:geolocator/geolocator.dart';

class Lap {
  List<Position> path;
  Duration time;
  double distance;

  Lap(
      {this.path = const [],
      this.time = const Duration(),
      this.distance = 0.0}) {
    this.path = path;
    this.time = time;
    this.distance = distance;
  }
}
