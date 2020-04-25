import 'package:flutter/material.dart';
import 'package:lap_tracking/models/watch_state.dart';

class WatchToolbar extends StatefulWidget {
  final Function onStart;
  final Function onStop;
  final Function onReset;
  final Function onFinish;
  final Function onLap;
  final WatchState state;
  final Duration currentLap;
  WatchToolbar(
      {Key key,
      this.currentLap,
      this.onStart,
      this.onStop,
      this.onReset,
      this.state,
      this.onFinish,
      this.onLap})
      : super(key: key);

  @override
  _WatchToolbarState createState() => _WatchToolbarState();
}

class _WatchToolbarState extends State<WatchToolbar>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;

  void start() {
    controller.forward();
    widget.onStart();
  }

  void stop() {
    controller.reverse();
    widget.onStop();
  }

  void reset() {
    controller.reverse();
    widget.onReset();
  }

  @override
  void initState() {
    controller = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Visibility(
          visible: widget.state != WatchState.unstarted,
          maintainAnimation: true,
          maintainSize: true,
          maintainState: true,
          child: FlatButton(
            highlightColor: Colors.white30,
            onPressed: reset,
            child: Text(
              "Reset",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        RawMaterialButton(
          onPressed: widget.state == WatchState.running ? stop : start,
          padding: EdgeInsets.all(8.0),
          shape: CircleBorder(),
          fillColor: Colors.indigoAccent.shade200,
          splashColor: Colors.indigoAccent.shade100,
          focusColor: Colors.indigoAccent.shade100,
          highlightColor: Colors.indigoAccent.shade100,
          elevation: 4.0,
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            color: Colors.white,
            progress: controller,
          ),
        ),
        Visibility(
          visible: widget.state != WatchState.unstarted,
          maintainAnimation: true,
          maintainSize: true,
          maintainState: true,
          child: widget.state == WatchState.stopped
              ? FlatButton(
                  highlightColor: Colors.white30,
                  onPressed: widget.onFinish,
                  child: Text(
                    "Finish",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : FlatButton(
                  highlightColor: Colors.white30,
                  onPressed: widget.onLap,
                  child: Text(
                    "Lap",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ),
      ],
    );
  }
}
