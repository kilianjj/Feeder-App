/// Arduino code for Wifi Mkr1010 board that connects to firebase to listen for
/// realtime requests and moves feeding servo accordingly, then updates firebase response

#include <WiFiNINA.h>
#include <NTPClient.h>
#include <ArduinoJson.h>
#include <Servo.h>
#include "wifi_secrets.h"
#include "Firebase_Arduino_WiFiNINA.h"

/// network and firebase creds:
/// define SECRET_SSID: newtork name
/// define SECRET_PASS: newtork pass
/// define DATABASE_SECRET: db secret token from firebase service account part of settings
/// define DATABASE_URL: db url WITHOUT https:// part

// network creds
const char ssid[] = SECRET_SSID;
const char pass[] = SECRET_PASS;

// servo positions
const int SERVO_REST_POSITION = 0;
const int SERVO_FEED_POSITION = 90;

// network status
int status = WL_IDLE_STATUS;

// servo, server
Servo feedServo;
WiFiServer server(80);

// firebase db reference and stream of command data
FirebaseData fbdo;
FirebaseData commandStream;

// firebase data paths
const char LAST_PATH[] = "/feeder/last";
const char COMMAND_PATH[] = "/command";
const char MSG_PATH[] = "/feeder/msg";
const char SAVED_PATH[] = "/feeder/saved";

// response msgs
const char ONLINE_STR[] = "BeanSprout is online!";
const char TRIGGER_STR[] = "Feed triggered!";
const char ADDED_STR[] = "Time added!";
const char MAX_STR[] = "Can't save any more times!";
const char F_ADD_STR[] = "Failed to add time...";
const char REMOVE_STR[] = "Removed time!";
const char F_REMOVE_STR[] = "Failed to remove time...";
const char NOT_REC_STR[] = "Time not recognized...";
const char F_CMD_STR[] = "Command not recognized...";

// settings for fetching time
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0, 30000); // update every 30 secs

// max scheduled feed time
const int MAX_SAVED_TIMES = 10;
// stored feeding times
char feedTimes[10][6];
// current number saved
int savedSize = 0;

// last time feed was triggered (to prevent it from going off like every 2 seconds)
char LAST_FEED[6] = "";

/// prints network and board info
void printConnectionData() {
    Serial.println("Board Information:");
    IPAddress ip = WiFi.localIP();
    Serial.print("IP Address: ");
    Serial.println(ip);
    Serial.println();
    Serial.println("Network Information:");
    Serial.print("SSID: ");
    Serial.println(WiFi.SSID());
    long rssi = WiFi.RSSI();
    Serial.print("signal strength (RSSI):");
    Serial.println(rssi);
}

// convert time list to string for storage in db
String timesToString() {
    String csv = "";
    for (int i=0; i < savedSize; i++) {
        csv += feedTimes[i];
        csv += ",";
    }
    return csv;
}

// parse saved times list string into list
void parseListData(String savedListStr) {
    char* token;
    char inputCharArray[savedListStr.length() + 1];
    savedListStr.toCharArray(inputCharArray, savedListStr.length() + 1);
    token = strtok(inputCharArray, ",");
    while (token != NULL) {
        // Serial.println(token);
        if (timeFormat(token)) {
            strncpy(feedTimes[savedSize], token, 6);
        }
        token = strtok(NULL, ",");
        savedSize += 1;
    }
}

// get saved times from firebase
void fetchSavedTimes() {
    // Serial.println("Trying to populate saved times");
    if (Firebase.get(fbdo, SAVED_PATH)) {
        // Serial.println("Getting saved times...");
        parseListData(fbdo.stringData());
    } else {
        Serial.println("error, " + fbdo.errorReason());
    }
}

/// connect to wifi, start server: wireless client isolation must be disabled for router
void startServer() {
    // connect and print details
    Serial.begin(9600);  // get a serial port
    while (!Serial);
    while (status != WL_CONNECTED) {
        Serial.println("Trying to connect to internet...");
        WiFiDrv::analogWrite(25, 25);
        status = WiFi.begin(ssid, pass);
        delay(15000);
    }
    WiFiDrv::analogWrite(25, 0);
    Serial.println("Connected");
    printConnectionData();
    server.begin();
    timeClient.begin();
    Serial.print("Server started at IP: ");
    Serial.println(WiFi.localIP());
    // make firebase connection
    Firebase.begin(DATABASE_URL, DATABASE_SECRET, SECRET_SSID, SECRET_PASS);
    Firebase.reconnectWiFi(true);
    // firebase command stream connection
    if (!Firebase.beginStream(commandStream, COMMAND_PATH)) {
        Serial.println("Can't connect stream, " + commandStream.errorReason());
        Serial.println();
    }
}

/// setup procedure
void setup() {
    startServer();
    WiFiDrv::pinMode(25, OUTPUT); // red LED
    WiFiDrv::pinMode(26, OUTPUT); // green LED
    WiFiDrv::pinMode(27, OUTPUT); // blue LED
    feedServo.attach(9);          // servo pin
    feedServo.write(SERVO_REST_POSITION); // put in rest position
    // pull any saved times from firebase
    fetchSavedTimes();
}

