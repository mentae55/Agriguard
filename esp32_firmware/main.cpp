#include <Arduino.h>
#include <WiFi.h>
#include <Preferences.h>        // Save WiFi credentials in NVS permanent storage
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>         // Servo library for ultrasonic pan servo

// =============================================================================
// --- Pin Configuration ---
// =============================================================================
#define FIREBASE_HOST  "https://agriguard-ca00b-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH  "f4a9cpr7svLSmn37lXkshcCdcu8grY92ERP1SpT9"
#define RELAY_PIN      13       // Kept 13 from original design
#define STATUS_LED     2

// Motor driver pins (L298N with PWM speed control)
#define MOTOR_IN1    27    // Left motor forward
#define MOTOR_IN2    26    // Left motor backward
#define MOTOR_IN3    25    // Right motor forward
#define MOTOR_IN4    33    // Right motor backward
#define SPEED_L      14    // Left motor PWM speed pin (EN A)
#define SPEED_R      32    // Right motor PWM speed pin (EN B)

// Ultrasonic sensor pins
#define TRIG_PIN      12
#define ECHO_PIN      35   // Input-only GPIO - ideal for echo
#define SAFE_DISTANCE 15   // cm - obstacle threshold

// Servo pin for ultrasonic pan
#define SERVO_PIN     15

// NVS storage keys
#define PREF_NAMESPACE "agriguard"
#define PREF_SSID      "ssid"
#define PREF_PASS      "pass"
#define PREF_MAC       "mac"

// =============================================================================
// --- BLE UUIDs (unchanged - keeps Flutter app compatibility) ---
// =============================================================================
#define SERVICE_UUID         "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CRED_WRITE_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define WIFI_LIST_CHAR_UUID  "c865921c-29b1-11ee-be56-0242ac120002"
#define CMD_WRITE_CHAR_UUID  "beb5483e-36e1-4688-b7f5-ea07361b26aa"

// =============================================================================
// --- GPS Simulation Settings ---
// Base point: Cairo, Egypt (30.0444, 31.2357)
// =============================================================================
#define GPS_BASE_LAT   30.0444
#define GPS_BASE_LNG   31.2357
#define GPS_MAX_DRIFT  0.0015    // ~150 meters radius drift
#define GPS_UPDATE_MS  10000     // Kept 10000ms (10 seconds) from original design

// =============================================================================
// --- Timing Constants ---
// =============================================================================
#define CMD_POLL_MS            500    // Poll robot command from Firebase every 500ms
#define FIREBASE_CHECK_INTERVAL 2000  // Read relay status every 2 seconds
#define WIFI_RETRY_MS          30000  // Attempt WiFi reconnect every 30 seconds

// =============================================================================
// --- Global Variables ---
// =============================================================================
FirebaseData   fbdo;
FirebaseData   fbdoCmd;            // Dedicated for robot command polling
FirebaseConfig fbConfig;
FirebaseAuth   fbAuth;
Preferences    prefs;

// Servo for ultrasonic pan
Servo myServo;

BLECharacteristic* pListCharacteristic = nullptr;

String bleBuffer     = "";
String targetSSID    = "";
String targetPass    = "";
String deviceSerial  = "";   // MAC without colons
String deviceMacFull = "";   // MAC with colons - used for Firebase paths

bool startWifi   = false;
bool fbInit      = false;
bool bleActive   = true;
bool presenceOk  = false;    // Tracks firebase presence status

// Timers
unsigned long lastFirebaseCheck = 0;
unsigned long lastGpsSend       = 0;
unsigned long lastCmdPoll       = 0;
unsigned long lastWifiRetry     = 0;  // For persistent WiFi reconnect
unsigned long lastSuccessfulPollTime = 0; // Tracks last successful Firebase poll for safety shutdown

// Simulated GPS position
float simLat = GPS_BASE_LAT;
float simLng = GPS_BASE_LNG;
// Motor state
String lastCmd  = "STOP";   // Tracks last Firebase command to avoid redundant writes
int    appStatus = 0;       // 1 = Start (autonomous run enabled), 0 = Stop

// =============================================================================
// --- Helper: Add colons to raw MAC string ---
// =============================================================================
String addColonsToMac(String rawMac) {
  rawMac.toUpperCase();
  if (rawMac.length() != 12) return rawMac;
  String result = "";
  for (int i = 0; i < 12; i += 2) {
    result += rawMac.substring(i, i + 2);
    if (i < 10) result += ":";
  }
  return result;
}

