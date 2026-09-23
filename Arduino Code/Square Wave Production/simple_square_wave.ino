const int outputPin = 2;

void setup() {
  // put your setup code here, to run once
  // running once beacuse PWM hardware keeps generating the 40 kHz waveform by itself after configuration
  
  // Configures GPIO 2 as an output
  pinMode(outputPin, OUTPUT);
  // Configures the PWM hardware for 40 kHz
  analogWriteFrequency(outputPin, 40000);  // 40 kHz
  // Sets the duty cycle to approximately 50%
  analogWrite(outputPin, 128);              // 50% duty cycle
}

void loop() {
  // put your main code here, to run repeatedly
}
