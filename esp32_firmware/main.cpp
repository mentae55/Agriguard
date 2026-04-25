#include <Arduino.h>
#include <WiFi.h>
#include <Preferences.h>        // حفظ WiFi credentials في الذاكرة الدائمة
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Firebase_ESP_Client.h>

// =============================================================================
// --- Configuration ---
// =============================================================================
#define FIREBASE_HOST "https://agriguard-ca00b-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "f4a9cpr7svLSmn37lXkshcCdcu8grY92ERP1SpT9"
#define RELAY_PIN    5
#define STATUS_LED   2

// مفاتيح حفظ البيانات في الذاكرة الدائمة (NVS)
#define PREF_NAMESPACE "agriguard"
#define PREF_SSID      "ssid"
#define PREF_PASS      "pass"
#define PREF_MAC       "mac"

// =============================================================================
// --- BLE UUIDs ---
// =============================================================================
#define SERVICE_UUID         "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CRED_WRITE_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define WIFI_LIST_CHAR_UUID  "c865921c-29b1-11ee-be56-0242ac120002"
#define CMD_WRITE_CHAR_UUID  "beb5483e-36e1-4688-b7f5-ea07361b26aa"

// =============================================================================
// --- Global Variables ---
// =============================================================================
FirebaseData fbdo;
FirebaseData fbdoOnDisconnect; // مخصص للـ onDisconnect فقط
FirebaseConfig fbConfig;
FirebaseAuth fbAuth;
Preferences prefs;             // للتخزين الدائم

BLECharacteristic* pListCharacteristic = nullptr;

String bleBuffer     = "";
String targetSSID    = "";
String targetPass    = "";
String deviceSerial  = ""; // MAC بدون colons
String deviceMacFull = ""; // MAC مع colons للـ Firebase

bool startWifi    = false;
bool fbInit       = false;
bool bleActive    = true;  // هل BLE لازم يشتغل

unsigned long lastFirebaseCheck = 0;
const unsigned long FIREBASE_CHECK_INTERVAL = 2000;

// =============================================================================
// --- Helper: MAC بدون colons → مع colons ---
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
// --- Helper: حفظ Credentials في الذاكرة الدائمة ---
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
// --- Helper: قراءة Credentials من الذاكرة الدائمة ---
// =============================================================================
bool loadCredentials() {
  prefs.begin(PREF_NAMESPACE, true); // read-only
  targetSSID    = prefs.getString(PREF_SSID, "");
  targetPass    = prefs.getString(PREF_PASS, "");
  deviceSerial  = prefs.getString(PREF_MAC,  "");
  prefs.end();

  if (targetSSID.isEmpty() || deviceSerial.isEmpty()) {
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
// --- BLE Callback: CMD (SCAN_WIFI) ---
// =============================================================================
class CmdCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) {
    String cmd = String(pChar->getValue().c_str());
    cmd.trim();
    Serial.println("CMD: " + cmd);
    if (cmd == "SCAN_WIFI" && pListCharacteristic != nullptr) {
      String nets = scanNetworks();
      pListCharacteristic->setValue(nets.c_str());
      pListCharacteristic->notify();
    }
  }
};

// =============================================================================
// --- BLE Callback: Credentials (SSID,Pass,Serial\n) ---
// =============================================================================
class CredCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) {
    String value = String(pChar->getValue().c_str());
    if (value.length() > 0) {
      bleBuffer += value;
      if (bleBuffer.indexOf('\n') != -1) {
        bleBuffer.trim();
        Serial.println("Received: [" + bleBuffer + "]");

        int c1 = bleBuffer.indexOf(',');
        int c2 = bleBuffer.lastIndexOf(',');

        if (c1 != -1 && c2 != -1 && c1 != c2) {
          targetSSID   = bleBuffer.substring(0, c1);
          targetPass   = bleBuffer.substring(c1 + 1, c2);
          deviceSerial = bleBuffer.substring(c2 + 1);
          deviceMacFull = addColonsToMac(deviceSerial);

          Serial.println("Parsed → SSID: " + targetSSID + " | MAC: " + deviceMacFull);

          // ✅ حفظ في الذاكرة الدائمة فوراً
          saveCredentials(targetSSID, targetPass, deviceSerial);

          startWifi = true;
        }
        bleBuffer = "";
      }
    }
  }
};

