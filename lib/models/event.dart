import 'package:lap_tracking/models/circuit.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/models/user.dart';

enum EventType { bike, run, walk }

class Event {
  List<Lap> laps;
  Circuit circuit;
  EventType type;
  User user;
  DateTime created;

  Event(
      {this.laps = const [],
      this.circuit,
      this.type,
      this.user,
      this.created}) {
    this.laps = laps;
    this.circuit = circuit;
    this.type = type;
    this.user = user;
    this.created = created;
  }

  double get distance => laps.fold(0, (sum, lap) => sum + lap.distance);
}
