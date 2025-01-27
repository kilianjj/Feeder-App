import 'package:haochi_app/util/db_ref.dart';

// methods for putting commands to db
class FeedApi {
  static final String add = "a";
  static final String now = "n";
  static final String get = "g";
  static final String delete = "d";
  static final String command = "command";

  static clearMsg() async {
    try {
      await FirebaseDatabaseService().msgRef.set("");
    } catch (e) {
      throw Exception('Error putting to db: $e');
    }
  }

  static triggerFeed(Function(bool) successCallback) async {
    try {
      await FirebaseDatabaseService().commandRef.set(now);
      successCallback(true);
    } catch (e) {
      successCallback(false);
      // throw Exception('Error putting to db: $e');
    }
  }

  static getInfo() async {
    try {
      await FirebaseDatabaseService().commandRef.set(get);
    } catch (e) {
      throw Exception('Error putting to db: $e');
    }
  }

  static addScheduledFeed(String newTime, Function(bool) successCallback) async {
    try {
      await FirebaseDatabaseService().commandRef.set(add + newTime);
      successCallback(true);
    } catch (e) {
      successCallback(false);
      // throw Exception('Error putting to db: $e');
    }
  }

  static deleteScheduledFeed(String oldTime, Function(bool) successCallback) async {
    try {
      await FirebaseDatabaseService().commandRef.set(delete + oldTime);
      successCallback(true);
    } catch (e) {
      successCallback(false);
      // throw Exception('Error putting to db: $e');
    }
  }
}