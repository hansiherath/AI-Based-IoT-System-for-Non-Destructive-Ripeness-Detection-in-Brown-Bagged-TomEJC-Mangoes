#include <Wire.h>
#include <WiFi.h>
#include <HTTPClient.h>

#include <HX711.h>
#include <AS726X.h>
#include <bme68xLibrary.h>
#include <MPU6050.h>
#include <ESP32Servo.h>

#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#include <math.h>
#include "esp_task_wdt.h"


#include <WebServer.h>
#include <ArduinoJson.h>

//////////////////////////////////////////////////////////
// OLED CONFIG
//////////////////////////////////////////////////////////

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

//////////////////////////////////////////////////////////
// WIFI
//////////////////////////////////////////////////////////

const char* ssid = "Tharu";
const char* password = "tharu2206";

const char* predictURL = "http://10.40.14.179:3000/predict";
const char* statusURL  = "http://10.40.14.179:3000/device/status";

//////////////////////////////////////////////////////////
// NEW GLOBALS (ADDED)
//////////////////////////////////////////////////////////

WebServer server(80);

int userId = 0;
int mangoId = 0;

//////////////////////////////////////////////////////////
// PINS
//////////////////////////////////////////////////////////

#define SDA_PIN 21
#define SCL_PIN 22
#define HX_DT 4
#define HX_SCK 5
#define SERVO_PIN 18

//////////////////////////////////////////////////////////
// ERROR CODES
//////////////////////////////////////////////////////////

#define ERR_NO_MANGO "NO_MANGO"
#define ERR_BAD_PLACEMENT "BAD_PLACEMENT"
#define ERR_NIR_FAIL "NIR_SENSOR_FAIL"
#define ERR_VOC_WARM "VOC_WARMING"

//////////////////////////////////////////////////////////
// SENSOR STATUS
//////////////////////////////////////////////////////////

bool hx_status=false;
bool nir_status=false;
bool bme_status=false;
bool mpu_status=false;

unsigned long lastStatusSend=0;

//////////////////////////////////////////////////////////
// HX711
//////////////////////////////////////////////////////////

HX711 scale;
float calibration_factor = 1802.0;

//////////////////////////////////////////////////////////
// AS7263
//////////////////////////////////////////////////////////

AS726X nir;

//////////////////////////////////////////////////////////
// BME688
//////////////////////////////////////////////////////////

Bme68x bme;
bme68xData bmeData;

//////////////////////////////////////////////////////////
// MPU6050
//////////////////////////////////////////////////////////

MPU6050 mpu;
Servo tapper;

#define TAP_POINTS 4
#define SAMPLE_COUNT 60

#define ACC_SENS 16384.0
#define GRAVITY 9.81

#define DATASET_MIN_KG 4.78
#define DATASET_MAX_KG 12.09

//////////////////////////////////////////////////////////
// DATA VARIABLES
//////////////////////////////////////////////////////////

float Weight_g;

float nir_610;
float nir_680;
float nir_730;
float nir_760;
float nir_810;
float nir_860;

float aromaIndex;
float gasResistance;
float firmnessKg;

float baselineGas = 20000;

void handleSetIds() {

  if (server.hasArg("plain")) {

    String body = server.arg("plain");

    Serial.println("📥 Received from Mobile:");
    Serial.println(body);

    DynamicJsonDocument doc(200);
    deserializeJson(doc, body);

    userId = doc["userId"];
    mangoId = doc["mangoId"];

    Serial.print(" UserID: ");
    Serial.println(userId);

    Serial.print(" MangoID: ");
    Serial.println(mangoId);

    server.send(200, "application/json", "{\"status\":\"ok\"}");
  }
  else {
    server.send(400, "text/plain", "No data");
  }
}

//////////////////////////////////////////////////////////
// SCAN CONTROL
//////////////////////////////////////////////////////////

unsigned long lastScan = 0;
unsigned long scanInterval = 3000;

//////////////////////////////////////////////////////////
// WIFI RECONNECT
//////////////////////////////////////////////////////////

void checkWiFi()
{
 if(WiFi.status()==WL_CONNECTED) return;

 Serial.println("WiFi reconnecting...");

 WiFi.disconnect();
 WiFi.begin(ssid,password);

 int attempt=0;

 while(WiFi.status()!=WL_CONNECTED && attempt<20)
 {
  delay(500);
  attempt++;
 }
}

