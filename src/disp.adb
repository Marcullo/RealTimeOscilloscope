--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- disp.adb    Control Display and TP, sporadic tasks --
--                                      Lukasz Marcul --
--                                 Edited: 16.01.2017 --
--------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;

with STM32.Board; use STM32.Board;
with LCD_Std_Out; use LCD_Std_Out;
with Bitmapped_Drawing; use Bitmapped_Drawing;
with HAL.Touch_Panel; use HAL.Touch_Panel;

with globals; use globals;
with adc_buffer;

package body disp is
   type ButtonIDType is (UARTConfigButton, UARTSendButton, ClearGraphButton);
   type PressedButtonIDType is (NoButton, ClearGraphButton, UARTConfigButton, UARTSendButton);
   type ButtonType is record
      Pressed : Boolean := False;
      X      : Natural;
      Y      : Natural;
      Width  : Positive;
      Height : Positive;
      Font : BMP_Font := Font12x12;
      Data : Natural := 0;
   end record;

   UARTConfigBtn : constant ButtonType :=
     (Pressed => False,
      X => 10,
      Y => 225,
      Width => 105,
      Height => 40,
      Font => Font16x24,
      Data => 0);

   UARTSendBtn : constant ButtonType :=
     (Pressed => False,
      X => 125,
      Y => 225,
      Width => 105,
      Height => 40,
      Font => Font16x24,
      Data => 0);

   ClearGraphBtn : constant ButtonType :=
     (Pressed => False,
      X => 20,
      Y => 20,
      Width => 200,
      Height => 140,
      Font => Font16x24,
      Data => 0);

   CurrentPlotMode : PlotModeType := Line;
   PressedButton, LastPressedButton : PressedButtonIDType := NoButton;

   procedure Init;

   procedure PrintGUIDescription;
   procedure PrintAxisDescription;
   procedure PrintHints;
   procedure PrintAxisX;
   procedure PrintAxisY;
   procedure PrintFrame (Frame : Rect);
   procedure PrintUARTDescription;
   procedure PrintButtonsFrames;

   procedure PrintGraph;
   procedure PrintButtons;
   procedure PrintMeasurements;
   procedure PrintCurrentPlotModeDescription;
   procedure PrintCurrentValueindicator;

   procedure PrintButton (ButtonID : ButtonIDType; Text : String := "");
   procedure PrintPressedButton (ButtonID : ButtonIDType; Text : String := "");
   procedure PrintButtonEvent (ButtonID : ButtonIDType);
   procedure PrintResetButtonEvent (ButtonID : ButtonIDType);
   function IsButtonPressed (ButtonID : ButtonIDType) return Boolean;
   function IsTPInsideButton (TPState : TP_State; ButtonID : ButtonIDType) return Boolean;

   procedure PutVoltage (X, Y : Natural; Voltage : ContainerVoltageType; Prefix : String := "";
                         Suffix : String := ""; TrailingSpaces : Boolean := True);
   procedure PutValue (X, Y : Natural; Value : Natural; Prefix : String := "";
                         Suffix : String := ""; TrailingSpacesNr : Integer := 0);
   procedure PrintString (X, Y : Natural;
                          Str : String := "";
                          Font : BMP_Font := Font12x12;
                          TxtColor : Bitmap_Color := MAINTextColor;
                          BgColor : Bitmap_Color :=  MAINBGColor);

   procedure Init is
   begin
      Touch_Panel.Initialize;
      ClearScreen;
      PrintGUIDescription;
      PrintAxisX;
      PrintAxisY;
      PrintFrame ((Position => (15, 15), Width => 210, Height => 150));
      PrintUARTDescription;
      PrintButtonsFrames;
      PrintButtons;
   end Init;

   procedure ClearScreen is
   begin
      Clear_Screen;
   end ClearScreen;

   procedure SwitchPlotMode is
   begin
      if CurrentPlotMode = Line then
         CurrentPlotMode := Scatter;
      elsif CurrentPlotMode = Scatter then
         CurrentPlotMode := Bar;
      else  --  CurrentPlotMode = Bar
         CurrentPlotMode := Line;
      end if;
   end SwitchPlotMode;

   procedure PrintGUIDescription is
   begin
      PrintAxisDescription;
      PrintHints;
   end PrintGUIDescription;

   procedure PrintAxisDescription is
   begin
      Set_Font (AxisDescriptionFont);

      Current_Text_Color := AxisDescriptionTextColor;
      Current_Background_Color := AxisDescriptionBGColor;
      --  vertical
      Put (2, 2, "3.300V");
      Put (2, 34, "3");
      Put (2, 74, "2");
      Put (2, 114, "1");
      Put (2, 155, "0");
      --  horizontal
      Put (5, 170, "100");
      Put (112, 170, "50");
      Put (220, 170, "0");
      --  resolution
      Put (140, 2, ADCResolutionDescription);

      Current_Text_Color := AxisDescriptionBGColor;
      Current_Background_Color := AxisDescriptionTextColor;
      --  CH
      case ADCChannelNumber is
         when 0 => Put (59, 2, "CH0");
         when 1 => Put (59, 2, "CH1");
         when 2 => Put (59, 2, "CH2");
         when 3 => Put (59, 2, "CH3");
         when 4 => Put (59, 2, "CH4");
         when 5 => Put (59, 2, "CH5");
         when 6 => Put (59, 2, "CH6");
         when 7 => Put (59, 2, "CH7");
      end case;
   end PrintAxisDescription;

   procedure PrintHints is
   begin
      Set_Font (GraphHintsFont);

      Current_Text_Color := GraphHintsTextColor;
      Current_Background_Color := GraphHintsBGColor;
      --  clear buffer
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 30, 282, 18, 11, 0, GraphBGColor);
      Draw_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), ((27, 279), 24, 17), 0, GraphFrameColor, 1);
      Draw_Line (Display.Get_Hidden_Buffer (1), (35, 288), (38, 284), GraphColor, 1);
      Draw_Line (Display.Get_Hidden_Buffer (1), (38, 284), (43, 284), GraphColor, 1);
      Draw_Line (Display.Get_Hidden_Buffer (1), (43, 284), (45, 289), GraphColor, 1);
      Put (57, 284, "Clear meas. buffer");
      --  change drawing mode
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 32, 300, 16, 17, 0, GraphHintsUBtnBGColor);
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 29, 300, 3, 2, 0, GraphHintsUBtnBGColor);
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 29, 315, 3, 2, 0, GraphHintsUBtnBGColor);
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 48, 300, 3, 2, 0, GraphHintsUBtnBGColor);
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 48, 315, 3, 2, 0, GraphHintsUBtnBGColor);
      Fill_Circle (Display.Get_Hidden_Buffer (1), (40, 308), 7, GraphHintsUBtnColor);
      Put (52, 304, "Change drawing mode");
   end PrintHints;

   procedure PrintAxisX is
   begin
      --  down
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 20, 160, 3, 3, 0, GraphGridColor);  --  100
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 40, 160, 3, 3, 0, GraphGridColor);  --  90
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 60, 160, 3, 3, 0, GraphGridColor);  --  80
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 80, 160, 3, 3, 0, GraphGridColor);  --  70
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 100, 160, 3, 3, 0, GraphGridColor);  --  60
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 120, 160, 3, 3, 0, GraphGridColor);  --  50
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 140, 160, 3, 3, 0, GraphGridColor);  --  40
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 160, 160, 3, 3, 0, GraphGridColor);  --  30
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 180, 160, 3, 3, 0, GraphGridColor);  --  20
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 200, 160, 3, 3, 0, GraphGridColor);  --  10
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 217, 160, 3, 3, 0, GraphGridColor);  --  0
   end PrintAxisX;

   procedure PrintAxisY is
   begin
      --  left
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 17, 20, 3, 3, 0, GraphGridColor);  --  3.300
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 17, 32, 3, 3, 0, GraphGridColor);  --  3
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 17, 74, 3, 3, 0, GraphGridColor);  --  2
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 17, 116, 3, 3, 0, GraphGridColor);  --  1
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 17, 157, 3, 3, 0, GraphGridColor);  --  0

      --  right
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 220, 20, 3, 3, 0, GraphGridColor);  --  3.300
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 220, 32, 3, 3, 0, GraphGridColor);  --  3
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 220, 74, 3, 3, 0, GraphGridColor);  --  2
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 220, 116, 3, 3, 0, GraphGridColor);  --  1
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 220, 157, 3, 3, 0, GraphGridColor);  --  0
   end PrintAxisY;

   procedure PrintFrame (Frame : Rect) is
   begin
      Draw_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), Frame, 0, GraphFrameColor, 3);
   end PrintFrame;

   procedure PrintUARTDescription is
   begin
      Current_Text_Color := UARTDescriptionColor;
      Current_Background_Color := UARTDescriptionBGColor;
      Set_Font (UARTDescriptionFont);
      Put (2, 206, "UART1 (PC)");
   end PrintUARTDescription;

   procedure PrintButtonsFrames is
   begin
      PrintFrame ((Position => (UARTConfigBtn.X - 5, UARTConfigBtn.Y - 5),
                  Width => UARTConfigBtn.Width + 10,
                  Height => UARTConfigBtn.Height + 10));
      PrintFrame ((Position => (UARTSendBtn.X - 5, UARTSendBtn.Y - 5),
                  Width => UARTSendBtn.Width + 10,
                  Height => UARTSendBtn.Height + 10));
   end PrintButtonsFrames;

   procedure PrintGraph is
      FrameOrigin : constant Point := (219, 159);
      CurrentPixel : Point := FrameOrigin;
      PixelBefore : Point := FrameOrigin;
   begin
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 20, 20, 200, 140, 0, GraphBGColor);
      for i in  0 .. ContainerSize - 1 loop
         if adc_buffer.ReadMappedValue (i) > -1 then
            PixelBefore := CurrentPixel;
            CurrentPixel.X := FrameOrigin.X - 2 * i;
            CurrentPixel.Y := FrameOrigin.Y - Natural (adc_buffer.ReadMappedValue (i));

            if CurrentPlotMode = Line then
               if i = ContainerSize - 1 or i = 0 then
                  PixelBefore := CurrentPixel;
               end if;
               Draw_Line (Display.Get_Hidden_Buffer (1), (CurrentPixel.X, CurrentPixel.Y),
                          PixelBefore, GraphColor, 2);
            elsif CurrentPlotMode = Scatter then
               Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1),
                                       CurrentPixel.X, CurrentPixel.Y,
                                       2, 2, 0, GraphColor);
            else  --  CurrentPlotMode = Bar
               Draw_Line (Display.Get_Hidden_Buffer (1), (CurrentPixel.X, CurrentPixel.Y),
                          (CurrentPixel.X, FrameOrigin.Y),
                          GraphColor, 2);
            end if;
         end if;
      end loop;
   end PrintGraph;

   procedure PrintButtons is
   begin
      if PressedButton /= NoButton then
         case PressedButton is
            when ClearGraphButton =>
               PrintPressedButton (ClearGraphButton);
            when UARTConfigButton =>
               PrintPressedButton (UARTConfigButton, UARTStringDescription);
            when UARTSendButton =>
               PrintPressedButton (UARTSendButton);
            when others =>
               null;
         end case;
      elsif LastPressedButton /= NoButton then
         case LastPressedButton is
            when ClearGraphButton =>
               null;
            when UARTConfigButton =>
               PrintButton (UARTConfigButton, UARTStringDescription);
            when UARTSendButton =>
               PrintButton (UARTSendButton);
               if UARTMessageSent then
                  PrintButtonEvent (UARTSendButton);
                  UARTMessageSent := False;
               else
                  PrintResetButtonEvent (UARTSendButton);
               end if;
            when others =>
               null;
         end case;
         --  LastPressedButton := NoButton;
      else
         PrintButton (UARTConfigButton, UARTStringDescription);
         PrintButton (UARTSendButton, UARTStringDescription);
      end if;
   end PrintButtons;

   procedure PrintMeasurements is
      TrailingSaSpaces : Integer := 0;
   begin
      Current_Text_Color := MeasurementsColor;
      LCD_Std_Out.Current_Background_Color := MeasurementsBGColor;
      LCD_Std_Out.Set_Font (MeasurementsFont);

      PutVoltage (171, 2, ADCLastValue, "", "mV", True);   --  current voltage
      PutVoltage (53, 186, ADCMeasMin, "", "mV");          --  min
      PutVoltage (158, 186, ADCMeasMax, "", "mV");         --  max
      Put (30, 186, "Min ");
      Put (135, 186, "Max ");

      if ADCMeasCounter < 10 then
         TrailingSaSpaces := 2;
      elsif ADCMeasCounter < 100 then
         TrailingSaSpaces := 1;
      else
         TrailingSaSpaces := 0;
      end if;
      PutValue (84, 2, ADCMeasCounter, "", "Sa", TrailingSaSpaces);
   end PrintMeasurements;

   procedure PrintCurrentPlotModeDescription is
   begin
      Current_Text_Color := MeasurementsColor;
      Current_Background_Color := MeasurementsBGColor;
      Set_Font (MeasurementsFont);

      if CurrentPlotMode = Scatter then
         Put (230, 2, ":");
      elsif CurrentPlotMode = Line then
         Put (230, 2, "/");
      else
         Put (230, 2, "|");
      end if;
   end PrintCurrentPlotModeDescription;

   procedure PrintCurrentValueindicator is
      IndicatorCentre : constant Point := (228, 159 - Natural (adc_buffer.ReadMappedValue (0)));
      NodePoint : Point;
   begin
      Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), 228, 16, 10, 150, 0,
                              CurrentValueIndicatorBGColor);
      NodePoint := (IndicatorCentre.X + 8, IndicatorCentre.Y + 4);
      Draw_Line (Display.Get_Hidden_Buffer (1), IndicatorCentre, NodePoint,
                 CurrentValueIndicatorColor, 1);
      NodePoint := (IndicatorCentre.X + 8, IndicatorCentre.Y - 4);
      Draw_Line (Display.Get_Hidden_Buffer (1), IndicatorCentre, NodePoint,
                 CurrentValueIndicatorColor, 1);
      Draw_Line (Display.Get_Hidden_Buffer (1), NodePoint, (NodePoint.X, NodePoint.Y + 8),
                 CurrentValueIndicatorColor, 1);
   end PrintCurrentValueindicator;

   procedure PrintButton (ButtonID : ButtonIDType; Text : String := "") is
   begin
      if ButtonID = UARTConfigButton then
         Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), UARTConfigBtn.X,
                                UARTConfigBtn.Y, UARTConfigBtn.Width,
                                 UARTConfigBtn.Height, 0, TouchButtonColor);
         if Text'Length > 0 then
            PrintString (UARTConfigBtn.X + 5, UARTConfigBtn.Y + 2, Text (Text'First .. Text'First + 5),
                      UARTConfigBtn.Font, TouchButtonTextColor, TouchButtonColor);
            PrintString (UARTConfigBtn.X + 73, UARTConfigBtn.Y + 26, Text (Text'First + 6 .. Text'First + 8),
                         Font8x8, TouchButtonTextColor, TouchButtonColor);
         else
            PrintString (UARTConfigBtn.X + 5, UARTConfigBtn.Y + 2, "CONFIG",
                      UARTConfigBtn.Font, TouchButtonTextColor, TouchButtonColor);
            PrintString (UARTConfigBtn.X + 73, UARTConfigBtn.Y + 26, "---",
                         Font8x8, TouchButtonTextColor, TouchButtonColor);
         end if;
      elsif ButtonID = UARTSendButton then
         Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), UARTSendBtn.X,
                                UARTSendBtn.Y, UARTSendBtn.Width,
                                UARTSendBtn.Height, 0, TouchButtonColor);
         PrintString (UARTSendBtn.X + 20, UARTSendBtn.Y + 10, "SEND",
                      UARTSendBtn.Font, TouchButtonTextColor, TouchButtonColor);
      else  --  ButtonID = ClearGraphButton
         null;
      end if;
   end PrintButton;

   procedure PrintPressedButton (ButtonID : ButtonIDType; Text : String := "") is
   begin
      if ButtonID = UARTConfigButton then
         Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), UARTConfigBtn.X,
                                 UARTConfigBtn.Y, UARTConfigBtn.Width,
                                 UARTConfigBtn.Height, 0, PressedTouchButtonColor);

         if Text'Length > 0 then
            PrintString (UARTConfigBtn.X + 5, UARTConfigBtn.Y + 2, Text (Text'First .. Text'First + 5),
                      UARTConfigBtn.Font, PressedTouchButtonTextColor, PressedTouchButtonColor);
            PrintString (UARTConfigBtn.X + 73, UARTConfigBtn.Y + 26, Text (Text'First + 6 .. Text'First + 8),
                         Font8x8, PressedTouchButtonTextColor, PressedTouchButtonColor);
         else
            PrintString (UARTConfigBtn.X + 5, UARTConfigBtn.Y + 10, "-----",
                      UARTConfigBtn.Font, PressedTouchButtonTextColor, PressedTouchButtonColor);
         end if;
      elsif ButtonID = UARTSendButton then
         Fill_Rounded_Rectangle (Display.Get_Hidden_Buffer (1), UARTSendBtn.X,
                                UARTSendBtn.Y, UARTSendBtn.Width,
                                UARTSendBtn.Height, 0, PressedTouchButtonColor);
         PrintString (UARTSendBtn.X + 20, UARTSendBtn.Y + 10, "SEND",
                      UARTSendBtn.Font, PressedTouchButtonTextColor, PressedTouchButtonColor);
      else  --  ButtonID = ClearGraphButton
         PrintString (ClearGraphBtn.X + 10, ClearGraphBtn.Y + 10, "Clear",
                      ClearGraphBtn.Font, GraphClearTextColor, GraphClearBGColor);
      end if;
   end PrintPressedButton;

   procedure PrintButtonEvent (ButtonID : ButtonIDType) is
   begin
      if ButtonID = UARTConfigButton then
         null;
      elsif ButtonID = UARTSendButton then
         Draw_Rounded_Rectangle (Display.Get_Hidden_Buffer (1),
                                 ((UARTSendBtn.X - 2, UARTSendBtn.Y - 2),
                                  UARTSendBtn.Width + 4, UARTSendBtn.Height + 4), 0,
                                 ButtonEventColor, 3);
      else  --  ButtonID = ClearGraphButton
         null;
      end if;
   end PrintButtonEvent;

   procedure PrintResetButtonEvent (ButtonID : ButtonIDType) is
   begin
      if ButtonID = UARTConfigButton then
         null;
      elsif ButtonID = UARTSendButton then
         Draw_Rounded_Rectangle (Display.Get_Hidden_Buffer (1),
                                 ((UARTSendBtn.X - 2, UARTSendBtn.Y - 2),
                                  UARTSendBtn.Width + 4, UARTSendBtn.Height + 4), 0,
                                 MAINBGColor, 3);
      else  --  ButtonID = ClearGraphButton
         null;
      end if;
   end PrintResetButtonEvent;

   function IsButtonPressed (ButtonID : ButtonIDType) return Boolean is
      TPState : constant TP_State := Touch_Panel.Get_All_Touch_Points;
   begin
      if TPState'Length /= 1 then
         return False;
      else
         if IsTPInsideButton (TPState, ButtonID) = False then
            return False;
         else
            return True;
         end if;
      end if;
   end IsButtonPressed;

   function IsTPInsideButton (TPState : TP_State; ButtonID : ButtonIDType) return Boolean is
      xTP : constant Natural := TPState (TPState'First).X;
      yTP : constant Natural := TPState (TPState'First).Y;
      xBTN : Natural;
      yBTN : Natural;
      Width  : Positive;
      Height : Positive;
   begin
      if ButtonID = UARTConfigButton then
         xBTN := UARTConfigBtn.X;
         yBTN := UARTConfigBtn.Y;
         Width := UARTConfigBtn.Width;
         Height := UARTConfigBtn.Height;
      elsif ButtonID = UARTSendButton then
         xBTN := UARTSendBtn.X;
         yBTN := UARTSendBtn.Y;
         Width := UARTSendBtn.Width;
         Height := UARTSendBtn.Height;
      else  --  ButtonID = ClearGraphButton
         xBTN := ClearGraphBtn.X;
         yBTN := ClearGraphBtn.Y;
         Width := ClearGraphBtn.Width;
         Height := ClearGraphBtn.Height;
      end if;

      if xTP < xBTN or xTP > xBTN + Width - 1 or yTP < yBTN or yTP > yBTN + Height - 1 then
         return False;
      else
         return True;
      end if;
   end IsTPInsideButton;

   procedure PutVoltage (X, Y : Natural; Voltage : ContainerVoltageType; Prefix : String := "";
                         Suffix : String := ""; TrailingSpaces : Boolean := True) is
   begin
      if TrailingSpaces then
         if Voltage > 999 then
            Put (X, Y, Prefix & Voltage'Img & Suffix);
         elsif Voltage > 99 then
            Put (X, Y, Prefix & Voltage'Img & Suffix & " ");
         elsif Voltage > 9 then
            Put (X, Y, Prefix & Voltage'Img & Suffix & "  ");
         else
            Put (X, Y, Prefix & Voltage'Img & Suffix & "   ");
         end if;
      else
         Put (X, Y, Prefix & Voltage'Img & Suffix);
      end if;

   end PutVoltage;

   procedure PutValue (X, Y : Natural; Value : Natural; Prefix : String := "";
                         Suffix : String := ""; TrailingSpacesNr : Integer := 0) is
   begin
      if TrailingSpacesNr = 0 then
         Put (X, Y, Prefix & Value'Img & Suffix);
      elsif TrailingSpacesNr = 1 then
         Put (X, Y, Prefix & Value'Img & Suffix & " ");
      elsif TrailingSpacesNr = 2 then
         Put (X, Y, Prefix & Value'Img & Suffix & "  ");
      else
         Put (X, Y, Prefix & Value'Img & Suffix);
      end if;
   end PutValue;

   procedure PrintString (X, Y : Natural;
                          Str : String := "";
                          Font : BMP_Font := Font12x12;
                          TxtColor : Bitmap_Color := MAINTextColor;
                          BgColor : Bitmap_Color :=  MAINBGColor) is
   begin
      Current_Text_Color := TxtColor;
      Current_Background_Color := BgColor;
      Set_Font (Font);
      Put (X, Y, Str);
   end PrintString;

   task body UpdateGUI is
   begin
      disp.Init;
      delay until Clock + InitializationDelay;
      loop
         Suspend_Until_True (DisplayUpdatePending);
         Set_False (DisplayUpdatePending);

         PrintGraph;
         PrintMeasurements;
         PrintCurrentPlotModeDescription;
         ADCNewValue := False;
         PrintButtons;
         PrintCurrentValueindicator;

      end loop;
   end UpdateGUI;

   task body ControlTouchPanel is
      ReleaseInterval : constant Time_Span := Milliseconds (TouchPanelMilisInterval);
      NextRelease : Time := Clock + ReleaseInterval + InitializationDelay;
   begin
      loop
         delay until NextRelease;

         if IsButtonPressed (ClearGraphButton) then
            PressedButton := ClearGraphButton;
            LastPressedButton := ClearGraphButton;
            adc_buffer.Clear;
            Set_True (DisplayUpdatePending);
         elsif IsButtonPressed (UARTConfigButton) then
            PressedButton := UARTConfigButton;
            LastPressedButton := UARTConfigButton;
            UARTChangeConfigPending := True;
            Set_True (UARTPending);
            Set_True (DisplayUpdatePending);
         elsif IsButtonPressed (UARTSendButton) then
            PressedButton := UARTSendButton;
            LastPressedButton := UARTSendButton;
            UARTChangeConfigPending := False;
            Set_True (UARTPending);
            Set_True (DisplayUpdatePending);
         else  -- NoButtton
            PressedButton := NoButton;
         end if;

         NextRelease := NextRelease + ReleaseInterval;
      end loop;
   end ControlTouchPanel;
end disp;
