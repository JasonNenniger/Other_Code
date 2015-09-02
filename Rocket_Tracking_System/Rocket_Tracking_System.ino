/*

Rocket Tracking System Code
Jason Nenniger


*/

//------------------------------------LIBRARIES---------------------------------

#include <Adafruit_BMP085.h>                                                                                                                                   //Altimeter Library
#include <ADXL345.h>                                                                                                                                           //Accelerometer Library
#include <HMC5883L.h>                                                                                                                                          //Magnetometer Library
#include <L3G.h>                                                                                                                                               //Gyroscope Library
#include <SPI.h>                                                                                                                                               //SPI Library
#include <SD.h>                                                                                                                                                //SD Card Library
#include <Time.h>                                                                                                                                              //Real Time Clock Library
#include <TinyGPS.h>                                                                                                                                           //GPS Library
#include <Wire.h>                                                                                                                                              //Wire Library

//------------------------------------VARIABLES---------------------------------


#define TIME_HEADER  "T"   

int accelx, accely, accelz, error = 0, gyrogx, gyrogy, gyrogz, counter1 = 0, counter2 = 0;
float accelxg, accelyg, accelzg, temperature, pressure, Altitude, realAltitude, rawXAxis, rawYAxis,rawZAxis, scaledXAxis, scaledYAxis, scaledZAxis, heading, headingDegrees;
char alpha;
const int chipSelect = 4, cardDetect = A8;
File dataFile, gpsFile;

static void gpsdump(TinyGPS &gps);
static bool feedgps();
static void print_float(float val, float invalid, int len, int prec);
static void print_int(unsigned long val, unsigned long invalid, int len);
static void print_date(TinyGPS &gps);
static void print_str(const char *str, int len);

//--------------------------SENSOR DECLARATIONS---------------------------------

Adafruit_BMP085 bmp;                                                                                                                                           //Define the bmp variable
ADXL345 adxl;                                                                                                                                                  //Define the ADXL345 variable
HMC5883L compass;                                                                                                                                              //Define the compass variable
L3G gyro;                                                                                                                                                      //Define the gyro variable
TinyGPS gps;                                                                                                                                                   //Define the gps variable

//------------------------------------VOID SETUP--------------------------------

void setup() {
  Serial2.begin(9600);                                                                                                                                         //Start Serial communications
  setupLED();                                                                                                                                                  //Void setup for the LED's
  setupAccelerometer();                                                                                                                                        //Void Setup for the Accelerometer
  setupAltimeter();                                                                                                                                            //Void setup for the Altimeter
  setupHMC5883L();                                                                                                                                             //Void setup for the Magnetometer
  setupRTC();                                                                                                                                                  //Void setup for the Real Time Clock
  setupL3G();                                                                                                                                                  //Void setup for the Gyroscope
  setupSD();                                                                                                                                                   //Void setup for the SD Card
  setupGPS();                                                                                                                                                  //Void setup for the GPS
  
}

//------------------------------------VOID LOOP---------------------------------

void loop() {
  digitalWrite(20, HIGH);                                                                                                                                      //Turn on the green LED to indicate that it is in void loop and working 
  dataFile = SD.open("D150827.txt", FILE_WRITE);                                                                                                               //Open up the Data file write to it
  loopRTC();                                                                                                                                                   //Void loop for the real time clock
  loopAccelerometer();                                                                                                                                         //Void loop for the Accelerometer
  loopAltimeter();                                                                                                                                             //Void loop for the Altimeter
  loopHMC5883L();                                                                                                                                              //Void loop for the Magnetometer
  loopL3G();                                                                                                                                                   //Void loop for the Gyroscope
  dataFile.close();                                                                                                                                            //Close the datafile and save it
  gpsFile = SD.open("G150827.txt", FILE_WRITE);                                                                                                                //Open the GPS file and write to it
  loopGPS();                                                                                                                                                   //Void loop for the GPS
  gpsFile.close();                                                                                                                                             //Close the GPSfile and save it
}

//--------------------------VOID SETUP LED---------------------------------------

