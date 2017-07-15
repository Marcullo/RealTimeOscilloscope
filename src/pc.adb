--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- pc.adb  Transmit Measurements to PC, sporadic task --
--                                     Lukasz Marcul  --
--                                Edited: 16.01.2017  --
--------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;

with STM32.Device; use STM32.Device;
with STM32.USARTs; use STM32.USARTs;

with Serial_IO.Blocking;    use Serial_IO.Blocking;
with Message_Buffers;       use Message_Buffers;
use Serial_IO;

with adc_buffer;
with globals; use globals;

package body pc is
   Outgoing : aliased Message (Physical_Size => 7);  -- arbitrary size

   Peripheral : aliased Serial_IO.Peripheral_Descriptor :=
                  (Transceiver    => USART_1'Access,
                   Transceiver_AF => GPIO_AF_7_USART1,
                   Tx_Pin         => PA10,
                   Rx_Pin         => PA9);
   COM : Blocking.Serial_Port (Peripheral'Access);

   procedure Init (Config : UARTConfigType);
   procedure SetConfig (Config : UARTConfigType);
   procedure ChangeConfig;
   procedure TransmitValue (Value : ContainerValueType);
   procedure TransmitVoltage (Voltage : ContainerVoltageType);
   procedure TransmitMessage (This : String);
   pragma Unreferenced (TransmitMessage);

   procedure Init (Config : UARTConfigType) is
   begin
      Initialize (COM);
      SetConfig (Config);
   end Init;

   procedure SetConfig (Config : UARTConfigType) is
   begin
      UARTCurrentConfig := Config;
      if Config = U_115200_8N1 then
         Configure (Device     => Peripheral'Access,
                    Baud_Rate  => 115_200,
                    Parity     => No_Parity,
                    Data_Bits  => Word_Length_8,
                    End_Bits   => Stopbits_1,
                    Control    => No_Flow_Control);
         UARTStringDescription := Text_U_115200_8N1;
      elsif Config = U_57600_8N1 then
         Configure (Device     => Peripheral'Access,
                    Baud_Rate  => 57_600,
                    Parity     => No_Parity,
                    Data_Bits  => Word_Length_8,
                    End_Bits   => Stopbits_1,
                    Control    => No_Flow_Control);
         UARTStringDescription := Text_U_57600_8N1;
      elsif Config = U_38400_8N1 then
         Configure (Device     => Peripheral'Access,
                    Baud_Rate  => 38_400,
                    Parity     => No_Parity,
                    Data_Bits  => Word_Length_8,
                    End_Bits   => Stopbits_1,
                    Control    => No_Flow_Control);
         UARTStringDescription := Text_U_38400_8N1;
      elsif Config = U_19200_8N1 then
         Configure (Device     => Peripheral'Access,
                    Baud_Rate  => 19_200,
                    Parity     => No_Parity,
                    Data_Bits  => Word_Length_8,
                    End_Bits   => Stopbits_1,
                    Control    => No_Flow_Control);
         UARTStringDescription := Text_U_19200_8N1;
      else  --  Config = U_9600_8N1
         Configure (Device     => Peripheral'Access,
                    Baud_Rate  => 9_600,
                    Parity     => No_Parity,
                    Data_Bits  => Word_Length_8,
                    End_Bits   => Stopbits_1,
                    Control    => No_Flow_Control);
         UARTStringDescription := Text_U_9600_8N1;
      end if;
   end SetConfig;

   procedure ChangeConfig is
   begin
      if UARTCurrentConfig = U_115200_8N1 then
         SetConfig (U_57600_8N1);
      elsif UARTCurrentConfig = U_57600_8N1 then
         SetConfig (U_38400_8N1);
      elsif UARTCurrentConfig = U_38400_8N1 then
         SetConfig (U_19200_8N1);
      elsif UARTCurrentConfig = U_19200_8N1 then
         SetConfig (U_9600_8N1);
      else  --  UARTCurrentConfig = U_9600_8N1
         SetConfig (U_115200_8N1);
      end if;
   end ChangeConfig;

   procedure TransmitValue (Value : ContainerValueType) is
      Str : constant String := ConvertIntToString (Integer (Value));
   begin
      Set (Outgoing, To => Str & ASCII.CR & ASCII.LF & ASCII.NUL);
      Blocking.Put (COM, Outgoing'Unchecked_Access);
   end TransmitValue;

   procedure TransmitVoltage (Voltage : ContainerVoltageType) is
      Str : constant String := ConvertIntToString (Integer (Voltage));
   begin
      Set (Outgoing, To => Str & ASCII.CR & ASCII.LF & ASCII.NUL);
      Blocking.Put (COM, Outgoing'Unchecked_Access);
   end TransmitVoltage;

   procedure TransmitMessage (This : String) is
   begin
      Set (Outgoing, To => This & ASCII.CR & ASCII.LF & ASCII.NUL);
      Blocking.Put (COM, Outgoing'Unchecked_Access);
   end TransmitMessage;

   task body VirtualCOM is
      NumberOfMeasToSend : Integer := 1;
   begin
      pc.Init (UARTInitConfigType);
      delay until Clock + InitializationDelay;
      loop
         Suspend_Until_True (UARTPending);
         Set_False (UARTPending);

         if UARTChangeConfigPending then
            UARTChangeConfigPending := False;
            ChangeConfig;
         else
            if UARTSendEmptyMeas then
               NumberOfMeasToSend := 100;
            else
               NumberOfMeasToSend := ADCMeasCounter;
            end if;

            for i in reverse 0 .. NumberOfMeasToSend - 1 loop
               if adc_buffer.ReadMappedValue (i) = -1 then
                  TransmitValue (adc_buffer.ReadMappedValue (i));
               else
                  TransmitVoltage (adc_buffer.ReadVoltage (i));
               end if;
               UARTMessageSent := True;
            end loop;
         end if;
      end loop;
   end VirtualCOM;
end pc;
