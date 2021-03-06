{{


                **************************************************
                 IMU_KFDOF V1.1       Kalman Filter on 5DOF data
                **************************************************
                   coded by Jason Wood jtw.programmer@gmail.com        
                ************************************************** 
                         other coders has been noted
                **************************************************

┌──────────────────────────────────────────┐
│ Copyright (c) 2008 Jason T Wood          │               
│     See end of file for terms of use.    │               
└──────────────────────────────────────────┘
                
  This object pulls readings off the 5DOF Accelerometer/Gyro from SparkFun
  http://www.sparkfun.com/commerce/product_info.php?products_id=741
  Using a MCP3208 8 Channel 12bit ADC.
  http://www.mouser.com/search/ProductDetail.aspx?R=MCP3208-CI%2fSLvirtualkey57940000virtualkey579-MCP3208CISL
  It then passes that information through a Kalman Filter to get true Angle, Rate and q_bias.

  This requires the MCP3208 Object written by Chip Gracey.
  It also requires Float32Full

  

           ┌───────────────────┐
1) 3.3v    │  ┌─────┐  YR-)   │
2) GND     │  │     │ ┌───┐    │
3) xRate   │  │     │ │   │    │             
4) yRate   │  └─────┘ └───┘    │            CLK = P27 
5) VRef    │       •Z        │            DIO = P26
6) ST      │ XR          ─Y X │            CS  = P25
7) Z Accl  │ 1 2 3 4 5 6 7 8 9 │
8) Y Accl  │ ° ° ° ° ° ° ° ° ° │            MCP3208
9) X Accl  └─│─│─│─│─│─│─│─│─│─┘          ┌──°───────┐
               │ │ │ S │ │ └─X Accl────│0       16│─┬ +3.3V
             + G │ │ │ T │ └─Y Accl──────│1       15│─┘
             3 N │ │ │   └─Z Accl────────│2       14│── GND
             . D │ │ └─Volt Ref──────────│3       13│── CLK:PIN
             3   │ └─Y Rate──────────────│4       12│─┬ DIO:PIN
             V   └─X Rate────────────────│5       11│─┘  
                                   VDD ──│6       10│── CS:PIN
                                       ──│7        9│── GND
                                          └──────────┘

  
  

          
/* $Id: tilt.c,v 1.1 2003/07/09 18:23:29 john Exp $
 *
 * 1 dimensional tilt sensor using a dual axis accelerometer
 * and single axis angular rate gyro.  The two sensors are fused
 * via a two state Kalman filter, with one state being the angle
 * and the other state being the gyro bias.
 *
 * Gyro bias is automatically tracked by the filter.  This seems
 * like magic.
 *
 * Please note that there are lots of comments in the functions and
 * in blocks before the functions.  Kalman filtering is an already complex
 * subject, made even more so by extensive hand optimizations to the C code
 * that implements the filter.  I've tried to make an effort of explaining
 * the optimizations, but feel free to send mail to the mailing list,
 * autopilot-devel@lists.sf.net, with questions about this code.
 *
 * 
 * (c) 2003 Trammell Hudson <hudson@rotomotion.com>
 *
 *************
 *
 *  This file is part of the autopilot onboard code package.
 *  
 *  Autopilot is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *  
 *  Autopilot is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with Autopilot; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */          
}}
CON

  ' Pitch and Rolln
  Pitch = 0
  Roll = 1

  ' These are the pens on the ADC connected to the 5DOF circuit.
  ' You may set these up any way you would like but it will not
  ' follow my pretty picture above any more.
  xAxis = 0
  yAxis = 1
  zAxis = 2
  VRef = 3
  yRate = 4
  xRate = 5
  supply = 6
  
OBJ
  
  MCP           :               "MCP3208"
  fMath         :               "Float32Full"
  KF[2]         :               "KalmanFilter"         
    
VAR

  ' This cog's ID
  long cog

  ' ADC Pens on the Prop. 
  long CS 
  long DIO
  long CLK

  ' I'm not real sure how much stack space is needed here
  ' So I just made it big. Once i've gotten it all working
  ' I'll see about srinking it to fit more control logic.
  long stack0[120]

  ' Array of ADC readings ... Possable of 8 channels from MCP3208
  long tiltReadings[8]
  long a2tan_angle[2]
  long totalRev

  ' 0'ing values
  long yRate0
  long xRate0  
  long Axis0  
   
  
pub start(_CS, _DIO, _CLK)
{{
  Assign the ADC pens on the Prop then
  start the COG to run the kalman filter
  returning the cog's ID
}}

  longmove(@CS, @_CS, 3)
  return cog := cognew(go, @stack0) + 1
       
pub stop
{{
  Stop the kalman filter, MCP3208 driver and Float driver
}}
  MCP.stop
  fMath.stop
  cogstop(cog)

pub get_angle_Pitch
{{
  Return the current Kalman Filtered angle as a Float in Degrees
}}
  return KF[Pitch].get_angle
  
