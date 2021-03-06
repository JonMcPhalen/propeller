{{
┌───────────────────────────┬───────────────────┬────────────────────────┐
│ HM55B_Dual_Demo.spin v1.0 │ Author: I.Kövesdi │ Release: 20 April 2009 │
├───────────────────────────┴───────────────────┴────────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│  This PST terminal application exercises the HM55B_Dual_Driver object. │
│ This driver object can control two HM55B modules that may form a 3-axis│
│ magnetometer unit. The driver can be used in a single sensor setup, as │
│ well. It needs only one additional COG for its PASM code for both      │
│ sensors.                                                               │ 
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│ -Electronic compassing is an effective way to provide absolute heading │
│ information for a mobile robot. A single antenna GPS can give heading  │
│ information but this inherently lags the movement of the robot because │
│ the derived heading requires previous position data. If the robot were │
│ to stop and change direction, a common scenario, a GPS could not tell  │
│ wether it is heading in the wanted new direction or not.               │
│ -Tilting the sensor would expose it to portions of the Earth's vertical│
│ magnetic field component and reduce its exposure to the horizontal     │
│ field component. This could result in either as an increase or decrease│
│ of the measured total field strength, depending on local inclination   │
│ angle and the direction and degree of tilt. For us, it is further      │
│ important, that the tilt creates substantial heading error, as well.   │
│ For a 2-axis sensor one degree of small tilt causes about two degrees  │
│ of heading error, depending on the location. However, when we have     │
│ 3-axis magnetometer data and a good mathematical model of the Earth's  │
│ magnetic field, we can figure out the attitude (pitch, roll and last   │
│ but not least, the heading) of the robot in most of its orientations.  │
│ -Attitude uncertainty remains only when one axis of the 3-axis sensor  │
│ magnetometer points directly parallel with the field vector. Any       │
│ rotation around this axis would not change measured values. However,   │
│ these poses are most uncommon for a horizontally mounted sensor on a   │
│ terrain robot. But to cope with this situation, too, we can apply a    │
│ 3-axis accelerometer together with the 3-axis magnetometer. With these │
│ the attitude of the robot can always be approximated with reasonable   │
│ accuracy. The H48C/HM55B(2x) sensor companion can yield about - or     │
│ better than - two degrees of attitude accuracy after careful general 3D│
│ calibration. The attitude estimation can be made easily with the triad │
│ algorithm using the IGRF-10 or WMM2005 mathematical models of the      │
│ Earth's magnetic field.                                                │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  With the HM55B_Dual_Driver one can obtain single shot data or can use │
│ the continuous measurement mode in the background. Using single shot   │
│ readouts sparsely the average current consumption of the sensor can be │
│ decreased considerably when compared with those of the continuous      │
│ measurement mode.                                                      │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘


Schematics for 3-wire SPI interface of the HM55B module


                  ┌────────┬┬────────┐
                  │            │
                  │       └┘└┘       │          
            ┌────│1   •┌──────┐    6│── +5V                                     
            │ 1K  │     │ X    │     │                   
       DIO ┻──│2    │     │    5│── /EN                 
                  │     │ └─Y │     │                                       
          VSS ──│3    └──────┘    4│── CLK                               
                  │      HM55B       │                                          
                  │                  │ 
                  └──────────────────┘



Connection of Prop lines to HM55B sensor(s)
   
  P ├A0───────────────────────> To DIO|1(-1K-2) of HM55B(1)                                
    │                                          
  8 ├A1───────────────────────> To /EN|5        of HM55B(1)                                     
    │                                           
  X ├A2───────────────────────> To CLK|4        of HM55B(1)                                   
    │ ------------------------------------------------------
  3 ├A3───────────────────────> To DIO|1(-1K-2) of HM55B(2)                                  
    │                                          
  2 ├A4───────────────────────> To /EN|5        of HM55B(2)                                      
    │                                           
  A ├A5───────────────────────> To CLK|4        of HM55B(2)     



}}


CON

_CLKMODE = XTAL1 + PLL16X
_XINFREQ = 5_000_000


CON     

'Propeller pin assignments to HM55B lines
_DIO1      = 0   
_EN1       = 1
_CLK1      = 2    

_DIO2      = 3   
_EN2       = 4
_CLK2      = 5      
   


VAR     