//////////////////////////////////////////////////////////
// SEND ERROR
//////////////////////////////////////////////////////////

void sendError(const char* code)
{
 if(WiFi.status()!=WL_CONNECTED) return;

 HTTPClient http;

 http.begin(predictURL);
 http.addHeader("Content-Type","application/json");

 char json[128];

 snprintf(json,sizeof(json),
 "{\"status\":\"error\",\"code\":\"%s\"}",code);

 http.POST(json);
 http.end();
}

//////////////////////////////////////////////////////////
// SENSOR STATUS API
//////////////////////////////////////////////////////////

void sendSensorStatus()
{
 if(WiFi.status()!=WL_CONNECTED) return;

 HTTPClient http;

 http.begin(statusURL);
 http.addHeader("Content-Type","application/json");

 char json[200];

 snprintf(json,sizeof(json),
 "{\"device_id\":\"mango_device_01\",\"AS7263\":\"%s\",\"BME688\":\"%s\",\"MPU6050\":\"%s\",\"HX711\":\"%s\"}",
 nir_status?"active":"inactive",
 bme_status?"active":"inactive",
 mpu_status?"active":"inactive",
 hx_status?"active":"inactive");

 http.POST(json);
 http.end();
}

//////////////////////////////////////////////////////////
// WEIGHT
//////////////////////////////////////////////////////////

float readWeight()
{
 long raw = scale.read_average(10);

 float weight = (raw - scale.get_offset()) / calibration_factor;

 if(weight < 0) weight = 0;

 return weight;
}

//////////////////////////////////////////////////////////
// READ NIR
//////////////////////////////////////////////////////////

bool readNIR()
{
 nir.takeMeasurements();

 nir_610 = nir.getCalibratedR();
 nir_680 = nir.getCalibratedS();
 nir_730 = nir.getCalibratedT();
 nir_760 = nir.getCalibratedU();
 nir_810 = nir.getCalibratedV();
 nir_860 = nir.getCalibratedW();

 if(isnan(nir_610) || isnan(nir_680))
  return false;

 return true;
}

//////////////////////////////////////////////////////////
// READ VOC
//////////////////////////////////////////////////////////

bool readVOC()
{
 bme.setOpMode(BME68X_FORCED_MODE);
 delay(150);

 if(!bme.fetchData()) return false;

 bme.getData(bmeData);

 gasResistance = bmeData.gas_resistance;

 float delta = baselineGas - gasResistance;

 if(delta < 0) delta = 0;

 aromaIndex = (delta / baselineGas) * 500;

 if(aromaIndex > 500) aromaIndex = 500;

 return true;
}

//////////////////////////////////////////////////////////
// FIRMNESS
//////////////////////////////////////////////////////////

float measureFirmnessPoint()
{
 int16_t ax,ay,az;

 mpu.getAcceleration(&ax,&ay,&az);

 float baseline = (az / ACC_SENS) * GRAVITY;

 delay(150);

 tapper.write(25);
 delay(70);
 tapper.write(0);
 delay(120);

 float peak = 0;
 float sumsq = 0;

 for(int i=0;i<SAMPLE_COUNT;i++)
 {
  mpu.getAcceleration(&ax,&ay,&az);

  float accel = (az / ACC_SENS) * GRAVITY;
  float vib = fabs(accel - baseline);

  if(vib > peak) peak = vib;

  sumsq += vib * vib;

  delay(2);
 }

 float rms = sqrt(sumsq / SAMPLE_COUNT);

 float peak_norm = peak/(peak+1);
 float rms_norm = rms/(rms+1);

 return 0.6*peak_norm + 0.4*rms_norm;
}

float readFirmness()
{
 float sum=0;

 for(int i=0;i<TAP_POINTS;i++)
 {
  Serial.print("Tap point ");
  Serial.println(i+1);

  sum += measureFirmnessPoint();

  if(i < TAP_POINTS-1)
  {
   Serial.println("Rotate mango...");
   delay(4000);
  }
 }

 float avg = sum/TAP_POINTS;

 return DATASET_MIN_KG + avg*(DATASET_MAX_KG - DATASET_MIN_KG);
}

//////////////////////////////////////////////////////////
// SEND DATASET
//////////////////////////////////////////////////////////

