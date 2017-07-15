--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- globals.adb           Parameters; shared variables --
--                                      Lukasz Marcul --
--                                 Edited: 16.01.2017 --
--------------------------------------------------------

package body globals is
   function ConvertDigitToCharacter (Dig : Integer) return Character;

   procedure Reset is
   begin
      ADCNewValue     := False;
      ADCLastValue    := 0;
      ADCMeasCounter  := 0;
      ADCMeasMin      := ADCMaxValue;
      ADCMeasMax      := 0;
      UARTMessageSent := False;
   end Reset;

   function ConvertIntToString (Int : Integer) return String is
      TempStr : String (1 .. 4) := (others => '0');
      TempVal : Integer := Int;
   begin
      if Int > 999 then
         TempStr (TempStr'First + 0) := ConvertDigitToCharacter (TempVal / 1000);
         TempVal := TempVal - (TempVal / 1000) * 1000;
      end if;
      if Int > 99 then
         TempStr (TempStr'First + 1) := ConvertDigitToCharacter (TempVal / 100);
         TempVal := TempVal - (TempVal / 100) * 100;
      end if;
      if Int > 9 then
         TempStr (TempStr'First + 2) := ConvertDigitToCharacter (TempVal / 10);
         TempVal := TempVal - (TempVal / 10) * 10;
      end if;
      if Int > -1 then
         TempStr (TempStr'First + 3) := ConvertDigitToCharacter (TempVal);
      else
         TempStr (TempStr'First + 0) := '9';
         TempStr (TempStr'First + 1) := '9';
         TempStr (TempStr'First + 2) := '9';
         TempStr (TempStr'First + 3) := '9';
      end if;

      return TempStr;
   end ConvertIntToString;

   function ConvertDigitToCharacter (Dig : Integer) return Character is
      Char : Character;
   begin
      case Dig is
         when 0 => Char := '0';
         when 1 => Char := '1';
         when 2 => Char := '2';
         when 3 => Char := '3';
         when 4 => Char := '4';
         when 5 => Char := '5';
         when 6 => Char := '6';
         when 7 => Char := '7';
         when 8 => Char := '8';
         when 9 => Char := '9';
         when others => Char := ' ';
      end case;
      return Char;
   end ConvertDigitToCharacter;
end globals;
