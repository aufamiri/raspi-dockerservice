const int SWITCH_OUTPUT = 10;

const byte buffSize = 40;
char inputBuffer[buffSize];
const char startMarker = '<';
const char endMarker = '>';
byte bytesRecvd = 0;
boolean readInProgress = false;
boolean newDataFromPC = false;

boolean isActionRequired = false;


void setup() {
  Serial.begin(9600);

  // put your setup code here, to run once:
  pinMode(SWITCH_OUTPUT, OUTPUT);

  Serial.println("<Arduino is ready>");
}

void loop() {
  // put your main code here, to run repeatedly:
  getDataFromPC();
  turnOnBay();
}

void turnOnBay() {
  if (!isActionRequired) {
    return;
  }

  analogWrite(SWITCH_OUTPUT, 150);
  delay(1000);
  Serial.print("<DONE>");
  isActionRequired = false;
}

void getDataFromPC() {

  // receive data from PC and save it into inputBuffer

  if (Serial.available() > 0) {

    char x = Serial.read();

    // the order of these IF clauses is significant

    if (x == endMarker) {
      readInProgress = false;
      newDataFromPC = true;
      inputBuffer[bytesRecvd] = 0;
      isActionRequired = true;
    }

    if (readInProgress) {
      inputBuffer[bytesRecvd] = x;
      bytesRecvd++;
      if (bytesRecvd == buffSize) {
        bytesRecvd = buffSize - 1;
      }
    }

    if (x == startMarker) {
      bytesRecvd = 0;
      readInProgress = true;
    }
  }
}
