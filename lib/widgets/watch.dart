import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lap_tracking/keys.dart';
import 'package:lap_tracking/utils/time_util.dart';

class Watch extends StatelessWidget {
  final Duration total;
  final Duration currentLap;
  final bool isMapView;
  Watch(
      {Key key, @required this.total, this.currentLap, this.isMapView = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    String formatedTotal = TimeUtil.formatWatchTime(total);
    String majorPart = formatedTotal.split(" ")[0];
    String minorPart = " " + formatedTotal.split(" ")[1];

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.only(
          top: currentLap != null || isMapView ? 0.0 : (size.height / 2) - 120),
      child: Column(
        children: [
          RichText(
            key: Key(Keys.WATCH_TOTAL_TIME),
            text: TextSpan(
              text: majorPart,
              style: TextStyle(
                fontSize: 48,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: minorPart,
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: currentLap != null,
            child: Text(
              TimeUtil.formatLapItemTime(currentLap ?? Duration()),
              textAlign: TextAlign.center,
              key: Key(Keys.WATCH_CURRENT_LAP_TIME),
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 4,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