// =============================================================================
// --- Helper: WiFi Scan ---
// =============================================================================
String scanNetworks() {
  Serial.println("Scanning WiFi...");
  WiFi.mode(WIFI_STA);
  int n = WiFi.scanNetworks();
  if (n == 0) return "No networks found";
  String list = "";
  for (int i = 0; i < n; ++i) {
    list += WiFi.SSID(i);
    if (i < n - 1) list += ",";
  }
  Serial.println("Found: " + list);
  return list;
}

// =============================================================================
// --- Helper: Save credentials to NVS ---
// =============================================================================
void saveCredentials(String ssid, String pass, String mac) {
  prefs.begin(PREF_NAMESPACE, false);
  prefs.putString(PREF_SSID, ssid);
  prefs.putString(PREF_PASS, pass);
  prefs.putString(PREF_MAC,  mac);
  prefs.end();
  Serial.println("Credentials saved to NVS.");
}

// =============================================================================
// --- Helper: Load credentials from NVS ---
// =============================================================================
bool loadCredentials() {
  prefs.begin(PREF_NAMESPACE, true); // read-only
  targetSSID   = prefs.getString(PREF_SSID, "");
  targetPass   = prefs.getString(PREF_PASS, "");
  deviceSerial = prefs.getString(PREF_MAC,  "");
  prefs.end();
  if (targetSSID.isEmpty()  deviceSerial.isEmpty()) {
    Serial.println("No saved credentials found.");
    return false;
  }

  deviceMacFull = addColonsToMac(deviceSerial);
  Serial.println("Loaded from NVS:");
  Serial.println("  SSID:   " + targetSSID);
  Serial.println("  Serial: " + deviceSerial);
  Serial.println("  MAC:    " + deviceMacFull);
  return true;
}

// =============================================================================
// --- Motor Control Functions (PWM speed + direction) ---
// Uses analogWrite for speed + existing IN1-IN4 direction logic
// =============================================================================
void motorsStop() {
  digitalWrite(MOTOR_IN1, LOW);
  digitalWrite(MOTOR_IN2, LOW);
  digitalWrite(MOTOR_IN3, LOW);
  digitalWrite(MOTOR_IN4, LOW);
  analogWrite(SPEED_L, 0);
  analogWrite(SPEED_R, 0);
  Serial.println("[Motor] STOP");
}

void motorsForward() {
  motorsStop(); // safety: stop before changing direction
  digitalWrite(MOTOR_IN1, HIGH);
  digitalWrite(MOTOR_IN2, LOW);
  digitalWrite(MOTOR_IN3, HIGH);
  digitalWrite(MOTOR_IN4, LOW);
  analogWrite(SPEED_L, 150);
  analogWrite(SPEED_R, 150);
  Serial.println("[Motor] FORWARD");
}

void motorsBackward() {
  motorsStop();
  digitalWrite(MOTOR_IN1, LOW);
  digitalWrite(MOTOR_IN2, HIGH);
  digitalWrite(MOTOR_IN3, LOW);
  digitalWrite(MOTOR_IN4, HIGH);
  analogWrite(SPEED_L, 150);
  analogWrite(SPEED_R, 150);
  Serial.println("[Motor] BACKWARD");
}

void motorsTurnLeft() {
  motorsStop();
  // Left motor backward, right motor forward -> tank turn left
  digitalWrite(MOTOR_IN1, LOW);
  digitalWrite(MOTOR_IN2, HIGH);
  digitalWrite(MOTOR_IN3, HIGH);
  digitalWrite(MOTOR_IN4, LOW);
  analogWrite(SPEED_L, 150);
  analogWrite(SPEED_R, 150);
  Serial.println("[Motor] LEFT");
}

void motorsTurnRight() {
  motorsStop();
  // Left motor forward, right motor backward -> tank turn right
  digitalWrite(MOTOR_IN1, HIGH);
  digitalWrite(MOTOR_IN2, LOW);
  digitalWrite(MOTOR_IN3, LOW);
  digitalWrite(MOTOR_IN4, HIGH);
  analogWrite(SPEED_L, 150);
  analogWrite(SPEED_R, 150);
  Serial.println("[Motor] RIGHT");
}