LONG       cog_ID 
LONG       mode, hm55b1, hm55b12

OBJ

DBG        : "FullDuplexSerialPlus"    'From Parallax Inc.
                                       'Propeller Education Kit
                                       'Objects Lab v1.1
                                       
HM55B      : "HM55B_Dual_Driver"       'v1.0


DAT '------------------------Start of SPIN code---------------------------
   

PUB DoIt | oK, aCogID                     
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ DoIt │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Demonstrates the HM55B Dual driver
'' Parameters: None
''    Results: None
''+Reads/Uses: /In CON section Prop pin assignments to HM55B lines
''    +Writes: -cog_ID, mode (global variables)
''      Calls: FullDuplexSerialPlus------->DBG.Start
''                                         DBG.Str
''                                         DBG.Dec 
''             HM55B_Dual_Driver---------->HM55B.StartCOG
''                                         HM55B.StopCOG
''             Single_Mode_demo, Dual_Mode_demo  
'-------------------------------------------------------------------------
DBG.Start(31, 30, 0, 38400)            'Initialize terminal UART

WAITCNT(8 * CLKFREQ + CNT)

DBG.Str(STRING(16, 1))

DBG.Str(STRING("HM55B Demo started..."))
DBG.Str(STRING(10, 13))
DBG.Str(STRING(10, 13))

aCogID := @cog_ID

'Mode selection
mode := 1                               'For single sensor setup
'mode := 2                               'If you have a dual sensor setup

CASE mode
  1:
    hm55b1 := HM55B.StartCOG(mode,_EN1,_CLK1,_DIO1,0,0,0,aCogID)
    oK := hm55b1    
  2:
    hm55b12:=HM55B.StartCOG(mode,_EN1,_CLK1,_DIO1,_EN2,_CLK2,_DIO2,aCogID)
    oK := hm55b12
  OTHER:
    oK := FALSE
    
IF oK
  CASE mode
    1:
      DBG.Str(STRING("HM55B Dual Driver started in single mode in COG "))
      DBG.Dec(cog_ID)
      DBG.Str(STRING(10, 13))
      WAITCNT(2 * CLKFREQ + CNT)
      SingleMode_Demo
      
    2:
      DBG.Str(STRING("HM55B Dual Driver started in dual mode in COG "))
      DBG.Dec(cog_ID)
      DBG.Str(STRING(10, 13))
      WAITCNT(2 * CLKFREQ + CNT)
      DualMode_Demo

  DBG.Str(STRING(10, 13, 13))
  DBG.Str(STRING("HM55B Demo terminated normally."))
  HM55B.StopCOG
      
ELSE
  DBG.Str(STRING("Some error occured. Check software/hardware..."))
'-------------------------------------------------------------------------  

    
PRI SingleMode_Demo | bX, bY, time
'-------------------------------------------------------------------------
'--------------------------┌─────────────────┐----------------------------
'--------------------------│ SingleMode_Demo │----------------------------
'--------------------------└─────────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates the HM48B Dual Driver in single sensor
'             configuration
' Parameters: None
'    Results: None
'+Reads/Uses: None
'    +Writes: None
'      Calls: FullDuplexSerialPlus-------->DBG.Str
'                                          DBG.Dec
'             HM55B_Dual_Driver----------->HM55B.Reset_1
'                                          HM55B.Read_1
'                                          HM55B.Start_1
'                                          HM55B.Get_1
'-------------------------------------------------------------------------
DBG.Str(STRING(16, 1))
DBG.Str(STRING("Single Mode Demo..."))
DBG.Str(STRING(10, 13))
DBG.Str(STRING(10, 13)) 

WAITCNT(2 * CLKFREQ + CNT)

DBG.Str(STRING(16, 1))
DBG.Str(STRING("350 Single Shot readouts of 1st sensor"))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("for about 10 seconds...")) 

WAITCNT(4 * CLKFREQ + CNT)

HM55B.Reset_1
REPEAT 350
  HM55B.Read_1(@bX, @bY)
  DBG.Str(STRING(16,1))     
  DBG.Str(STRING("Bx="))
  DBG.Dec(bX)
  DBG.Str(STRING("  "))
  DBG.Str(STRING(10, 13))
  DBG.Str(STRING("By=")) 
  DBG.Dec(bY)
  DBG.Str(STRING("  "))
  