void setupLED() {
  pinMode(21, OUTPUT);                                                                                                                                         //Declare the red LED as a output
  pinMode(20, OUTPUT);                                                                                                                                         //Declare the green LED as a output
  while(analogRead(cardDetect) > 100) {                                                                                                                        //While no SD Card is inserted
    digitalWrite(21, HIGH);                                                                                                                                    //Turn the red LED on
    delay(100);                                                                                                                                                //Wait 100 miliseconds
    digitalWrite(21, LOW);                                                                                                                                     //Turn the red LED off
    delay(100);                                                                                                                                                //Wait 100 miliseconds
  }
}

//--------------------------VOID SETUP ACCELEROMETER------------------------------

void setupAccelerometer (){
  adxl.powerOn();                                                                                                                                              //Turn on the accelerometer
  adxl.setActivityThreshold(75);                                                                                                                               //Set the activity threshold to 75
  adxl.setInactivityThreshold(255);                                                                                                                            //Set the inactivity threshold to 255
  adxl.setTimeInactivity(3600);                                                                                                                                //Set the time inactivity threshold to 3600
  adxl.setActivityX(1);                                                                                                                                        //Turn on the Accelerometer X-axis
  adxl.setActivityY(1);                                                                                                                                        //Turn on the Accelerometer Y-axis
  adxl.setActivityZ(1);                                                                                                                                        //Turn on the Accelerometer Z-axis
}

//--------------------------VOID SETUP ALTIMETER-----------------------------------

void setupAltimeter() {
  bmp.begin();                                                                                                                                                 //Start the Altimeter
}

//--------------------------VOID SETUP MAGNETOMETER--------------------------------

void setupHMC5883L() {
  compass = HMC5883L();                                                                                                                                        //Declare the compass variable
  error = compass.SetScale(1.3);                                                                                                                               //Declare the error variable
  error = compass.SetMeasurementMode(Measurement_Continuous);                                                                                                  //Declare the error variable
}

//--------------------------VOID SETUP RTC-----------------------------------------

void setupRTC()  {
  Serial.begin(9600);                                                                                                                                          //Start serial communications
  setSyncProvider(getTeensy3Time);                                                                                                                             //Set the time on the Real Time clock if needed
  if (timeStatus()!= timeSet) {                                                                                                                                //If the time has not been set
    while(!SD.begin(chipSelect)) {                                                                                                                             //Start the SD card using the chipSelect pin
      digitalWrite(20, HIGH);                                                                                                                                  //Turn digital pin 20 on
      digitalWrite(21, HIGH);                                                                                                                                  //Turn digital pin 21 on
      delay(100);                                                                                                                                              //Delay 100 miliseconds
      digitalWrite(21, LOW);                                                                                                                                   //Turn digital pin 21 off
      delay(100);                                                                                                                                              //Delay 100 miliseconds
    }
  }
}

//--------------------------VOID SETUP GYROSCOPE-----------------------------------

void setupL3G() {
  if (!gyro.init()) {                                                                                                                                          //If the gyroscope i1s not initialized
    while(!gyro.init()) {                                                                                                                                      //While the gyroscope is not initialized
      digitalWrite(21, HIGH);                                                                                                                                  //Turn digital pin 21 on
      delay(100);                                                                                                                                              //Delay 100 miliseconds
      digitalWrite(21, LOW);                                                                                                                                   //Turn digital pin 21 off
      digitalWrite(20, HIGH);                                                                                                                                  //Turn digital pin 20 on
      delay(100);                                                                                                                                              //Delay 100 miliseconds
      digitalWrite(20, LOW);                                                                                                                                   //Turn digital pin 20 off
    }
  }
  gyro.enableDefault();                                                                                                                                        //Enable default settings on the gyroscope
}

//--------------------------VOID SETUP SD CARD-------------------------------------

void setupSD() {
  pinMode(10, OUTPUT);                                                                                                                                         //Declare pin 10 as an output
  if (!SD.begin(chipSelect)) {                                                                                                                                 //If the SD Card is not initialized
    while(!SD.begin(chipSelect)) {                                                                                                                             //While the SD Card is not initialized
      digitalWrite(21, HIGH);                                                                                                                                  //Turn digital pin 21 on
      delay(500);                                                                                                                                              //Delay 500 miliseconds
      digitalWrite(21, LOW);                                                                                                                                   //Turn digital pin 21 off
      digitalWrite(20, HIGH);                                                                                                                                  //Turn digital pin 20 on
      delay(500);                                                                                                                                              //Delay 500 miliseconds
      digitalWrite(20, LOW);                                                                                                                                   //Turn digital pin 20 off
    }
    return;                                                                                                                                                    //Exit the loop
  }
  SD.remove("D150827.txt");                                                                                                                                    //Remove any old versions of the data file
  SD.remove("G150827.txt");                                                                                                                                    //Remove any old versions of the gps file
}

