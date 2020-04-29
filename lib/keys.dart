class Keys {
  static const String RESET_BUTTON = "reset_button";
  static const String START_STOP_BUTTON = "start_stop_button";
  static const String FINISH_BUTTON = "finish_button";
  static const String LAP_BUTTON = "lap_button";

  static const String WATCH_TOTAL_TIME = "watch_total_time";
  static const String WATCH_CURRENT_LAP_TIME = "watch_current_lap_time";

  static const String LAP_LIST_ITEM_TITLE = "lap_list_item_title";
  static const String LAP_LIST_ITEM_DISTANCE = "lap_list_item_distance";
  static const String LAP_LIST_ITEM_SPEED = "lap_list_item_speed";

  static lapListItem(int index) => "lap_list_item_$index";
}
