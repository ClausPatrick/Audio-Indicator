# Audio-Indicator
Using AVR on a Balanced_to_Unbalanced interface to indicate audio levels.

Aside from the audio circuitry for 8 channels (bal) to 4 stereo channels (un_bal) the board contains a ATtiny2313 
connected to each channel via its ADC and a PCA9685 with 8 RED and 8 GREEN LEDs to indicate Audio levels controlled via I2C.
The serial I2C protocol is implemented following Atmel's white paper since the controller does not contain a hardware stack for I2C.
The PCA9685 allows for 4 level PWM per LED. There is one green and one red LED per channel, allowing 8 levels per audio channel.
The code will scroll through the ADC channels and convert each 256 audio value to 8 level and subsequently to a key the PCA9685
can understand.