//--------------------------VOID SETUP GPS------------------------------------------

void setupGPS() {                                                                                         
  gpsFile = SD.open("G150827.txt", FILE_WRITE);                                                                                                                //Open the gps file and prepare to write to it
  gpsFile.println("Latitude Longitude   Date       Time        Alt   Course Speed Card  Distance Course Card ");                                               //Add a header to the top of the gps file
  gpsFile.println("(deg)    (deg)                              (m)   --- from GPS ----  ---- to Calgary ---- ");                                               //Add a header to the top of the gps file
  gpsFile.println("------------------------------------------------------------------------------------------");                                               //Add a header to the top of the gps file
  gpsFile.close();                                                                                                                                             //Close the gps file and save what has been written to it
}

//--------------------------VOID LOOP RTC------------------------------------------

void loopRTC() {
  if (Serial.available()) {                                                                                                                                    //If serial communications are available
    time_t t = processSyncMessage();                                                                                                                           //Read the time 
    if (t != 0) {                                                                                                                                              //If t does not equal 0
      Teensy3Clock.set(t);                                                                                                                                     //Set the RTC
      setTime(t);                                                                                                                                              //Set the time
    }
  }
  digitalClockDisplay();                                                                                                                                       //Print the time to the data file
}

void digitalClockDisplay() {
  dataFile.print(hour());                                                                                                                                      //Print the hour to the data file
  printDigits(minute());                                                                                                                                       //Print the minute to the data file
  printDigits(second());                                                                                                                                       //Print the second to the data file
  dataFile.print(" ");                                                                                                                                         //Print a space
  dataFile.print(day());                                                                                                                                       //Print the day to the data file
  dataFile.print(" ");                                                                                                                                         //Print a space
  dataFile.print(month());                                                                                                                                     //Print the month to the data file
  dataFile.print(" ");                                                                                                                                         //Print a space
  dataFile.print(year());                                                                                                                                      // Print the year to the data file
}

time_t getTeensy3Time()
{
  return Teensy3Clock.get();                                                                                                                                   //Get the time from the RTC
}

unsigned long processSyncMessage() {
  unsigned long pctime = 0L;                                                                                                                                   //reset pctime
  const unsigned long DEFAULT_TIME = 1357041600;                                                                                                               // Jan 1 2013 

  if(Serial.find(TIME_HEADER)) {                                                                                                                               //If serial finds the time header
    pctime = Serial.parseInt();                                                                                                                                //read the pctime
    return pctime;                                                                                                                                             //Return pctime
    if( pctime < DEFAULT_TIME) {                                                                                                                               //If the pctime is older than January 1, 2013
      pctime = 0L;                                                                                                                                             //Return a error
    }
  }
  return pctime;                                                                                                                                               //return pctime
}

void printDigits(int digits){
  dataFile.print(":");                                                                                                                                         //print a colon for readability
  if(digits < 10)                                                                                                                                              //If there is less than 2 digits
    dataFile.print('0');                                                                                                                                       //Print a 0 for readability 
  dataFile.print(digits);                                                                                                                                      //Print the number
}

//--------------------------VOID LOOP ACCELEROMETER-------------------------------

void loopAccelerometer ()  {
  adxl.readAccel(&accelx, &accely, &accelz);                                                                                                                   //Read the data from the accelerometer
  accelxg = accelx * 0.0078;                                                                                                                                   //Convert the x axis accelerometer to earth g's
  accelyg = accely * 0.0078;                                                                                                                                   //Convert the y axis accelerometer to earth g's
  accelzg = accelz * 0.0078;                                                                                                                                   //Convert the z axis accelerometer to earth g's
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  dataFile.print(accelxg, DEC);                                                                                                                                //Print the x-axis accelerometer data
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  dataFile.print(accelyg, DEC);                                                                                                                                //Print the y-axis accelerometer data
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  dataFile.print(accelzg, DEC);                                                                                                                                //Print the z-axis accelerometer data
}

