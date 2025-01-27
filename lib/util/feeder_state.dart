import 'package:haochi_app/util/feed_api.dart';

class FeederState {

  static String cachedLastFeed = "loading...";
  static String cachedMsg = "msg";
  static List<String> cachedSavedTimes = [];

  static getFeederInfo() async {
    await FeedApi.getInfo();
  }

  static clearMsg() async {
    await FeedApi.clearMsg();
  }

  static feedNow(Function(bool) successCallback) async {
    await FeedApi.triggerFeed(successCallback);
  }

  // try to remove a saved time
  static removeTime(String time, int index, Function(bool) successCallback) async {
    if (FeederState.cachedSavedTimes.isEmpty) {
      successCallback(false);
    } else {
      await FeedApi.deleteScheduledFeed(time, successCallback);
    }
  }

  // try to add a scheduled time
  static addTime(String time, Function(bool) successCallback) async {
    if (FeederState.cachedSavedTimes.length >= 10) {
      successCallback(false);
    } else {
      await FeedApi.addScheduledFeed(time, successCallback);
    }
  }
}