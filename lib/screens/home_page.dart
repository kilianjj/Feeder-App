import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:haochi_app/screens/settings.dart';
import 'package:haochi_app/screens/schedule_list_page.dart';
import 'package:haochi_app/util/feeder_state.dart';
import 'package:haochi_app/util/db_ref.dart';
import 'package:haochi_app/util/time_convert.dart';
import 'package:haochi_app/screens/toast.dart';
import 'package:haochi_app/util/feed_api.dart';

// Main page of the app
// Show last feed time, trigger feeds, and switch to other app screens
class MainPage extends StatefulWidget {

  MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  // db streams for last feed time and msg updates
  Stream<DatabaseEvent> _lastFeedStream =
  FirebaseDatabaseService().lastRef.onValue.asBroadcastStream();
  Stream<DatabaseEvent> _msgStream =
  FirebaseDatabaseService().msgRef.onValue.asBroadcastStream();
  Stream<DatabaseEvent> _connectionStream =
  FirebaseDatabaseService().connectionRef.onValue.asBroadcastStream();
  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  StreamSubscription<DatabaseEvent>? _msgSubscription;
  StreamSubscription<DatabaseEvent>? _feedSub;

  // fetch updated info from db, make widget listen to streams for ui updates
  @override
  void initState() {
    FeedApi.getInfo();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // get last time
    _feedSub = _lastFeedStream.listen((DatabaseEvent event) {
      FeederState.cachedLastFeed = event.snapshot.value!.toString();
    });
    // check connection status
    _connectionSubscription = _connectionStream.listen((DatabaseEvent event) {
      final bool isConnected = event.snapshot.value as bool? ?? false;
      // debugPrint("Firebase connected: $isConnected");
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
            ToastHelper.getToastBar("Lost Firebase connection...")
        );
      }
    });
    // listen to msg stream for changes
    _msgSubscription = _msgStream.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        String message = event.snapshot.value.toString();
        message = message.trim();
        if (!message.isEmpty && message != "null") {
          ScaffoldMessenger.of(context).showSnackBar(
              ToastHelper.getToastBar(message)
          );
          FeederState.clearMsg();
        }
      }
    });
  }

  // call state model to add selected time to feeder
  // shows feeder response msg
  void addSelectedTime(TimeOfDay selectedTime) async {
    String formattedTime = TimeConverter.convertToBoardTime(selectedTime);
    await FeederState.addTime(formattedTime,
            (s) {
          if (s) {
            FeederState.cachedSavedTimes.add(formattedTime);
          }
        }
    );
  }

  Future<void> openTimePicker(BuildContext context) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      addSelectedTime(selectedTime);
    }
  }

  // call state model to trigger a feed right now
  // shows feeder response msg
  void triggerFeed() {
    FeederState.feedNow(
            (s) {
        }
    );
  }

  // builds scaffolding, app bar, etc
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            "BeanSprout",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
        onPressed: () {
          openTimePicker(context);
        },
        child: Icon(Icons.add),
      )
          : null,
      body: _currentIndex == 0 ? buildStreamHomePage() : ScheduleListPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Scheduled",
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // cancel the stream subscriptions
    _msgSubscription?.cancel();
    _connectionSubscription?.cancel();
    _feedSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // show last feed time and trigger feed button
  Widget feedWidget(String lastFeed) {
    String formattedTime = TimeConverter.parseBoardTime(lastFeed);
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Last fed: ${formattedTime}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        // color: Theme.of(context).colorScheme.secondary,
                        color: Colors.black
                    ),
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: triggerFeed,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.white70,
                      textStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                    child: Text('Feed now'),
                  ),
                ])
        )
    );
  }

  // builds home page info widget based on feeder state in db
  Widget buildStreamHomePage() {
    return StreamBuilder<DatabaseEvent>(
        stream: _lastFeedStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error fetching data");
          } else if (snapshot.hasData) {
            FeederState.cachedLastFeed = snapshot.data!.snapshot.value.toString();
          }
          return feedWidget(FeederState.cachedLastFeed);
        }
    );
  }
}