//--------------------------VOID LOOP ALTIMETER------------------------------------

void loopAltimeter() {
  temperature = bmp.readTemperature();                                                                                                                         //Read the temperature
  pressure = bmp.readPressure();                                                                                                                               //Read the pressure
  Altitude = bmp.readAltitude();                                                                                                                               //Read the altitude
  realAltitude = bmp.readAltitude(101500);                                                                                                                     //Read the real altitude based on ther current sea level pressure
  
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  dataFile.print(" T = ");                                                                                                                                     //Print T = to the data file
  dataFile.print(temperature);                                                                                                                                 //Print the temperature to the data file
  dataFile.print(" *C  ");                                                                                                                                     //Print *C to the data file
  dataFile.print("\t");                                                                                                                                        //Insert a tab

  dataFile.print("P = ");                                                                                                                                      //Print P = to the data file
  dataFile.print(pressure);                                                                                                                                    //Print the pressure to the data file
  dataFile.print(" Pa  ");                                                                                                                                     //Print Pa to the data file
  dataFile.print("\t");                                                                                                                                        //Insert a tab

  dataFile.print("Altitude = ");                                                                                                                               //Print Altitude = to the data file
  dataFile.print(Altitude);                                                                                                                                    //Print the altitude to the data file
  dataFile.print(" meters ");                                                                                                                                  //Print meters to the data file
  dataFile.print("\t");                                                                                                                                        //Insert a tab

  dataFile.print("Real altitude = ");                                                                                                                          //Print Real altitude = to the data file 
  dataFile.print(realAltitude);                                                                                                                                //Print the real altitude to the data file
  dataFile.print(" meters");                                                                                                                                   //Print meters to the data file
}

//--------------------------VOID LOOP MAGNETOMETER---------------------------------

void loopHMC5883L() {
  MagnetometerRaw raw = compass.ReadRawAxis();                                                                                                                 //Read the raw data
  MagnetometerScaled scaled = compass.ReadScaledAxis();                                                                                                        //Read the scaled data
  int MilliGauss_OnThe_XAxis = scaled.XAxis;                                                                                                                   //Calibrate the magnetometer
  heading = atan2(scaled.YAxis, scaled.XAxis);                                                                                                                 //Calculaye the heading
  float declinationAngle = 0.0457;                                                                                                                             //Declare the declination angle as a variable
  heading += declinationAngle;

  while(heading < 0)                                                                                                                                           //If the heading is less than 0
    heading += 2*PI;                                                                                                                                           //Add 2*pi to make the heading greater than 0
                                                                                                       
  while(heading > 2*PI)                                                                                                                                        //If the heading is greater than 2*pi
    heading -= 2*PI;                                                                                                                                           //Subtract 2*pi to make the heading between 0 and 2*pi

  headingDegrees = heading * 180/M_PI;                                                                                                                         //Convert the heading from radians to degrees for readability 

  rawXAxis = raw.XAxis;                                                                                                                                        //Store the raw x axis values as a variable
  rawYAxis = raw.YAxis;                                                                                                                                        //Store the raw y axis values as a variable
  rawZAxis = raw.ZAxis;                                                                                                                                        //Store the raw z axis values as a variable
  scaledXAxis = scaled.XAxis;                                                                                                                                  //Store the scaled x axis values as a variable
  scaledYAxis = scaled.YAxis;                                                                                                                                  //Store the scaled x axis values as a variable
  scaledZAxis = scaled.ZAxis;                                                                                                                                  //Store the scaled x axis values as a variable
  dataFile.print("\t");                                                                                                                                        //Insert a tab

  dataFile.print("Raw: ");                                                                                                                                     //Print Raw: to the dataFile
  dataFile.print(rawXAxis);                                                                                                                                    //Print the raw x-axis data to the dataFile
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  if(rawXAxis < 100 && rawXAxis > 0) {                                                                                                                         //If the raw x-axis value is less than 100 and greater than 0
    dataFile.print("\t");                                                                                                                                      //Insert a tab
  }
  dataFile.print(rawYAxis);                                                                                                                                    //Print the raw y-axis data to the dataFile
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  if(rawYAxis < 100 && rawYAxis > 0) {                                                                                                                         //If the raw y-axis value is less than 100 and greater than 0
    dataFile.print("\t");                                                                                                                                      //Insert a tab
  }  
  dataFile.print(rawZAxis);                                                                                                                                    //Print the raw z-axis data to the dataFile
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  if(rawZAxis < 100 && rawZAxis > 0) {                                                                                                                         //If the raw z-axis value is less than 100 and greater than 0
    dataFile.print("\t");                                                                                                                                      //Insert a tab
  }   
  dataFile.print(" Scaled: ");                                                                                                                                 //Print Scaled: to the dataFile
  dataFile.print(scaledXAxis);                                                                                                                                 //Print the scaled x-axis data to the dataFile
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  if(scaledXAxis < 100 && scaledXAxis > 0) {                                                                                                                   //If the scaled x-axis value is less than 100 and greater than 0
    dataFile.print("\t");                                                                                                                                      //Insert a tab
  }
  dataFile.print(scaledYAxis);                                                                                                                                 //Print the scaled y-axis data to the dataFile
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  if(scaledYAxis < 100 && scaledYAxis > 0) {                                                                                                                   //If the scaled y-axis value is less than 100 and greater than 0
    dataFile.print("\t");                                                                                                                                      //Insert a tab
  }
  dataFile.print(scaledZAxis);                                                                                                                                 //Print the scaled z-axis data to the dataFile
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  if(scaledZAxis < 100 && scaledZAxis > 0) {                                                                                                                   //If the scaled z-axis value is less than 100 and greater than 0
    dataFile.print("\t");                                                                                                                                      //Insert a tab
  }

  dataFile.print(" Heading: ");                                                                                                                                //Print Heading: to the dataFile
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  dataFile.print(heading);                                                                                                                                     //Print the heading data in radians to the dataFile
  dataFile.print(" Radians ");                                                                                                                                 //Print Radians to the dataFile
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  dataFile.print(headingDegrees);                                                                                                                              //Print the heading data in degrees to the dataFile
  dataFile.print(" Degrees ");                                                                                                                                 //Print Degrees to the dataFile
}