// write value to specified firebase path
void writeToFirebase(String path, String data) {
    // path should be of the form /path with no file type
    // Serial.print("Trying to set string... ");
    if (Firebase.setString(fbdo, path, data)) {
        // Serial.println("Wrote successfully");
    } else {
        Serial.println("error, " + fbdo.errorReason());
    }
}

/// add a stored time
bool addTime(String newTime) {
    if (!timeFormat(newTime)) {
        return false;
    }
    if (savedSize >= MAX_SAVED_TIMES) {
        return false;
    }
    for (int i = 0; i < savedSize; i++) {
        if (strcmp(newTime.c_str(), feedTimes[i]) == 0) return false;
    }
    strncpy(feedTimes[savedSize], newTime.c_str(), 6);
    savedSize++;
    return true;
}

/// remove a stored time
bool removeTime(int index) {
    if (index < 0 || index >= savedSize) return false;
    strncpy(feedTimes[index], feedTimes[savedSize - 1], 6);
    savedSize--;
    return true;
}

// get index to delete
int getDeleteIndex(String t) {
    if (!timeFormat(t)) {
        return -1;
    }
    int d = -1;
    for (int i = 0; i < savedSize; i++) {
        if (strcmp(t.c_str(), feedTimes[i]) == 0) {
            d = i;
            break;
        }
    }
    return d;
}

/// feed servo movement and write time to db
void feedProcedure(String currentTime) {
    if (strcmp(currentTime.c_str(), LAST_FEED) != 0) {
        Serial.println("feeding...");
        feedServo.write(SERVO_FEED_POSITION);
        delay(2000);
        feedServo.write(SERVO_REST_POSITION);
        strncpy(LAST_FEED, currentTime.c_str(), 6);
        writeToFirebase(LAST_PATH, currentTime);
    }
}

/// check if time is formatted correctly
bool timeFormat(String t) {
    if (t.length() == 5) {
        for (int i = 0; i < t.length(); i++) {
            char c = t.charAt(i);
            if (i == 2) {
                if (c != ':') {
                    return false;
                }
            } else {
                if (!isDigit(c)) return false;
            }
        }
        return true;
    }
    return false;
}

// parse commands from db
void parseCommand(String c, String now) {
    if (c.length() == 0) {
        return;
    }
    switch (c[0]) {
        case 'g':
            writeToFirebase(MSG_PATH, ONLINE_STR);
            break;
        case 'n':
            feedProcedure(now);
            writeToFirebase(MSG_PATH, TRIGGER_STR);
            break;
        case 'a': {
            if (addTime(c.substring(1))){
                writeToFirebase(SAVED_PATH, timesToString());
                writeToFirebase(MSG_PATH, ADDED_STR);
            } else {
                if (savedSize == 10) {
                    writeToFirebase(MSG_PATH, MAX_STR);
                } else {
                    writeToFirebase(MSG_PATH, F_ADD_STR);
                }
            }
            break;
        }
        case 'd': {
            int index = getDeleteIndex(c.substring(1));
            if (index != -1) {
                if (removeTime(index)) {
                    writeToFirebase(SAVED_PATH, timesToString());
                    writeToFirebase(MSG_PATH, REMOVE_STR);
                } else {
                    writeToFirebase(MSG_PATH, F_REMOVE_STR);
                }
            } else {
                writeToFirebase(MSG_PATH, NOT_REC_STR);
            }
            break;
        }
        default:
            writeToFirebase(MSG_PATH, F_CMD_STR);
            break;
    }
    writeToFirebase(COMMAND_PATH, "");
}

/// check if current time is stored
void checkStoredTime(String now) {
    // Serial.println("Saved times :");
    for (int i = 0; i < savedSize; i++) {
        // Serial.print(feedTimes[i]);
        // Serial.print(" ");
        if (now == feedTimes[i]) {
            feedProcedure(now);
            break;
        }
    }
}

// check if stream is working, has timed out, or has data available
// if has data, parse the command
void streamLoop(String time) {
    if (!Firebase.readStream(commandStream)) {
        Serial.println("Can't read stream, " + commandStream.errorReason());
    }
    if (commandStream.streamTimeout()) {
        Serial.println("Stream timed out, resuming...");
        Firebase.endStream(commandStream);
        if (!Firebase.beginStream(commandStream, COMMAND_PATH)) {
            Serial.println("Can't connect stream, " + commandStream.errorReason());
            Serial.println();
        }
    }
    if (commandStream.streamAvailable()) {
        // Serial.println("New data received:");
        String data = commandStream.stringData();
        // Serial.println("Data: " + data);
        parseCommand(data, time);
    }
}

/// loop procedure
void loop() {
    // update the current time
    timeClient.update();
    String currentTime = timeClient.getFormattedTime().substring(0, 5); // HH:MM
    // Serial.println();
    // Serial.println(currentTime);

    // check for updates from firebase stream
    streamLoop(currentTime);

    // check stored times for feeds
    checkStoredTime(currentTime);

    // check wifi connection
    if (status != WL_CONNECTED) {
        startServer();
    }
    delay(1000);
}