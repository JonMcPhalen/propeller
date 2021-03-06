
{{

┌────────────────────────────────────────────────┐
│                                                │                          
│ Author: Brian McClure                          │
|  Email: brian.mcclure@gmail.com                │
│    web: www.n8vhf.com                          │
│                                                │               
│ Copyright (c) 2012                             │
│ See end of file for terms of use.              │
│                                                │                
└────────────────────────────────────────────────┘

I2C Interface for the Honeywell HIH-6130/6131 series of temperature and humidity sensors.
This library requires the "Basic_I2C_Driver" library.
I used the one included with Tim Moore's I2C LMM Drivers  http://obex.parallax.com/objects/636/

Data sheets for the sensors are at  http://sensing.honeywell.com/index.php?ci_id=3106&defId=44872

}}

OBJ
  i2c   : "basic_i2c_driver"
  uarts : "pcFullDuplexSerial4FC" 
  
VAR


CON
   ACK      = 0                        ' I2C Acknowledge
   NAK      = 1                        ' I2C No Acknowledge

DAT
  

PUB Init(SCL, _deviceAddress)
i2c.Initialize(0)

        
PUB readData32(SCL,device_address) : value     '//modified the read routines in Basic_I2C_Driver to make a dedicated HIH sensor function



  i2c.initialize(0)
  i2c.start(SCL)
  i2c.writeNS(SCL,device_address | 0)
  pause(50)                     '// pause for 50 ms to allow sensor to finish measurements
                                '// too short of a pause can cause stale data

  'uarts.str(0,string("Start Read",13,13))  '//used for debugging
  i2c.start(SCL)
  i2c.write(SCL,device_address | 1)  
  value := i2c.read(SCL,ACK)
  value <<= 8
  value |= (i2c.read(SCL,ACK) & $ff)
  value <<= 8
  value |= (i2c.read(SCL,ACK) & $ff)
  value <<= 8
  value |= (i2c.read(SCL,NAK) & $ff)
  i2c.stop(SCL)
  return value



PRI pause(Duration)  
waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)     '//found this delay function somewhere, can't remember who wrote it. Sorry
return





{{
MIT License   http://www.opensource.org/licenses/mit-license.php

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies
 or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
}}