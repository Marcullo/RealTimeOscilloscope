--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- adc.ads           12-bit ADC, polling, cyclic task --
--                                      Lukasz Marcul --
--                                 Edited: 16.01.2017 --
--------------------------------------------------------

with System;

package adc is
   task MeasureADC is
      pragma Priority (System.Default_Priority + 3);
   end MeasureADC;
end adc;