DBG.Str(STRING(16, 1))
DBG.Str(STRING("10 Readouts of 1st sensor at 1Hz rate with continuous"))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("measurement mode in the background...")) 

WAITCNT(4 * CLKFREQ + CNT)

HM55B.Reset_1
HM55B.Start_1
time := CNT
REPEAT 10
  WAITCNT(time + CLKFREQ)
  time += CLKFREQ 
  HM55B.Get_1(@bX, @bY)
  DBG.Str(STRING(16,1))     
  DBG.Str(STRING("Bx="))
  DBG.Dec(bX)
  DBG.Str(STRING("  "))
  DBG.Str(STRING(10, 13))
  DBG.Str(STRING("By=")) 
  DBG.Dec(bY)
  DBG.Str(STRING("  ")) 
'-------------------------------------------------------------------------  

  
PRI DualMode_Demo | bX1, bY1, bX2, bY2, time
'-------------------------------------------------------------------------
'----------------------------┌───────────────┐----------------------------
'----------------------------│ DualMode_Demo │----------------------------
'----------------------------└───────────────┘----------------------------
'-------------------------------------------------------------------------
'     Action: Demonstrates the HM48B Dual Driver in dual sensor
'             configuration
' Parameters: None
'    Results: None
'+Reads/Uses: None
'    +Writes: None
'      Calls: FullDuplexSerialPlus-------->DBG.Str
'                                          DBG.Dec
'             HM55B_Dual_Driver----------->HM55B.Reset_1
'                                          HM55B.Reset_2
'                                          HM55B.Read_1
'                                          HM55B.Read_2
'                                          HM55B.Start_12
'                                          HM55B.Get_12
'-------------------------------------------------------------------------
DBG.Str(STRING(16, 1))
DBG.Str(STRING("Dual Mode Demo..."))
DBG.Str(STRING(10, 13))
DBG.Str(STRING(10, 13)) 

WAITCNT(2 * CLKFREQ + CNT)

DBG.Str(STRING(16, 1))
DBG.Str(STRING("175 Single Shot readouts of both sensors "))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("for about 10 seconds..."))  

WAITCNT(4 * CLKFREQ + CNT)

HM55B.Reset_1
HM55B.Reset_2
time := CNT
REPEAT 175
  HM55B.Read_1(@bX1, @bY1)
  HM55B.Read_2(@bX2, @bY2) 
  DBG.Str(STRING(16,1))     
  DBG.Str(STRING("Bx1="))
  DBG.Dec(bX1)
  DBG.Str(STRING("  "))
  DBG.Str(STRING(10, 13))
  DBG.Str(STRING("By1=")) 
  DBG.Dec(bY1)
  DBG.Str(STRING("  "))
  DBG.Str(STRING(10, 13)) 
  DBG.Str(STRING("Bx2="))
  DBG.Dec(bX2)
  DBG.Str(STRING("  "))
  DBG.Str(STRING(10, 13))
  DBG.Str(STRING("By2=")) 
  DBG.Dec(bY2)
  
DBG.Str(STRING(16, 1))
DBG.Str(STRING("10 Readouts of both sensors at 1Hz rate with continuous"))
DBG.Str(STRING(10, 13))
DBG.Str(STRING("measurement mode in the background...")) 

WAITCNT(4 * CLKFREQ + CNT)

HM55B.Reset_1
HM55B.Reset_2
HM55B.Start_12
time := CNT
REPEAT 10  
  HM55B.Get_12(@bX1, @bY1, @bX2, @bY2)
  DBG.Str(STRING(16,1))     
  DBG.Str(STRING("Bx1="))
  DBG.Dec(bX1)
  DBG.Str(STRING("  "))
  DBG.Str(STRING(10, 13))
  DBG.Str(STRING("By1=")) 
  DBG.Dec(bY1)
  DBG.Str(STRING("  "))
  DBG.Str(STRING(10, 13)) 
  DBG.Str(STRING("Bx2="))
  DBG.Dec(bX2)
  DBG.Str(STRING("  "))
  DBG.Str(STRING(10, 13))
  DBG.Str(STRING("By2=")) 
  DBG.Dec(bY2)
  WAITCNT(time + CLKFREQ)
  time += CLKFREQ 
'-------------------------------------------------------------------------  


DAT '---------------------------MIT License-------------------------------


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}                                  