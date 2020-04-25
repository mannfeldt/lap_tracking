import 'package:geolocator/geolocator.dart';

class Waypoint {
  DateTime timestamp;
  double longitude;
  double latitude;
  double altitude;
  double speed;
  Waypoint(
      {this.timestamp,
      this.latitude,
      this.longitude,
      this.altitude,
      this.speed}) {
    this.timestamp = timestamp;
    this.longitude = longitude;
    this.latitude = latitude;
    this.altitude = altitude;
    this.speed = speed;
  }
  Waypoint.fromPosition(Position position) {
    this.timestamp = position.timestamp;
    this.longitude = position.longitude;
    this.latitude = position.latitude;
    this.altitude = position.altitude;
    this.speed = position.speed;
  }

  Future<double> distanceFrom(Waypoint other) async {
    return await Geolocator().distanceBetween(
      this.latitude,
      this.longitude,
      other.latitude,
      other.longitude,
    );
  }
}
