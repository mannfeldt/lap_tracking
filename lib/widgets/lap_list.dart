import 'package:flutter/material.dart';
import 'package:lap_tracking/models/lap.dart';
import 'package:lap_tracking/widgets/lap_list_item.dart';

class LapList extends StatelessWidget {
  final List<Lap> laps;
  final GlobalKey lapListKey;
  LapList({Key key, this.laps, this.lapListKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
      ),
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.8, 1])
              .createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
        },
        blendMode: BlendMode.dstIn,
        child: Padding(
          padding: EdgeInsets.only(
            top: 30,
          ),
          child: AnimatedList(
            padding: EdgeInsets.only(bottom: 120, right: 30, left: 30),
            key: lapListKey,
            initialItemCount: 0,
            itemBuilder: (BuildContext context, int index,
                    Animation<double> animation) =>
                Opacity(
              opacity: animation.value < 1 ? 0 : 1,
              child: SizeTransition(
                sizeFactor: animation,
                child: LapListItem(laps[laps.length - index - 1]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
