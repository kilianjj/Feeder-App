import 'package:flutter/material.dart';
import 'package:haochi_app/util/feeder_state.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:haochi_app/util/time_convert.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:haochi_app/util/db_ref.dart';

// ui and logic for scheduled list of feed times
class ScheduleListPage extends StatefulWidget {

  @override
  _ScheduleListPageState createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
  Stream<DatabaseEvent> _savedStream =
      FirebaseDatabaseService().savedRef.onValue;

  // call model to remove a time
  // if successful remove from ui list too
  void removeSavedTime(BuildContext context, int index) async {
    String timeToRemove = FeederState.cachedSavedTimes[index];
    TimeOfDay selectedTime = TimeConverter.parseTimeOfDayString(timeToRemove);
    String formattedTime = TimeConverter.convertToBoardTime(selectedTime);
    await FeederState.removeTime(formattedTime, index,
        (s) {
          if (s) {
            FeederState.cachedSavedTimes.removeAt(index);
          }
        }
    );
  }

  Widget listWidget(List<String> items) {
    return Column(
      children: [
        Text(
          'Saved Times',
          style: TextStyle(
              fontSize: 24,
              color: Colors.black,
              fontWeight: FontWeight.w500
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final time = items[index];
              return Slidable(
                key: ValueKey(time),
                startActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  dismissible: DismissiblePane(onDismissed: () {
                    removeSavedTime(context, index);
                  }),
                  children: [
                    SlidableAction(
                      onPressed: (_) => removeSavedTime(context, index),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        time,
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
        stream: _savedStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error fetching data"));
          }
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final savedTimes = snapshot.data!.snapshot.value;
            if (savedTimes is String) {
              List<String> savedTimesList = savedTimes
                  .split(',')
                  .where((e) => e.isNotEmpty)
                  .map((e) => e.trim())
                  .toList();
              FeederState.cachedSavedTimes = savedTimesList.map((time) {
                return TimeConverter.parseBoardTime(time);
              }).toList();
              FeederState.cachedSavedTimes.sort();
            } else {
              FeederState.cachedSavedTimes = [];
            }
          }
          return listWidget(FeederState.cachedSavedTimes);
      }
    );
  }
}