// =============================================================================
// --- Execute Command from Firebase ---
// Called when a new command string is received from Flutter app.
// Strings must match what Flutter's RobotControlService sends.
// =============================================================================
void executeMotorCommand(String cmd) {
  cmd.trim();
  cmd.toUpperCase();

  if (cmd == lastCmd) return; // avoid redundant execution
  lastCmd = cmd;

  Serial.println("[CMD] Received: " + cmd);

  if      (cmd == "FORWARD")  motorsForward();
  else if (cmd == "BACKWARD") motorsBackward();
  else if (cmd == "LEFT")     motorsTurnLeft();
  else if (cmd == "RIGHT")    motorsTurnRight();
  else                        motorsStop(); // "STOP" or unknown -> safe stop
}

// =============================================================================
// --- Ultrasonic Distance Measurement ---
// =============================================================================
long getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  long duration = pulseIn(ECHO_PIN, HIGH, 30000); // 30ms timeout
  return duration * 0.034 / 2;
}

// =============================================================================
// --- Smart Obstacle Avoidance ---
// Servo pans to scan right/left. Wheels move only if autonomous run is active.
// Uses blocking delays intentionally - avoidance is a short, safe critical path.
// =============================================================================
void avoidObstacle(bool moveWheels) {
  motorsStop();
  Serial.println("[Obstacle] Detected! Scanning surroundings...");

  // 1. Servo scans right
  myServo.write(150);
  delay(600);
  long distRight = getDistance();
  Serial.printf("[Obstacle] Scan Right: %ld cm\n", distRight);

  if (distRight > SAFE_DISTANCE) {
    // Removed duplicate erroneous block
    Serial.println("[Obstacle] Right is clear -> turning RIGHT");
    myServo.write(90);
    delay(400);
    if (moveWheels) {
      motorsTurnRight();
      delay(800);
      motorsStop();
    }
    return;
  }

  

  // 2. Servo scans left
  myServo.write(30);
  delay(600);
  long distLeft = getDistance();
  Serial.printf("[Obstacle] Scan Left: %ld cm\n", distLeft);

  myServo.write(90); // Re-center servo
  delay(400);

  if (distLeft > SAFE_DISTANCE) {
    Serial.println("[Obstacle] Left is clear -> turning LEFT");
    if (moveWheels) {
      motorsTurnLeft();
      delay(800);
      motorsStop();
    }
  } else {
    // Both sides blocked -> reverse and turn
    Serial.println("[Obstacle] Both sides blocked -> reversing");
    if (moveWheels) {
      motorsBackward();
      delay(1000);
      motorsTurnLeft();
      delay(800);
      motorsStop();
    }
  }
}

// =============================================================================
// --- GPS Simulation ---
// Generates slightly drifted lat/lng every update to mimic real movement.
// =============================================================================
void updateSimulatedGPS() {
  float driftLat = ((float)random(-1000, 1000) / 1000000.0) * GPS_MAX_DRIFT * 1000;
  float driftLng = ((float)random(-1000, 1000) / 1000000.0) * GPS_MAX_DRIFT * 1000;

  simLat += driftLat;
  simLng += driftLng;

  // Clamp to stay within drift radius of base
  if (simLat > GPS_BASE_LAT + GPS_MAX_DRIFT) simLat = GPS_BASE_LAT + GPS_MAX_DRIFT;
  if (simLat < GPS_BASE_LAT - GPS_MAX_DRIFT) simLat = GPS_BASE_LAT - GPS_MAX_DRIFT;
  if (simLng > GPS_BASE_LNG + GPS_MAX_DRIFT) simLng = GPS_BASE_LNG + GPS_MAX_DRIFT;
  if (simLng < GPS_BASE_LNG - GPS_MAX_DRIFT) simLng = GPS_BASE_LNG - GPS_MAX_DRIFT;
}

// =============================================================================
// --- Send GPS to Firebase ---
// Writes to /Devices/{MAC}/gps with lat, lng and server timestamp.
// =============================================================================
void sendGPSToFirebase() {
  if (!Firebase.ready() || deviceMacFull.isEmpty()) return;
  

  String gpsPath = "/Devices/" + deviceMacFull + "/gps";

  FirebaseJson gpsJson;
  gpsJson.set("lat", simLat);
  gpsJson.set("lng", simLng);
  gpsJson.set("ts/.sv", "timestamp"); // server-side timestamp

  if (Firebase.RTDB.setJSON(&fbdo, gpsPath.c_str(), &gpsJson)) {
    Serial.printf("[GPS] Sent -> lat: %.6f, lng: %.6f\n", simLat, simLng);
  } else {
    Serial.println("[GPS] Error: " + fbdo.errorReason());
  }
}

