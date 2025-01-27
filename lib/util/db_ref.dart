import 'package:firebase_database/firebase_database.dart';

// singleton firebase realtime db reference
class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance = FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;
  FirebaseDatabaseService._internal();

  final DatabaseReference _commandRef = FirebaseDatabase.instance.ref("command");
  final DatabaseReference _lastRef = FirebaseDatabase.instance.ref("feeder/last");
  final DatabaseReference _savedRef = FirebaseDatabase.instance.ref("feeder/saved");
  final DatabaseReference _msgRef = FirebaseDatabase.instance.ref("feeder/msg");
  final DatabaseReference _connectionRef = FirebaseDatabase.instance.ref(".info/connected");

  DatabaseReference get commandRef => _commandRef;
  DatabaseReference get lastRef => _lastRef;
  DatabaseReference get savedRef => _savedRef;
  DatabaseReference get msgRef => _msgRef;
  DatabaseReference get connectionRef => _connectionRef;
}
