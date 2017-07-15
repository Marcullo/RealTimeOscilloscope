--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- adc.adb           12-bit ADC, polling, cyclic task --
--                                      Lukasz Marcul --
--                                 Edited: 16.01.2017 --
--------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;

with STM32.Device; use STM32.Device;
with STM32.ADC;   use STM32.ADC;
with STM32.GPIO;   use STM32.GPIO;

with globals; use globals;
with adc_buffer;

package body adc is
   BasePointer : Analog_To_Digital_Converter renames ADC_1;
   InputChannel : constant Analog_Input_Channel := Analog_Input_Channel (ADCChannelNumber);
   InputPin : constant GPIO_Point := (GPIO_A'Access, Integer (ADCChannelNumber));
   AllRegularConversions : constant Regular_Channel_Conversions :=
     (1 => (Channel => InputChannel, Sample_Time => Sample_144_Cycles));
   Successful : Boolean;

   procedure Init;
   procedure Start;

   procedure Init is
   begin
      Enable_Clock (InputPin);
      Enable_Clock (BasePointer);
      Configure_IO (InputPin, (Mode => Mode_Analog, others => <>));
      Reset_All_ADC_Units;

      Configure_Common_Properties
        (Mode           => Independent,
         Prescalar      => PCLK2_Div_2,
         DMA_Mode       => Disabled,
         Sampling_Delay => Sampling_Delay_5_Cycles);

      Configure_Unit
        (BasePointer,
         Resolution => ADCResolution,
         Alignment  => Right_Aligned);

      Configure_Regular_Conversions
        (BasePointer,
         Continuous  => False,
         Trigger     => Software_Triggered,
         Enable_EOC  => True,
         Conversions => AllRegularConversions);

      Enable (BasePointer);
   end Init;

   procedure Start is
   begin
      Start_Conversion (BasePointer);
      Poll_For_Status (BasePointer, Regular_Channel_Conversion_Complete, Successful);
   end Start;

   task body MeasureADC is
      ReleaseInterval : constant Time_Span := Milliseconds (20);
      NextRelease : Time := Clock + ReleaseInterval + InitializationDelay;
   begin
      Init;
      loop
         delay until NextRelease;

         if ADCNewValue = False then
            Start;
            adc_buffer.Insert (ContainerVoltageType (Integer (
                               Conversion_Value (BasePointer)) * Integer (ADCMaxVoltageMeas)
                               / Integer (ADCMaxValue)));
            ADCNewValue := True;
            Set_True (DisplayUpdatePending);
         end if;

         NextRelease := NextRelease + ReleaseInterval;
      end loop;
   exception
         when others => null;
   end MeasureADC;
end adc;
