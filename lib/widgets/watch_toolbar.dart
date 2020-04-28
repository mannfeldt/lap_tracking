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

  WatchToolbar({
    Key key,
    this.currentLap,
    this.onStart,
    this.onStop,
    this.onReset,
    this.state,
    this.onFinish,
    this.onLap,
  }) : super(key: key);

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
              "RESET",
              style: TextStyle(
                  color: Colors.white, fontSize: 14, letterSpacing: 0.8),
            ),
          ),
        ),
        RawMaterialButton(
          onPressed: widget.state == WatchState.running ? stop : start,
          padding: EdgeInsets.all(16.0),
          shape: CircleBorder(),
          fillColor: Color.fromRGBO(93, 151, 246, 1),
          highlightColor: Color.fromRGBO(
              (93 / 0.9).round(), (151 / 0.9).round(), (255).round(), 1),
          splashColor: Color.fromRGBO(93, 151, 246, 1),
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
                    "FINISH",
                    style: TextStyle(
                        color: Colors.white, fontSize: 14, letterSpacing: 0.8),
                  ),
                )
              : FlatButton(
                  highlightColor: Colors.white30,
                  onPressed: widget.onLap,
                  child: Text(
                    "LAP",
                    style: TextStyle(
                        color: Colors.white, fontSize: 14, letterSpacing: 0.8),
                  ),
                ),
        ),
      ],
    );
  }
}