pub get_q_bias_Pitch
{{
  Return the current q_bias of the gyro as a Float
}}
  return KF[Pitch].get_q_bias
  
pub get_rate_Pitch
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return KF[Pitch].get_rate

pub get_angle_Roll
{{
  Return the current Kalman Filtered angle as a Float in Degrees
}}
  return KF[Roll].get_angle
  
pub get_q_bias_Roll
{{
  Return the current q_bias of the gyro as a Float
}}
  return KF[Roll].get_q_bias
  
pub get_rate_Roll
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return KF[Roll].get_rate

  
pub get_y_rate
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return tiltReadings[yRate]

pub get_x_rate
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return tiltReadings[xRate]
                  
pub get_y_axis
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return tiltReadings[yAxis]

pub get_z_axis
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return tiltReadings[zAxis]

pub get_x_axis
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return tiltReadings[xAxis]

pub get_a2tan_angle_Pitch
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return a2tan_angle[0]

pub get_a2tan_angle_Roll
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return a2tan_angle[1]

pub get_Revs
{{
  Return the current biased rate of the gyro as a Float in Degrees/sec
}}
  return KF[0].get_Revolutions
                                                                             
pri go | lastTime, pidCalcTime, kalmanCalcTime, tilt_jmax, tilt_filter[5], tilt_idx, f1, tfCount, tmpCO, last_time, holdXPos, holdYPos, holdZPos, Normolize, LastA2Tan, holdA2Tan[2]


{{


Main Thread:
─────────────
PRI  go   
    get ADC readings and format them into normat date
    then pass them through a kalman filter:

  
}}
 
  ' Start the ADC chip using 7 of the 8 channels
  MCP.Start(DIO, CLK, CS, %01111111)                       
  ' Start the floating point engin.
  fMath.start
  ' Start the Pitch Kalman Filter
  KF[Pitch].start
  ' Start the Roll Kalman Filter
  KF[Roll].start
    
  ' wait a second for some equilibrium
  waitcnt((80_000_000*1) + cnt)

  ' get a few ADC readings for 0'ing later 
  tiltReadings[VRef] := MCP.in(VRef)
  tiltReadings[supply] := MCP.in(supply)
  yRate0 := MCP.in(yRate)
  xRate0 := MCP.in(xRate) 
  Axis0 := tiltReadings[supply] / 2 

  ' setup some defaults
  LastA2Tan := 0.0
  totalRev := 0
  
  repeat


    ' X,Y,Z axis readings
    holdXPos := fMath.FFloat(MCP.in(xAxis) - 2048)
    holdYPos := fMath.FFloat(MCP.in(yAxis) - 2048)
    holdZPos := fMath.FFloat(MCP.in(zAxis) - 2048)
     
    'Normolize := fMath.FSqr(fMath.FAdd(fMath.FAdd(fMath.FMul(holdZPos, holdZPos), fMath.FMul(holdXPos, holdXPos)), fMath.FMul(holdYPos, holdYPos)))
     
    tiltReadings[xAxis] := holdXPos 'fMath.FSub(holdXPos, Normolize)
    tiltReadings[yAxis] := holdYPos
    tiltReadings[zAxis] := holdZPos

    a2tan_angle[Pitch] := fMath.Degrees(fMath.ATan2(tiltReadings[yAxis], tiltReadings[zAxis]))   
    a2tan_angle[Roll] := fMath.Degrees(fMath.ATan2(tiltReadings[xAxis], tiltReadings[zAxis]))   

{{

    ┌───────────────────────────────────────────┐ 
    │ Convert gyro rate to deg/sec              │
    │                                           │
    │ My Setup                                  │
    │ 2mV/deg/sec                               │
    │ 500deg/sec                                │
    │                                           │
    │ 0deg/sec=2048                             │
    │ 500deg/sec=4096adu=2048 + 2048            │
    │ each 1deg/sec = 2048/500 = 4.096          │
    │ each 1=1/4.096deg/sec=0.244140625deg/sec  │
    └───────────────────────────────────────────┘


      
}}
    tiltReadings[xRate] := fMath.FMul(fMath.FFloat(MCP.in(xRate) - xRate0), 0.24414)
    tiltReadings[yRate] := fMath.FMul(fMath.FFloat(MCP.in(yRate) - yRate0), 0.24414)
                                                
    ' Update the Pitch KF
    KF[Pitch].state_update( tiltReadings[xRate] )
    KF[Pitch].kalman_update( a2tan_angle[Pitch] )

    ' Update the Roll KF    
    KF[Roll].state_update( tiltReadings[yRate] )
    KF[Roll].kalman_update( a2tan_angle[Roll] )     


{{
    ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                                   TERMS OF USE: MIT License                                                  │                                                            
    ├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
    │Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
    │files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
    │modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
    │is furnished to do so, subject to the following conditions:                                                                   │
    │                                                                                                                              │
    │The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
    │                                                                                                                              │
    │THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
    │WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
    │COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
    │ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
    └──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}       