//--------------------------VOID LOOP GYROSCOPE----------------------------------

void loopL3G() {
  gyro.read();                                                                                                                                                 //Read the data from the gyroscope
  gyrogx = gyro.g.x;                                                                                                                                           //Store the x axis gyroscope data from the gyroscope as a variable
  gyrogy = gyro.g.y;                                                                                                                                           //Store the y axis gyroscope data from the gyroscope as a variable
  gyrogz = gyro.g.z;                                                                                                                                           //Store the z axis gyroscope data from the gyroscope as a variable

  dataFile.print("\tGYRO: ");                                                                                                                                  //Print GYRO: to the dataFile
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  dataFile.print("X: ");                                                                                                                                       //Print X: to the dataFile
  dataFile.print(gyrogx);                                                                                                                                      //Print the x-axis gyroscope data to the dataFile
  
  if(gyrogx < 10000) {                                                                                                                                         //If the x-axis gyroscope data is less than 10,000
    dataFile.print("\t");                                                                                                                                      //Insert a tab
  }
    
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  dataFile.print("Y: ");                                                                                                                                       //Print Y: to the dataFile
  dataFile.print(gyrogy);                                                                                                                                      //Print the y-axis gyroscope data to the dataFile
  
  if(gyrogy < 10000) {                                                                                                                                         //If the y-axis gyroscope data is less than 10,000
    dataFile.print("\t");                                                                                                                                      //Insert a tab
  }
  
  dataFile.print("\t");                                                                                                                                        //Insert a tab
  dataFile.print("Z: ");                                                                                                                                       //Print Y: to the dataFile
  dataFile.println(gyrogz);                                                                                                                                    //Print the y-axis gyroscope data to the dataFile
}

//--------------------------VOID LOOP GPS-------------------------------------------

void loopGPS() {
  bool newdata = false;                                                                                                                                        //Set newdata to false
  unsigned long start = millis();                                                                                                                              //set a time variable
  while (millis() - start < 300) {                                                                                                                             //Every 300ms print an update
    if (feedgps()) {                                                                                                                                           //If data can be read from the GPS
      newdata = true;                                                                                                                                          //Set newdata to true
    }
  }
  gpsdump(gps);                                                                                                                                                //Go to the feedgps subroutine
}

