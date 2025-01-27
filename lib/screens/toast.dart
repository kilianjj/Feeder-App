import 'package:flutter/material.dart';

// create appropriate ui snack bar based on board response msg
class ToastHelper {
  static Map<String, bool> msg_status = {
    "BeanSprout is online!": true,
    "Feed triggered!": true,
    "Time added!": true,
    "Can't save any more times!": false,
    "Failed to add time...": false,
    "Removed time!": true,
    "Failed to remove time...": false,
    "Time not recognized...": false,
    "Command not recognized...": false,
    "Lost Firebase connection...": false,
    "Sign-in failed": false
  };

  static SnackBar getToastBar (String msg) {
    if (!msg_status.keys.contains(msg)) {
      msg = "Command not recognized...";
    }
    bool success = msg_status[msg] ?? false;
    return SnackBar(
      content: Text(
        msg,
        style: TextStyle(color: Colors.white, fontSize: 16.0),
      ),
      backgroundColor: success ? Colors.green : Colors.red,
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(bottom: 50, left: 20, right: 20),
    );
  }
}