// =============================================================================
// --- Poll Motor Command from Firebase ---
// Reads /Devices/{MAC}/cmd and executes if changed.
// =============================================================================
void pollMotorCommand() {
  if (!Firebase.ready() || deviceMacFull.isEmpty()) return;

  String cmdPath = "/Devices/" + deviceMacFull + "/cmd";

  if (Firebase.RTDB.getString(&fbdoCmd, cmdPath.c_str())) {
    lastSuccessfulPollTime = millis(); // Reset safety timeout on successful Firebase read
    String cmd = fbdoCmd.stringData();
    executeMotorCommand(cmd);
  } else {
    Serial.println("[CMD] Poll error: " + fbdoCmd.errorReason());
  }
}

// =============================================================================
// --- BLE Callback: CMD characteristic (SCAN_WIFI trigger) ---
// =============================================================================
class CmdCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pChar) {
      String cmd = String(pChar->getValue().c_str());
      cmd.trim();
      Serial.println("BLE CMD: " + cmd);
      if (cmd == "SCAN_WIFI" && pListCharacteristic != nullptr) {
        String nets = scanNetworks();
        pListCharacteristic->setValue(nets.c_str());
        pListCharacteristic->notify();
      }
    }
};
 // =============================================================================
// --- BLE Callback: Credentials characteristic (SSID,Pass,Serial\n) ---
// =============================================================================
class CredCallbacks : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pChar) {
      String value = String(pChar->getValue().c_str());
      if (value.length() > 0) {
        bleBuffer += value;
        if (bleBuffer.indexOf('\n') != -1) {
          bleBuffer.trim();
          Serial.println("BLE Received: [" + bleBuffer + "]");

          int c1 = bleBuffer.indexOf(',');
          int c2 = bleBuffer.lastIndexOf(',');

          if (c1 != -1 && c2 != -1 && c1 != c2) {
            targetSSID    = bleBuffer.substring(0, c1);
            targetPass    = bleBuffer.substring(c1 + 1, c2);
            deviceSerial  = bleBuffer.substring(c2 + 1);
            deviceMacFull = addColonsToMac(deviceSerial);

            Serial.println("Parsed -> SSID: " + targetSSID + " | MAC: " + deviceMacFull);
            saveCredentials(targetSSID, targetPass, deviceSerial);
            startWifi = true;
          }
          bleBuffer = "";
        }
      }
    }
};

// =============================================================================
// --- Firebase Presence Setup ---
// Registers onDisconnect handler BEFORE writing online = true.
// Firebase server automatically sets online = false when the socket drops.
// =============================================================================
// setupFirebasePresence() - sets online=true and resets cmd on every (re)connect.
// Note: Firebase v4.4.17 does not support setDisconnectBool.
// Instead, online=false is written manually when WiFi drops in loop().
void setupFirebasePresence() {
  if (deviceMacFull.isEmpty()) {
    Serial.println("[Presence] ERROR: deviceMacFull is empty - cannot register presence!");
    return;
  }

  String onlinePath = "/Devices/" + deviceMacFull + "/online";

  // Mark device as online
  if (Firebase.RTDB.setBool(&fbdo, onlinePath.c_str(), true)) {
    Serial.println("Firebase: online = true ✅");
  } else {
    Serial.println("Firebase setBool Error: " + fbdo.errorReason());
  }

  // Reset cmd to STOP - prevents ghost commands from previous session
  String cmdPath = "/Devices/" + deviceMacFull + "/cmd";
  Firebase.RTDB.setString(&fbdo, cmdPath.c_str(), "STOP");
  lastCmd = "STOP"; // Sync local state

  // Reset status to 0 - ensures autonomous mode is stopped at boot
  String statusPath = "/Devices/" + deviceMacFull + "/status";
  Firebase.RTDB.setInt(&fbdo, statusPath.c_str(), 0);
  appStatus = 0; // Sync local state

  lastSuccessfulPollTime = millis(); // Initialize safety poll timer

  presenceOk = true; // Mark presence as registered for this session
  Serial.println("[Presence] Setup complete for: " + deviceMacFull);
}

