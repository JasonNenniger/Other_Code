#include "pitches.h"
boolean hit = false;
int thisNote = 0, value = 0;

int Octave0[12] = {NOTE_B0};
int Octave1[12] = {NOTE_C1, NOTE_CS1, NOTE_D1, NOTE_DS1, NOTE_E1, NOTE_F1, NOTE_FS1, NOTE_G1, NOTE_GS1, NOTE_A1, NOTE_AS1, NOTE_B1};
int Octave2[12] = {NOTE_C2, NOTE_CS2, NOTE_D2, NOTE_DS2, NOTE_E2, NOTE_F2, NOTE_FS2, NOTE_G2, NOTE_GS2, NOTE_A2, NOTE_AS2, NOTE_B2};
int Octave3[12] = {NOTE_C3, NOTE_CS3, NOTE_D3, NOTE_DS3, NOTE_E3, NOTE_F3, NOTE_FS3, NOTE_G3, NOTE_GS3, NOTE_A3, NOTE_AS3, NOTE_B3};
int Octave4[12] = {NOTE_C4, NOTE_CS4, NOTE_D4, NOTE_DS4, NOTE_E4, NOTE_F4, NOTE_FS4, NOTE_G4, NOTE_GS4, NOTE_A4, NOTE_AS4, NOTE_B4};
int Octave5[12] = {NOTE_C5, NOTE_CS5, NOTE_D5, NOTE_DS5, NOTE_E5, NOTE_F5, NOTE_FS5, NOTE_G5, NOTE_GS5, NOTE_A5, NOTE_AS5, NOTE_B5};
int Octave6[12] = {NOTE_C6, NOTE_CS6, NOTE_D6, NOTE_DS6, NOTE_E6, NOTE_F6, NOTE_FS6, NOTE_G6, NOTE_GS6, NOTE_A6, NOTE_AS6, NOTE_B6};
int Octave7[12] = {NOTE_C7, NOTE_CS7, NOTE_D7, NOTE_DS7, NOTE_E7, NOTE_F7, NOTE_FS7, NOTE_G7, NOTE_GS7, NOTE_A7, NOTE_AS7, NOTE_B7};
int Octave8[12] = {NOTE_C8, NOTE_CS8, NOTE_D8, NOTE_DS8};

//int melody[12] = {NOTE_A4, NOTE_AS4, NOTE_B4, NOTE_C5, NOTE_CS5, NOTE_D5, NOTE_DS5, NOTE_E5, NOTE_F5, NOTE_FS5, NOTE_G5, NOTE_GS5};
int noteDurations[12] = {4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4};

void setup() {

}

void loop() {
  for(int i = 0; i < 12; i++) {
    if(analogRead(i) > 100 && analogRead(i) > value) {
      value = analogRead(i);
      hit = true;
      thisNote = i;
    }
  }
  if (hit == true) {
    int noteDuration = 1000/noteDurations[thisNote];
    tone(8, Octave4[thisNote],noteDuration);
    int pauseBetweenNotes = noteDuration * 1.30;
    delay(pauseBetweenNotes);
    noTone(8);
    hit = false;  
    thisNote = 0;
    value = 0;
  }
}


