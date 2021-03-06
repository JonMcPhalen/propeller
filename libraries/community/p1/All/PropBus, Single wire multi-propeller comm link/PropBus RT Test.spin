{{
  Prop Bus, Test Driver
  File: PropBusTest.spin
  Version: 1.0
  Copyright (c) 2014 Mike Christle
}}

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  BUS_BIT_RATE = 1_100_000

'  _clkmode = RCFast

  BUF_SIZE = 10

VAR

  word  RTBuf[BUF_SIZE], IncrBuf[BUF_SIZE], RTCmnd
   
OBJ

  pst : "Parallax Serial Terminal"
  rt  : "PropBusRT"
  
PUB MainRoutine | I, J, V

  pst.Start(115200)

  rt.AddBuffer(1, @RTBuf, BUF_SIZE, rt#RECEIVE_BUFFER)
  rt.AddBuffer(2, @RTBuf, BUF_SIZE, rt#TRANSMIT_BUFFER)
  rt.AddBuffer(3, @IncrBuf, BUF_SIZE, rt#TRAN_INCR_BUFFER)
  rt.SetBitRate(BUS_BIT_RATE)

  ' Single Wire
  rt.Start(16, 16, -1, @RTCmnd)

  ' Two Wire
'  rt.Start(0, 2, -1, @RTCmnd)

  ' Three Wire
'  rt.Start(18, 20, 22, @RTCmnd)

  dira := $80_0000
  repeat
    waitcnt(cnt + 8_000_000)
    outa ^= $80_0000


{{
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}                        