static void gpsdump(TinyGPS &gps) {
  float flat, flon;                                                                                                                                            //Variables
  unsigned long age, date, time, chars = 0;                                                                                                                    //Variables
  unsigned short sentences = 0, failed = 0;                                                                                                                    //Variables
  static const float LONDON_LAT = 51.0486, LONDON_LON = -114.0708;                                                                                             //Declare the latitude and longitude of calgary as variables
  gps.f_get_position(&flat, &flon, &age);                                                                                                                      //Get the data from the GPS
  print_float(flat, TinyGPS::GPS_INVALID_F_ANGLE, 9, 5);                                                                                                       //Print the latitude to the gpsFile
  print_float(flon, TinyGPS::GPS_INVALID_F_ANGLE, 10, 5);                                                                                                      //Print the longitude to the gpsFile
  gpsFile.print(" ");                                                                                                                                          //Print a space to the gpsFile
  print_date(gps);                                                                                                                                             //Go into the print_date subroutine and print the date to the gpsFile
  print_float(gps.f_altitude(), TinyGPS::GPS_INVALID_F_ALTITUDE, 8, 2);                                                                                        //Print the altitude to the gpsFile        
  print_float(gps.f_course(), TinyGPS::GPS_INVALID_F_ANGLE, 7, 2);                                                                                             //Print the heading to the gpsFile
  print_float(gps.f_speed_kmph(), TinyGPS::GPS_INVALID_F_SPEED, 6, 2);                                                                                         //Print the speed in kilometers per hour to the gpsFile
  print_str(gps.f_course() == TinyGPS::GPS_INVALID_F_ANGLE ? "*** " : TinyGPS::cardinal(gps.f_course()), 6);  //Print the course to the gpsFile
  print_int(flat == TinyGPS::GPS_INVALID_F_ANGLE ? 0UL : (unsigned long)TinyGPS::distance_between(flat, flon, LONDON_LAT, LONDON_LON) / 1000, 0xFFFFFFFF, 9);  //Print the distance to calgary to the gpsFile
  print_float(flat == TinyGPS::GPS_INVALID_F_ANGLE ? 0.0 : TinyGPS::course_to(flat, flon, 51.508131, -0.128002), TinyGPS::GPS_INVALID_F_ANGLE, 7, 2);          //Print the heading to calgary to the gpsPFile
  print_str(flat == TinyGPS::GPS_INVALID_F_ANGLE ? "*** " : TinyGPS::cardinal(TinyGPS::course_to(flat, flon, LONDON_LAT, LONDON_LON)), 6);                     //Print the coordinates of calgary to the gpsFile
  gps.stats(&chars, &sentences, &failed);                                                                                                                      //Record the GPS stats
  gpsFile.println();                                                                                                                                           //Go to the next line in the gpsFile
}

static void print_int(unsigned long val, unsigned long invalid, int len) {
  char sz[32];                                                                                                                                                 //Declare the sz array
  if (val == invalid) {                                                                                                                                        //If the data is invalid print an error and blink the LED's to indicate that an error has occurred
    strcpy(sz, "*******");                                                                                                                                     //Print a error to the gpsFile
    digitalWrite(20, HIGH);                                                                                                                                    //Turn on the green LED
    digitalWrite(21, HIGH);                                                                                                                                    //Turn on the red LED
    delay(100);                                                                                                                                                //delay 100 miliseconds
    digitalWrite(20, LOW);                                                                                                                                     //Turn off the green LED
    digitalWrite(21, LOW);                                                                                                                                     //Turn off the red LED
  }
  else
    sprintf(sz, "%ld", val);                                                                                                                                   //Otherwise write the data to the gpsFile
  sz[len] = 0;                                                                                                                                                 //Write 0 to the array 
  for (int i=strlen(sz); i<len; ++i)                                                                                                                           //For i=strlen(sz); i<len; ++i
    sz[i] = ' ';                                                                                                                                               //Write a space to the array
  if (len > 0)                                                                                                                                                 //If len is greater than 0                      
    sz[len-1] = ' ';                                                                                                                                           //Write a space to the array
  gpsFile.print(sz);                                                                                                                                           //Write the array to the gpsFile
  feedgps();                                                                                                                                                   //Go to the feedgps subroutine
}

