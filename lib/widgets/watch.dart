import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lap_tracking/keys.dart';
import 'package:lap_tracking/utils/time_util.dart';

class Watch extends StatelessWidget {
  final Duration total;
  final Duration currentLap;
  final bool isMapView;
  Watch({Key key, @required this.total, this.currentLap, this.isMapView})
      : super(key: key);

  //mindre fontsize på hundradelarna? som i andrid stock

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.only(
          top: currentLap != null || isMapView ? 0.0 : (size.height / 2) - 120),
      child: Column(
        children: [
          Text(
            TimeUtil.formatTime(total),
            key: Key(Keys.WATCH_TOTAL_TIME),
            style: Theme.of(context).textTheme.headline2,
          ),
          Visibility(
            visible: currentLap != null,
            child: Text(
              TimeUtil.formatTime(currentLap ?? Duration()),
              key: Key(Keys.WATCH_CURRENT_LAP_TIME),
              style: Theme.of(context).textTheme.headline5,
            ),
          ),
        ],
      ),
    );
  }
}