void sendToBackend()
{
 if(WiFi.status()!=WL_CONNECTED) return;

 HTTPClient http;

 http.begin(predictURL);
 http.addHeader("Content-Type","application/json");

 char json[512];

snprintf(json,sizeof(json),
"{\"userId\":%d,"
"\"mangoId\":%d,"
"\"weight_g\":%.2f,"  
"\"AS7263_610nm\":%.2f,"
"\"AS7263_680nm\":%.2f,"
"\"AS7263_730nm\":%.2f,"
"\"AS7263_760nm\":%.2f,"
"\"AS7263_810nm\":%.2f,"
"\"AS7263_860nm\":%.2f,"
"\"BME688_Aroma_Index_0_500\":%.2f,"
"\"BME688_Gas_Resistance_Ohm\":%.0f,"
"\"Firmness_Average_Kg\":%.2f}",
userId,
mangoId,
Weight_g,
nir_610,
nir_680,
nir_730,
nir_760,
nir_810,
nir_860,
aromaIndex,
gasResistance,
firmnessKg);

 http.POST(json);
 http.end();
}

//////////////////////////////////////////////////////////
// SETUP
//////////////////////////////////////////////////////////

void setup()
{
 Serial.begin(115200);
 delay(2000);

 Wire.begin(SDA_PIN,SCL_PIN);

 // OLED INIT
 display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
 display.clearDisplay();
 display.setTextSize(2);
 display.setTextColor(WHITE);
 display.setCursor(0,10);
 display.println("Starting...");
 display.display();
 delay(1000);

 WiFi.begin(ssid,password);
 while(WiFi.status()!=WL_CONNECTED) delay(500);

 Serial.print("ESP32 IP: ");
 Serial.println(WiFi.localIP());

//  START SERVER
 server.on("/set-ids", HTTP_POST, handleSetIds);
 server.begin();

 scale.begin(HX_DT,HX_SCK);
 scale.tare();
 hx_status = scale.is_ready();

 nir_status = nir.begin();

 if(nir_status)
 {
  nir.setGain(3);
  nir.setIntegrationTime(150);
  nir.enableBulb();
 }

 bme.begin(BME68X_I2C_ADDR_LOW,Wire);
 bme.setTPH(BME68X_OS_2X,BME68X_OS_2X,BME68X_OS_2X);
 bme.setHeaterProf(320,150);

 bme_status=true;

 mpu.initialize();
 mpu_status=mpu.testConnection();

 tapper.attach(SERVO_PIN);
 tapper.write(0);

 Serial.println("SYSTEM READY");
}

//////////////////////////////////////////////////////////
// LOOP
//////////////////////////////////////////////////////////

void loop()
{

//  NEW (REQUIRED for receiving data from mobile)
  server.handleClient();
  checkWiFi();

  if(millis() - lastStatusSend > 20000)
  {
    sendSensorStatus();
    lastStatusSend = millis();
  }

  if(millis() - lastScan < scanInterval) return;

  lastScan = millis();

  Serial.println("\n----- NEW SCAN -----");

  Weight_g = readWeight();

  Serial.print("Weight: ");
  Serial.println(Weight_g);

  // OLED DISPLAY UPDATE
  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(0,0);
  display.println("Weight:");
  display.setTextSize(3);
  display.setCursor(0,30);
  display.print(Weight_g,1);
  display.println(" g");
  display.display();

  if(Weight_g < 100)
  {
    Serial.println("NO MANGO");
    sendError(ERR_NO_MANGO);
    return;
  }

  if(!readNIR())
  {
    Serial.println("NIR ERROR");
    sendError(ERR_NIR_FAIL);
    return;
  }

  Serial.println("NIR VALUES");
  Serial.print("AS7263_610nm: "); Serial.println(nir_610);
  Serial.print("AS7263_680nm: "); Serial.println(nir_680);
  Serial.print("AS7263_730nm: "); Serial.println(nir_730);
  Serial.print("AS7263_760nm: "); Serial.println(nir_760);
  Serial.print("AS7263_810nm: "); Serial.println(nir_810);
  Serial.print("AS7263_860nm: "); Serial.println(nir_860);

  if(!readVOC())
  {
    Serial.println("VOC ERROR");
  }

  Serial.print("BME688_Gas_Resistance_Ohm: ");
  Serial.println(gasResistance);

  Serial.print("BME688_Aroma_Index_0_500: ");
  Serial.println(aromaIndex);

  firmnessKg = readFirmness();

  Serial.print("Firmness_Average_Kg: ");
  Serial.println(firmnessKg);

  sendToBackend();

  Serial.println("SCAN COMPLETE");
}