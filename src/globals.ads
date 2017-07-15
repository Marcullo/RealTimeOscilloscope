--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- globals.ads           Parameters; shared variables --
--                                      Lukasz Marcul --
--                                 Edited: 16.01.2017 --
--------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;
with HAL; use HAL;

with Interfaces; use Interfaces;

with STM32.ADC; use STM32.ADC;

package globals is
   ContainerSize       : constant Positive := 100;
   InitializationDelay : constant Time_Span := Milliseconds (1000);

   type ContainerValueType   is new Integer_32;
   type ContainerVoltageType is new UInt32;
   type ContainerType        is array (0 .. ContainerSize - 1) of ContainerValueType;
   type ContainerVoltage     is array (0 .. ContainerSize - 1) of ContainerVoltageType;
   type ChannelNumberType    is new Natural range 0 .. 7;
   type PlotModeType         is (Line, Scatter, Bar);
   type UARTConfigType       is (U_115200_8N1, U_57600_8N1, U_38400_8N1, U_19200_8N1, U_9600_8N1);

   ADCChannelNumber         : constant ChannelNumberType    := 1;
   ADCResolution            : constant ADC_Resolution       := ADC_Resolution_12_Bits;
   ADCMaxValue              : constant ContainerVoltageType := 4095;
   ADCMaxVoltageMeas        : constant ContainerVoltageType := 3300;
   ADCResolutionDescription : constant String               := "12b";
   GraphMaxYValue           : constant ContainerVoltageType := 139;              --  respective to GraphOrigin
   Text_U_115200_8N1        : constant String               := "1152008N1";
   Text_U_57600_8N1         : constant String               := " 576008N1";
   Text_U_38400_8N1         : constant String               := " 384008N1";
   Text_U_19200_8N1         : constant String               := " 192008N1";
   Text_U_9600_8N1          : constant String               := "  96008N1";
   TouchPanelMilisInterval  : constant Integer              := 250;
   UARTInitConfigType       : constant UARTConfigType       := U_115200_8N1;
   UARTSendEmptyMeas        : constant Boolean              := False;
   UserButtonMilisInterval  : constant Integer              := 1000;

   ADCNewValue              : Boolean := False with Atomic;
   ADCLastValue             : ContainerVoltageType := 0 with Atomic;
   ADCMeasCounter           : Natural := 0 with Atomic;
   ADCMeasMin               : ContainerVoltageType := ADCMaxValue with Atomic;
   ADCMeasMax               : ContainerVoltageType := 0 with Atomic;
   DisplayUpdatePending     : Suspension_Object;
   UARTChangeConfigPending  : Boolean := False with Atomic;
   UARTMessageSent          : Boolean := False with Atomic;
   UARTPending              : Suspension_Object;
   UARTCurrentConfig        : UARTConfigType := U_115200_8N1;
   UARTStringDescription    : String := Text_U_115200_8N1;

   procedure Reset;
   function ConvertIntToString (Int : Integer) return String;
end globals;
