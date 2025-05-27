#include <Wire.h>
#include <LiquidCrystal_I2C.h>

#define ENA 9
#define IN1 7
#define IN2 8
#define BTN_INC 2
#define BTN_DEC 3
#define BTN_BYPASS 5
#define RX_PIN 4

int speedValue = 0;
const int speedStep = 25;
const int receivedSpeed = 255 * 0.2; // 20% speed limit (~51)
bool speedLimited = false;
bool bypassActivated = false;

LiquidCrystal_I2C lcd(0x27, 16, 2);

unsigned long startMillis;    // track time since startup
int entryId = 1;              // incrementing entry ID for CSV rows

void setup() {
    pinMode(ENA, OUTPUT);
    pinMode(IN1, OUTPUT);
    pinMode(IN2, OUTPUT);
    pinMode(BTN_INC, INPUT_PULLUP);
    pinMode(BTN_DEC, INPUT_PULLUP);
    pinMode(BTN_BYPASS, INPUT_PULLUP);
    pinMode(RX_PIN, INPUT);

    digitalWrite(IN1, LOW);
    digitalWrite(IN2, HIGH);

    speedLimited = false;
    speedValue = 0;
    analogWrite(ENA, speedValue);

    lcd.init();
    lcd.backlight();
    updateLCD();

    Serial.begin(9600); // Start serial communication

    startMillis = millis();
}

// Helper: Send CSV line for speed log
void logSpeed(int entryId, unsigned long timestampMs, int speedPwm, bool speedLimited, bool bypassActive) {
    Serial.print(entryId); Serial.print(",");
    Serial.print(timestampMs); Serial.print(",");
    Serial.print(speedPwm); Serial.print(",");
    Serial.print(speedLimited ? "Y" : "N"); Serial.print(",");
    Serial.print(bypassActive ? "Y" : "N"); Serial.print(",");
    Serial.print(""); Serial.print(","); // empty event_type
    Serial.println("");                  // empty description
}

// Helper: Send CSV line for event log
void logEvent(int entryId, unsigned long timestampMs, const char* eventType, const char* description) {
    Serial.print(entryId); Serial.print(",");
    Serial.print(timestampMs); Serial.print(",");
    Serial.print(""); Serial.print(","); // empty speed_pwm
    Serial.print(""); Serial.print(","); // empty speed_limited
    Serial.print(""); Serial.print(","); // empty bypass_active
    Serial.print(eventType); Serial.print(",");
    Serial.println(description);
}

void loop() {
    unsigned long currentMillis = millis() - startMillis;

    // Bypass button pressed
    if (digitalRead(BTN_BYPASS) == LOW && !bypassActivated) {
        bypassActivated = true;
        speedLimited = false;
        updateLCD();
        logEvent(entryId++, currentMillis, "BypassEnabled", "Bypass button pressed");
        delay(300);
    }

    // Speed limit logic if bypass not active
    if (!bypassActivated) {
        if (digitalRead(RX_PIN) == HIGH) {
            if (!speedLimited) {
                logEvent(entryId++, currentMillis, "SpeedLimitActive", "RF signal received - limiting speed");
            }
            speedLimited = true;
            speedValue = receivedSpeed;
        } else {
            if (speedLimited) {
                logEvent(entryId++, currentMillis, "SpeedLimitInactive", "RF signal lost - manual control allowed");
            }
            speedLimited = false;
        }
    }

    analogWrite(ENA, speedValue);
    updateLCD();

    // Manual speed control allowed if no limit or bypass active
    if (!speedLimited || bypassActivated) {
        if (digitalRead(BTN_INC) == LOW) {
            increaseSpeed();
            delay(200);
        }
        if (digitalRead(BTN_DEC) == LOW) {
            decreaseSpeed();
            delay(200);
        }
    }

    // Log current speed state every 5 seconds
    static unsigned long lastLogTime = 0;
    if (currentMillis - lastLogTime >= 5000) {
        logSpeed(entryId++, currentMillis, speedValue, speedLimited, bypassActivated);
        lastLogTime = currentMillis;
    }
}

void increaseSpeed() {
    if (speedValue < 255) {
        speedValue += speedStep;
        if (speedValue > 255) speedValue = 255;
        analogWrite(ENA, speedValue);
        updateLCD();
        logEvent(entryId++, millis() - startMillis, "SpeedIncreased", "Manual speed increased");
    }
}

void decreaseSpeed() {
    if (speedValue > 0) {
        speedValue -= speedStep;
        if (speedValue < 0) speedValue = 0;
        analogWrite(ENA, speedValue);
        updateLCD();
        logEvent(entryId++, millis() - startMillis, "SpeedDecreased", "Manual speed decreased");
    }

    if (speedValue == 0) {
        digitalWrite(ENA, LOW);
    }
}

void updateLCD() {
    lcd.clear();
    lcd.setCursor(0, 0);

    if (bypassActivated) {
        lcd.print("Bypass Active");
        lcd.setCursor(0, 1);
        lcd.print("Manual Control");
    } else if (speedLimited) {
        lcd.print("Speed Limited:");
        lcd.setCursor(0, 1);
        lcd.print("20%");
    } else {
        lcd.print("Motor Speed:");
        lcd.setCursor(0, 1);
        lcd.print(map(speedValue, 0, 255, 0, 100));
        lcd.print("%");
    }
}
