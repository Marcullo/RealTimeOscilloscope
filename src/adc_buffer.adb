--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- adc_buffer.adb                 Stores measurements --
--                 (clear only using Clear procedure) --
--                                      Lukasz Marcul --
--                                 Edited: 16.01.2017 --
--------------------------------------------------------

package body adc_buffer is
   protected Container is
      procedure Insert (Item : in ContainerVoltageType);
      procedure ReadMappedValue (Index : in Natural;
                                 Item : out ContainerValueType);
      procedure ReadVoltage (Index : in Natural;
                             Item : out ContainerVoltageType);
      procedure ReadNrOfMeasurements (NrOfMeas : out Natural);
      procedure Full (Full : out Boolean);
      procedure Empty (Empty : out Boolean);
      procedure Clear;
      procedure ProcessMeasurement;
   private
      ContainerFull : Boolean := False;
      ContainerEmpty : Boolean := True;
      MeasurementBuffer : ContainerType := (others => -1);
      VoltageBuffer : ContainerVoltage := (others => -1);
   end Container;

   procedure Insert (Measurement : ContainerVoltageType) is
   begin
      Container.Insert (Measurement);
   end Insert;

   function ReadMappedValue (Index : Natural) return ContainerValueType is
      TempVal : ContainerValueType;
   begin
      Container.ReadMappedValue (Index, TempVal);
      return TempVal;
   end ReadMappedValue;

   function ReadVoltage (Index : Natural) return ContainerVoltageType is
      TempVal : ContainerVoltageType;
   begin
      Container.ReadVoltage (Index, TempVal);
      return TempVal;
   end ReadVoltage;

   function ReadNrOfMeasurements return Natural is
      TempVal : Natural;
   begin
      Container.ReadNrOfMeasurements (TempVal);
      return TempVal;
   end ReadNrOfMeasurements;

   function IsFull return Boolean is
      TempFull : Boolean := False;
   begin
      Container.Full (TempFull);
      return TempFull;
   end IsFull;

   function IsEmpty return Boolean is
      TempEmpty : Boolean := False;
   begin
      Container.Empty (TempEmpty);
      return TempEmpty;
   end IsEmpty;

   procedure Clear is
   begin
      Container.Clear;
   end Clear;

   function MapMeasurement (Value : ContainerVoltageType; inMin : ContainerVoltageType;
                            inMax : ContainerVoltageType; outMin : ContainerVoltageType;
                            outMax : ContainerVoltageType) return ContainerVoltageType;

   protected body Container is
      procedure Insert (Item : in ContainerVoltageType) is
      begin
         if ADCMeasCounter >= ContainerSize then
            ContainerFull := True;
         else
            ADCMeasCounter := ADCMeasCounter + 1;
         end if;
         for i in reverse 1 .. ContainerSize - 1 loop
            MeasurementBuffer (i) := MeasurementBuffer (i - 1);
            VoltageBuffer (i) := VoltageBuffer (i - 1);
         end loop;
         MeasurementBuffer (0) := ContainerValueType (MapMeasurement (Item,
                                                      0, ADCMaxVoltageMeas, 0, GraphMaxYValue));
         VoltageBuffer (0) := Item;
         ProcessMeasurement;
      end Insert;

      procedure ReadMappedValue (Index : in Natural;
                                 Item : out ContainerValueType) is
      begin
         Item := MeasurementBuffer (Index);
      end ReadMappedValue;

      procedure ReadVoltage (Index : in Natural;
                             Item : out ContainerVoltageType) is
      begin
         Item := VoltageBuffer (Index);
      end ReadVoltage;

      procedure ReadNrOfMeasurements (NrOfMeas : out Natural) is
      begin
         NrOfMeas := ADCMeasCounter;
      end ReadNrOfMeasurements;

      procedure Full (Full : out Boolean) is
      begin
         Full := ContainerFull;
      end Full;

      procedure Empty (Empty : out Boolean) is
      begin
         Empty := ContainerEmpty;
      end Empty;

      procedure Clear is
      begin
         ADCNewValue := False;
         ContainerFull := False;
         ContainerEmpty := True;
         ADCMeasCounter := 0;
         ADCMeasMin := ADCMaxVoltageMeas;
         ADCMeasMax := 0;
         MeasurementBuffer := (others => -1);
         VoltageBuffer := (others => -1);
      end Clear;

      procedure ProcessMeasurement is
         TempValue : ContainerVoltageType;
      begin
         ADCLastValue := VoltageBuffer (0);
         ADCMeasMin := 3300;
         ADCMeasMax := 0;

         for i in 0 .. 99 loop
            if MeasurementBuffer (i) = -1 then
               TempValue := 3301;
            else
               TempValue := VoltageBuffer (i);
            end if;

            if TempValue < ADCMeasMin then
               ADCMeasMin := TempValue;
            elsif TempValue > ADCMeasMax and TempValue < 3301 then
               ADCMeasMax := TempValue;
            end if;
         end loop;
      end ProcessMeasurement;
   end Container;

   function MapMeasurement (Value : ContainerVoltageType; inMin : ContainerVoltageType;
                            inMax : ContainerVoltageType; outMin : ContainerVoltageType;
                            outMax : ContainerVoltageType) return ContainerVoltageType is
      tempValue : ContainerVoltageType := Value;
   begin
      if tempValue < inMin then
         tempValue := inMin;
      elsif tempValue > inMax then
         tempValue := inMax;
      end if;
      return (tempValue - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
   end MapMeasurement;
end adc_buffer;
