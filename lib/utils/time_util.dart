class TimeUtil {
  static String formatWatchTime(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours.toString()}:${(duration.inMinutes % 60).toString().padLeft(2, '0')} ${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes.toString()}:${(duration.inSeconds % 60).toString().padLeft(2, '0')} ${((duration.inMilliseconds / 10) % 100).floor().toString().padLeft(2, '0')}";
    } else {
      return "${(duration.inSeconds % 60).toString()} ${((duration.inMilliseconds / 10) % 100).floor().toString().padLeft(2, '0')}";
    }
  }

  static String formatLapItemTime(Duration duration) {
    if (duration.inHours > 0) {
      return "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
    } else {
      return "${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}:${((duration.inMilliseconds / 10) % 100).floor().toString().padLeft(2, '0')}";
    }
  }
}