// =============================================================================
// --- Motor Pin & Servo Setup ---
// =============================================================================
void setupMotorPins() {
  pinMode(MOTOR_IN1, OUTPUT);
  pinMode(MOTOR_IN2, OUTPUT);
  pinMode(MOTOR_IN3, OUTPUT);
  pinMode(MOTOR_IN4, OUTPUT);
  pinMode(SPEED_L,   OUTPUT);
  pinMode(SPEED_R,   OUTPUT);
  motorsStop(); // ensure motors are stopped at boot
  Serial.println("[Motor] Pins configured. Motors stopped.");
}

void setupServo() {
  // Allocate LEDC timers for ESP32Servo
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);
  myServo.setPeriodHertz(50);
  myServo.attach(SERVO_PIN, 500, 2500);
  myServo.write(90); // Center on boot
  Serial.println("[Servo] Initialized and centered at 90°.");
}

// =============================================================================
// --- BLE Initialization ---
// =============================================================================
void _startBLE() {
  BLEDevice::init("AgriGuard_Robot");
  BLEServer*  pServer  = BLEDevice::createServer();
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // Characteristic 1: Credentials write
  BLECharacteristic* pCredChar = pService->createCharacteristic(
          CRED_WRITE_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCredChar->setCallbacks(new CredCallbacks());
  // Characteristic 2: WiFi list (read + notify)
  pListCharacteristic = pService->createCharacteristic(
          WIFI_LIST_CHAR_UUID,
          BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pListCharacteristic->addDescriptor(new BLE2902());
  pListCharacteristic->setValue("Waiting...");

  // Characteristic 3: CMD (SCAN_WIFI trigger)
  BLECharacteristic* pCmdChar = pService->createCharacteristic(
          CMD_WRITE_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCmdChar->setCallbacks(new CmdCallbacks());

  pService->start();
  BLEDevice::startAdvertising();
  Serial.println("BLE started: AgriGuard_Robot");
}

// =============================================================================
// --- Setup ---
// =============================================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n=== AgriGuard Boot ===");

  randomSeed(analogRead(0)); // Seed for GPS simulation

  // Basic I/O
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  pinMode(STATUS_LED, OUTPUT);

  // Ultrasonic
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  // Motors & Servo
  setupMotorPins();
  setupServo();

  // Load saved WiFi credentials from NVS
  bool hasSavedCreds = loadCredentials();

  if (hasSavedCreds) {
    // Credentials exist - connect to WiFi directly, skip BLE
    Serial.println("Found saved credentials. Connecting to WiFi directly...");
    WiFi.begin(targetSSID.c_str(), targetPass.c_str());
    bleActive = false;
  } else {
    // No credentials - start BLE so Flutter app can provision
    Serial.println("No saved creds. Starting BLE...");
    bleActive = true;
    _startBLE();
  }
}

// =============================================================================
// --- Loop ---
// =============================================================================
void loop() {
  // Blink status LED
  digitalWrite(STATUS_LED, (millis() / 500) % 2);

  // ----- Handle WiFi connect request from BLE provisioning -----
  if (startWifi) {
    startWifi = false;
    Serial.println("Connecting to WiFi: " + targetSSID);
    WiFi.disconnect(true);
    WiFi.begin(targetSSID.c_str(), targetPass.c_str());
    lastWifiRetry = millis(); // Reset retry timer
  }

  // ----- Persistent WiFi reconnect (if disconnected after first connect) -----
  if (!startWifi && fbInit && WiFi.status() != WL_CONNECTED) {
    if (millis() - lastWifiRetry > WIFI_RETRY_MS) {
      lastWifiRetry = millis();
      Serial.println("[WiFi] Connection lost. Retrying: " + targetSSID);
      WiFi.disconnect(true);
      WiFi.begin(targetSSID.c_str(), targetPass.c_str());
    }
  }

  // ----- Firebase init and periodic tasks (only when WiFi is connected) -----
  if (WiFi.status() == WL_CONNECTED) {

    // First-time Firebase initialization (runs only once per boot)
    if (!fbInit) {
      fbInit = true;
      Serial.println("WiFi Connected! IP: " + WiFi.localIP().toString());

      fbConfig.database_url               = FIREBASE_HOST;
      fbConfig.signer.tokens.legacy_token = FIREBASE_AUTH;
      Firebase.begin(&fbConfig, &fbAuth);
      Firebase.reconnectWiFi(true);

      // Setup presence: online=true now, server will set false on disconnect
      setupFirebasePresence();
    }

    // Read relay/status from Firebase every 2 seconds
    if (Firebase.ready() && presenceOk &&
        (millis() - lastFirebaseCheck > FIREBASE_CHECK_INTERVAL)) {
      lastFirebaseCheck = millis();
      String statusPath = "/Devices/" + deviceMacFull + "/status";
      if (Firebase.RTDB.getInt(&fbdo, statusPath.c_str())) {
        appStatus = fbdo.intData(); // 1 = autonomous run enabled
        digitalWrite(RELAY_PIN, (appStatus == 1) ? HIGH : LOW);
      }
    }

    // Send simulated GPS every GPS_UPDATE_MS
    if (Firebase.ready() && presenceOk &&
        (millis() - lastGpsSend > GPS_UPDATE_MS)) {
      lastGpsSend = millis();
      updateSimulatedGPS();
      sendGPSToFirebase();
    }
    // Poll manual movement command from Flutter app every CMD_POLL_MS
    if (Firebase.ready() && presenceOk &&
        (millis() - lastCmdPoll > CMD_POLL_MS)) {
      lastCmdPoll = millis();
      pollMotorCommand();
    }

    // Check for Firebase communication timeout (Safety)
    if (presenceOk && (millis() - lastSuccessfulPollTime > 5000)) {
      if (lastCmd != "STOP") {
        lastCmd = "STOP";
        motorsStop();
        Serial.println("[Safety] Motors stopped - Firebase connection timeout (5s).");
      }
    }

  } else if (fbInit) {
    // WiFi dropped after being connected
    // Safety: ensure motors stop immediately on connection loss
    if (lastCmd != "STOP") {
      lastCmd = "STOP";
      motorsStop();
      Serial.println("[Safety] Motors stopped - WiFi lost.");
    }
    // Mark device offline in Firebase when WiFi drops and presence was registered
    // This runs once per disconnect by resetting presenceOk
    if (presenceOk && !deviceMacFull.isEmpty()) {
      presenceOk = false; // Will re-register (and set online=true) on reconnect
      Serial.println("[Presence] WiFi lost - will set online=false on next reconnect.");
    }
  }

  // ----- Obstacle Avoidance (runs regardless of connectivity) -----
  // Determines whether wheels should move based on online/offline state
  bool shouldRun = false;
  bool isMoving = false;
  if (WiFi.status() == WL_CONNECTED) {
    // Online: autonomous run only if appStatus = 1 (Flutter "Start" button)
    // Note: Manual D-pad commands from Flutter are handled by pollMotorCommand()
    shouldRun = (appStatus == 1);
    isMoving = (appStatus == 1 || lastCmd != "STOP");
  } else {
    // Offline / BLE-only mode: allow movement if not explicitly stopped
    shouldRun = (lastCmd != "STOP");
    isMoving = (lastCmd != "STOP");
  }

  long distance = getDistance();

  // Only check obstacles if the robot is actually moving (saves power, avoids false boot triggers)
  // Also filter out false 0/timeout readings (distance must be > 2 cm)
  if (isMoving && distance > 2 && distance <= SAFE_DISTANCE) {
    delay(10); // Short delay to double check and filter noise spikes
    long confirmDistance = getDistance();
    if (confirmDistance > 2 && confirmDistance <= SAFE_DISTANCE) {
      // Obstacle confirmed - scan and redirect
      avoidObstacle(shouldRun);
      // After avoidance, reset lastCmd so the next Firebase poll re-executes cleanly
      lastCmd = "";
    }
  } else {
    // Path clear - run forward if autonomous mode active; else stay stopped
    if (shouldRun && WiFi.status() != WL_CONNECTED) {
      // Only auto-drive in offline mode; online mode is driven by Firebase cmd polling
      motorsForward();
    }
    // Online mode movement is fully handled by executeMotorCommand() via pollMotorCommand()
  }

  delay(100); // Stabilize ultrasonic readings
}