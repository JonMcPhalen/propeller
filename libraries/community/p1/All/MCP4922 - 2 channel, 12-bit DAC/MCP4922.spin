''******************************************************************''*  MCP4921/4922 Driver v0.1                                      *''*  Author: Ryan David (coding tips from Timmoore - thanks!)      *''*  Date Modified: 9-5-09                                         *''*                                                                * ''*  Changelog:                                                    *''*     Rev 0.1 (9-5-09)                                           *''*        -Inital Release                                         * ''*                                                                *''*  Very simple MCP4921/4922 Driver written in spin.  Eventually  *''*  I would like to convert it over to assembly.  I still need    *''*  check the output on the scope, but it should be okay.  The    *''*  internal DAC register should be updated on the rising edge    *''*  of CS with LDAC tied to ground.                               *''''''              *Pin 1''              ┌──────────────┐''          5V ─│Vdd      VoutA│- Output A''        Prop -│CS        AVss│- Ground''        Prop -│SCK       AVss│- 5V (with gain bit set to 1)''        Prop -│SDI       LDAC│- Ground''              └──────────────┘''                  MCP4921''              *Pin 1''              ┌──────────────┐''          5V ─│Vdd      VoutA│- Output A''             -│NC       VrefA│- 5V (with gain bit set to 1)''        Prop -│CS        AVss│- Ground''        Prop -│SCK      VrefB│- 5V (with gain bit set to 1)''        Prop -│SDI      VoutB│- Output B''             -│NC        SHDN│- 5V''             -│NC        LDAC│- Ground''              └──────────────┘''                  MCP4922''*  Call the 'Init' routine first with the pin assignments, and  *''*  then you can call the 'Set' routine with the channel (0 for  *''*  channel A, 1 for channel B) and the value (from 0 to 4095).  *''*  MCP4921 uses will only use channel 0                         *VAR  byte CS, SCK, SDI  PUB Init(inCS, inSCK, inSDI)  CS := inCS  SCK := inSCK  SDI := inSDI    dirA[SDI]~~  dirA[SCK]~~  dirA[CS]~~  outA[CS] := 1   outA[SCK] := 0PUB Set(Channel, Value) | data  '        Channel,        Gain,       Shutdown,   Value  data := (Channel << 15) + (1 << 13) + (1 << 12) + Value  data ><= 16  outa[CS] := 0  repeat 16    outa[SDI] := data & 1    outa[SCK] := 1    outa[SCK] := 0    data >>= 1  outA[CS] := 1   