static void print_float(float val, float invalid, int len, int prec)
{
  char sz[32];                                                                                                                                                 //Declare the sz array
  if (val == invalid) {                                                                                                                                        //If the data is invalid print an error and blink the LED's to indicate an error has occurred
    strcpy(sz, "*******");                                                                                                                                     //Print an error to the gpsFile
    digitalWrite(20, HIGH);                                                                                                                                    //Turn on the green LED
    digitalWrite(21, HIGH);                                                                                                                                    //Turn on the red LED
    delay(100);                                                                                                                                                //Delay 100 miliseconds
    digitalWrite(20, LOW);                                                                                                                                     //Turn off the green LED
    digitalWrite(21, LOW);                                                                                                                                     //Turn off the red LED
    sz[len] = 0;                                                                                                                                               //Write a 0 to the array
        if (len > 0)                                                                                                                                           //If len is greater than 0
          sz[len-1] = ' ';                                                                                                                                     //Write a space to the array
    for (int i=7; i<len; ++i)                                                                                                                                  //For int i=7; i<len; ++i
        sz[i] = ' ';                                                                                                                                           //Write a space to the array
    gpsFile.print(sz);                                                                                                                                         //Write the data to the gpsFile
  }
  else {
    gpsFile.print(val, prec);                                                                                                                                  //Print data to the gpsFile
    int vi = abs((int)val);                                                                                                                                    //Declare the vi integer
    int flen = prec + (val < 0.0 ? 2 : 1);                                                                                                                     //Declare the flen integer
    flen += vi >= 1000 ? 4 : vi >= 100 ? 3 : vi >= 10 ? 2 : 1;                                                                                                 //calculate the flen integer
    for (int i=flen; i<len; ++i)                                                                                                                               //For int i=flen; i<len; ++i
      gpsFile.print(" ");                                                                                                                                      //Write a space to the gpsFile
  }
  feedgps();                                                                                                                                                   //Go to the feedgps subroutine
}

static void print_date(TinyGPS &gps) {
  int year;                                                                                                                                                    //Variables
  byte month, day, hour, minute, second, hundredths;                                                                                                           //Variables
  unsigned long age;                                                                                                                                           //Variables
  gps.crack_datetime(&year, &month, &day, &hour, &minute, &second, &hundredths, &age);                                                                         //Read the date and time from the GPS
  if (age == TinyGPS::GPS_INVALID_AGE) {                                                                                                                       //If there is an error in the date and time 
    gpsFile.print("*******    *******    ");                                                                                                                   //Print an error to the gpsFile
    digitalWrite(20, HIGH);                                                                                                                                    //Turn on the green LED
    digitalWrite(21, HIGH);                                                                                                                                    //Turn off the red LED
    delay(100);                                                                                                                                                //Delay 100 miliseconds
    digitalWrite(20, LOW);                                                                                                                                     //Turn on the green LED
    digitalWrite(21, LOW);                                                                                                                                     //Turn off the red LED
  }
  
  else {
    char sz[32];                                                                                                                                               //Otherwise declare the sz array
    sprintf(sz, "%02d/%02d/%02d %02d:%02d:%02d   ", month, day, year, hour, minute, second);                                                                   //Read the data from the GPS
    gpsFile.print(sz);                                                                                                                                         //print the date and time to the gpsFile
  }
  feedgps();                                                                                                                                                   //Go to the feedgps subroutine
}

static void print_str(const char *str, int len) {                                            
  int slen = strlen(str);                                                                                                                                      //Declare the slen variable
  for (int i=0; i<len; ++i)                                                                                                                                    //For int i=0; i<len; ++i
    gpsFile.print(i<slen ? str[i] : ' ');                                                                                                                      //Print data to the gpsFile
  feedgps();                                                                                                                                                   //Go to the feedgps subroutine
}

static bool feedgps() {
  while (Serial2.available()) {                                                                                                                                //While Serial2 is avaliable 
    if (gps.encode(Serial2.read()))                                                                                                                            //If data can be read from the GPS
      return true;                                                                                                                                             //Return the variable as true
  }
  return false;                                                                                                                                                //Otherwise return the variable as false
}

