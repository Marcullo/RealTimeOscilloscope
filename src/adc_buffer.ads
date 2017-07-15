--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- adc_buffer.ads                 Stores measurements --
--                 (clear only using Clear procedure) --
--                                      Lukasz Marcul --
--                                 Edited: 16.01.2017 --
--------------------------------------------------------

with globals; use globals;

package adc_buffer is
   procedure Insert (Measurement : ContainerVoltageType);
   function ReadMappedValue (Index : Natural) return ContainerValueType;
   function ReadVoltage (Index : Natural) return ContainerVoltageType;
   function ReadNrOfMeasurements return Natural;
   function IsFull return Boolean;
   function IsEmpty return Boolean;
   procedure Clear;
end adc_buffer;
