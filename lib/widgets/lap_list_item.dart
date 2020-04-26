import 'package:flutter/material.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/utils/time_util.dart';

class LapListItem extends StatelessWidget {
  final Lap lap;

  LapListItem(this.lap, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        "#${(lap.index + 1).toString().padRight(2, "  ")}  ${TimeUtil.formatTime(lap.lapTime)}  ${TimeUtil.formatTime(lap.totalTime)}",
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            lap.distanceVisual,
          ),
          Text(
            lap.speedVisual,
          ),
        ],
      ),
    );
  }
}
