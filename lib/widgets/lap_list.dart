import 'package:flutter/material.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/utils/time_util.dart';

class LapList extends StatelessWidget {
  final List<Lap> laps;
  LapList({Key key, this.laps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 60, vertical: 30),
        //fixa till bättre responsiovitet, lägg till avg speed på en lap? gör det till lap_list_item och aligna så de blir rakt även när datan är olika lång i raderna.
        children: laps
            .map(
              (lap) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "#${lap.index + 1}",
                    textAlign: TextAlign.start,
                  ),
                  Text(
                    TimeUtil.formatTime(lap.lapTime),
                    textAlign: TextAlign.end,
                  ),
                  Text(
                    TimeUtil.formatTime(lap.totalTime),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "${lap.distance.toStringAsFixed(2)}m",
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
