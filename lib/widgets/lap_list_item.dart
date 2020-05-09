import 'package:flutter/material.dart';
import 'package:lap_tracking/keys.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/utils/time_util.dart';

class LapListItem extends StatelessWidget {
  final Lap lap;

  LapListItem(this.lap, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key(Keys.lapListItem(lap.index)),
      title: Text(
        "#${(lap.index + 1).toString().padRight(2, "  ")}  ${TimeUtil.formatLapItemTime(lap.lapTime)}  ${TimeUtil.formatLapItemTime(lap.totalTime)}",
        key: Key(Keys.LAP_LIST_ITEM_TITLE),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            lap.distanceVisual,
            key: Key(Keys.LAP_LIST_ITEM_DISTANCE),
          ),
          Text(
            lap.speedVisual,
            key: Key(Keys.LAP_LIST_ITEM_SPEED),
          ),
        ],
      ),
    );
  }
}
