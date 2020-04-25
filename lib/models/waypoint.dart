import 'package:geolocator/geolocator.dart';

class Waypoint {
  DateTime timeStamp;
  double longitude;
  double latitude;
  double altitude;
  double speed;
  Waypoint(
      {this.timeStamp,
      this.latitude,
      this.longitude,
      this.altitude,
      this.speed}) {
    this.timeStamp = timeStamp;
    this.longitude = longitude;
    this.latitude = latitude;
    this.altitude = altitude;
    this.speed = speed;
  }
  Waypoint.fromPosition(Position position) {
    this.timeStamp = position.timestamp;
    this.longitude = position.longitude;
    this.latitude = position.latitude;
    this.altitude = position.altitude;
    this.speed = position.speed;
  }
}
