--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- oscilloscope_demo.adb                  MAIN SOURCE --
--               Switch graph display mode, blink led --
--                                      Lukasz Marcul --
--                                 Edited: 16.01.2017 --
--------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;
with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
with System;

with STM32.Board;  use STM32.Board;
with STM32.User_Button; use STM32;

with adc; pragma Unreferenced (adc);
with disp;
with pc; pragma Unreferenced (pc);

with globals; use globals;

procedure oscilloscope_demo is
   pragma Priority (System.Default_Priority);

   ReleaseInterval : constant Time_Span := Milliseconds (UserButtonMilisInterval);
   NextRelease : Time := Clock + ReleaseInterval + InitializationDelay;
begin
   Initialize_LEDs;
   User_Button.Initialize;
   loop
      delay until NextRelease;
      Green.Toggle;
      if User_Button.Has_Been_Pressed then
         disp.SwitchPlotMode;
         Set_True (DisplayUpdatePending);
      end if;
      NextRelease := NextRelease + ReleaseInterval;
   end loop;
end oscilloscope_demo;
