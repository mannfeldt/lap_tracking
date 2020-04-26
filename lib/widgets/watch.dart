import 'package:flutter/material.dart';
import 'package:lap_tracking/utils/time_util.dart';

class Watch extends StatelessWidget {
  final Duration total;
  final Duration currentLap;
  Watch({Key key, this.total, this.currentLap}) : super(key: key);

  //! kanske döpa om till mainWatch och lägga currentlap överst i listan av varv som i stock android stopwatch.
  //mindre fontsize på hundradelarna? som i andrid stock

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      padding: EdgeInsets.only(
          top: currentLap != null ? 30.0 : (size.height / 2) - 80),
      child: Column(
        children: [
          Text(
            TimeUtil.formatTime(total),
            style: Theme.of(context).textTheme.headline2,
          ),
          AnimatedOpacity(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeIn,
            opacity: currentLap != null ? 1 : 0,
            child: Text(
              TimeUtil.formatTime(currentLap ?? Duration()),
              style: Theme.of(context).textTheme.headline5,
            ),
          ),
        ],
      ),
    );
  }
}
