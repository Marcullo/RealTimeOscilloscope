--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- disp.ads    Control Display and TP, sporadic tasks --
--                                      Lukasz Marcul --
--                                 Edited: 16.01.2017 --
--------------------------------------------------------

with HAL.Bitmap; use HAL.Bitmap;
with BMP_Fonts; use BMP_Fonts;
with System; use System;

package disp is
   MAINTextColor                : constant Bitmap_Color         := White;
   MAINBGColor                  : constant Bitmap_Color         := Black;
   AxisDescriptionTextColor     : constant Bitmap_Color         := MAINTextColor;
   AxisDescriptionBGColor       : constant Bitmap_Color         := MAINBGColor;
   AxisDescriptionFont          : constant BMP_Font             := Font8x8;
   ButtonEventColor             : constant Bitmap_Color         := Green;
   CurrentValueIndicatorColor   : constant Bitmap_Color         := Red;
   CurrentValueIndicatorBGColor : constant Bitmap_Color         := MAINBGColor;
   GraphColor                   : constant Bitmap_Color         := Blue_Violet;
   GraphBGColor                 : constant Bitmap_Color         := Light_Cyan;
   GraphClearTextColor          : constant Bitmap_Color         := Black;
   GraphClearBGColor            : constant Bitmap_Color         := GraphBGColor;
   GraphFrameColor              : constant Bitmap_Color         := Blue_Violet;
   GraphGridColor               : constant Bitmap_Color         := Red;
   GraphHintsTextColor          : constant Bitmap_Color         := MAINTextColor;
   GraphHintsBGColor            : constant Bitmap_Color         := MAINBGColor;
   GraphHintsFont               : constant BMP_Font             := Font8x8;
   GraphHintsUBtnColor          : constant Bitmap_Color         := Midnight_Blue;    -- UBtn : User Button
   GraphHintsUBtnBGColor        : constant Bitmap_Color         := Light_Slate_Gray; -- UBtn : User Button
   MeasurementsColor            : constant Bitmap_Color         := MAINTextColor;
   MeasurementsBGColor          : constant Bitmap_Color         := MAINBGColor;
   MeasurementsFont             : constant BMP_Font             := Font8x8;
   UARTDescriptionColor         : constant Bitmap_Color         := MAINTextColor;
   UARTDescriptionBGColor       : constant Bitmap_Color         := MAINBGColor;
   UARTDescriptionFont          : constant BMP_Font             := Font8x8;
   TouchButtonColor             : constant Bitmap_Color         := White;
   TouchButtonTextColor         : constant Bitmap_Color         := Blue_Violet;
   PressedTouchButtonColor      : constant Bitmap_Color         := Blue_Violet;
   PressedTouchButtonTextColor  : constant Bitmap_Color         := White;

   procedure ClearScreen;
   procedure SwitchPlotMode;

   task UpdateGUI is
      pragma Priority (System.Default_Priority + 2);
   end UpdateGUI;

   task ControlTouchPanel is
      pragma Priority (System.Default_Priority + 4);
   end ControlTouchPanel;
end disp;