// =============================================================================
// --- Firebase Presence ---
// ✅ الـ Flow:
//   1. ESP32 يتصل بـ Firebase → يبعت online = true
//   2. يسجل على السيرفر: "لو اتقطعت، حط online = false أتوماتيك"
//   3. لما الـ ESP32 ينقطع (restart/power off/WiFi loss) →
//      Firebase Server نفسه يكتب online = false بدون ما الـ ESP32 يعمل حاجة
// =============================================================================
void setupFirebasePresence() {
  String onlinePath = "/Devices/" + deviceMacFull + "/online";

  // خطوة 1: سجّل onDisconnect قبل ما تكتب true
  // (عشان لو انقطعت قبل ما تكتب، Firebase Server عنده الأمر)
  if (Firebase.RTDB.setDisconnectBool(&fbdoOnDisconnect, onlinePath.c_str(), false)) {
    Serial.println("onDisconnect registered: online → false on disconnect ✅");
  } else {
    Serial.println("onDisconnect Error: " + fbdoOnDisconnect.errorReason());
  }

  // خطوة 2: دلوقتي اكتب online = true (الجهاز متصل فعلاً)
  if (Firebase.RTDB.setBool(&fbdo, onlinePath.c_str(), true)) {
    Serial.println("Firebase: online = true ✅");
  } else {
    Serial.println("Firebase setBool Error: " + fbdo.errorReason());
  }

  Serial.println("Presence setup complete for: " + deviceMacFull);
}

// =============================================================================
// --- Setup ---
// =============================================================================
void setup() {
  Serial.begin(115200);
  Serial.println("\n=== AgriGuard Boot ===");

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  pinMode(STATUS_LED, OUTPUT);

  // ===== حاول تحمل الـ credentials المحفوظة =====
  bool hasSavedCreds = loadCredentials();

  if (hasSavedCreds) {
    // ✅ عنده credentials محفوظة → اتصل بـ WiFi مباشرة بدون BLE
    Serial.println("Found saved credentials. Connecting to WiFi directly...");
    WiFi.begin(targetSSID.c_str(), targetPass.c_str());
    // BLE مش هيبدأ (مش محتاجينه)
    bleActive = false;
  } else {
    // ❌ مفيش credentials → شغّل BLE عشان التطبيق يبعت
    Serial.println("No saved creds. Starting BLE...");
    bleActive = true;
    _startBLE();
  }
}

// =============================================================================
// --- BLE Init (منفصلة عشان نقدر نناديها من setup) ---
// =============================================================================
void _startBLE() {
  BLEDevice::init("AgriGuard_Robot");
  BLEServer*  pServer  = BLEDevice::createServer();
  BLEService* pService = pServer->createService(SERVICE_UUID);

  // Characteristic 1: استلام الـ Credentials
  BLECharacteristic* pCredChar = pService->createCharacteristic(
    CRED_WRITE_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCredChar->setCallbacks(new CredCallbacks());

  // Characteristic 2: إرسال قائمة الشبكات
  pListCharacteristic = pService->createCharacteristic(
    WIFI_LIST_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pListCharacteristic->addDescriptor(new BLE2902());
  pListCharacteristic->setValue("Waiting...");

  // Characteristic 3: CMD (SCAN_WIFI)
  BLECharacteristic* pCmdChar = pService->createCharacteristic(
    CMD_WRITE_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCmdChar->setCallbacks(new CmdCallbacks());

  pService->start();
  BLEDevice::startAdvertising();
  Serial.println("BLE started: AgriGuard_Robot");
}

// =============================================================================
// --- Loop ---
// =============================================================================
void loop() {
  // LED بيبرق
  digitalWrite(STATUS_LED, (millis() / 500) % 2);

  // ===== اتصل بـ WiFi لو الـ flag اتضبط من BLE =====
  if (startWifi) {
    startWifi = false;
    Serial.println("Connecting to WiFi: " + targetSSID);
    WiFi.disconnect(true);
    WiFi.begin(targetSSID.c_str(), targetPass.c_str());
  }

  // ===== Firebase لما WiFi يتصل =====
  if (WiFi.status() == WL_CONNECTED) {
    if (!fbInit) {
      fbInit = true;
      Serial.println("WiFi Connected! IP: " + WiFi.localIP().toString());

      fbConfig.database_url               = FIREBASE_HOST;
      fbConfig.signer.tokens.legacy_token = FIREBASE_AUTH;
      Firebase.begin(&fbConfig, &fbAuth);
      Firebase.reconnectWiFi(true);

      // ✅ إعداد الـ Presence (online = true الآن، false لو انقطع)
      setupFirebasePresence();
    }

    // قراءة الـ relay status كل 2 ثانية
    if (Firebase.ready() && (millis() - lastFirebaseCheck > FIREBASE_CHECK_INTERVAL)) {
      lastFirebaseCheck = millis();
      String statusPath = "/Devices/" + deviceMacFull + "/status";
      if (Firebase.RTDB.getInt(&fbdo, statusPath.c_str())) {
        digitalWrite(RELAY_PIN, fbdo.intData() == 1 ? HIGH : LOW);
      }
    }

  } else if (fbInit) {
    // WiFi انقطع بعد ما كان متصل
    // Firebase سيعيد الاتصال تلقائياً بفضل Firebase.reconnectWiFi(true)
  }
}
