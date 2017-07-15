# RealTimeOscilloscope
Analyse incoming signal using FreeRTOS facilities and basic math calculations.

Project was designed using GNAT Programming Studio. Main functionality allows to measure voltage from ADC (12-bit), display it on graphical interface and send to the PC in order to process the data. The acquisition starts after connecting the device to a power supply. The collected data is stored in a buffer, then being displayed on the lcd screen or sent to PC using UART. Display shows graph, measurements (current value, min/max), touch buttons (providing UART configuration and sending measurement buffer). It is possible to clear the buffer by touching (and holding for a while) a graph on the screen. User button can change graph plotting mode.

## HOW TO USE

1. Install Ada Drivers Library (https://github.com/AdaCore/Ada_Drivers_Library).
2. Create folder oscilloscope in ../examples folder (from the Ada Driver Library).
3. Copy content of the repository inside the created folder.
4. Edit project properties if necessary.
5. Build and run/debug.
