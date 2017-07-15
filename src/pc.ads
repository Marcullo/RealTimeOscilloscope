--------------------------------------------------------
--  PROJECT: REAL-TIME DIGITAL OSCILLOSCOPE           --
--------------------------------------------------------
-- pc.ads  Transmit Measurements to PC, sporadic task --
--                                     Lukasz Marcul  --
--                                Edited: 16.01.2017  --
--------------------------------------------------------

with System;

package pc is
   task VirtualCOM is
      pragma Priority (System.Default_Priority + 1);
   end VirtualCOM;
end pc;
