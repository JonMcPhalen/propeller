{{
CW Keyer Sinus.spin

Copyright (c) 2014 Thierry Eggen, ON5TE
See end of file for terms of use 

The signal generator code comes thanks to Johannes Ahlebrand (see OBEX)

  This CW keyer is currently in use in a Ham Radio UHF repeater.

  Being a non-blocking process, it requires one COG.

  Calls:
        Start :      initializes the local parameters based on the following
                     pin     : pin via which the CW signal is delivered as synthesized sinusoide with PWM rectangular signal
                     pitch   : CW tone frequency in Hz
                     speed   : approximate speed in WPM
                     volume  : attenuator (see propellersignalgenerator)
                     busypin : this pin is ON when the keyer is busy transmitting, may be used for flow control withe anoher COG or a LED, or ...
                               ignored if value outside range 0..31    
        Stop :       frees the COG and obviously stops transmission
        Send :       places the zero-terminated ascii string into the transmission buffer
        SetVolume :  range 5..0, 0 being maximum volume and 5 being maximum damping at approx 6 dB per step       

  How it works:                                
        When a message is received from the calling program, it is inserted into the TxBuffer and the control is sent back to the caller, provided there is enough space free
        in the buffer. The KeyerLoop then extracts the characters from the buffer one by one and sends them to tha keyer process, at the same time
        it frees the space in the buffer. Buffer management is done via a quasi circular buffer and two pointers NextToSend and NextToFill.
        The pin BusyPin may be used to indicaqte to any other COG that the keyer is busy transmitting or idle (its buffer is empty), for flow control
        purpose or anything else you want.
        We have here a non blocking process, in our case, the repeater software doesn't need to wait until message has been sent to do something else.
        HOWEVER, if the buffer is full, then we operate as back pressure flow control and the calling program has to wait until his last message is completely in the buffer.
        In our case, a buffer of 20 is large enough.
  Notes
        - the so called "circular buffer" is not really one, but a sliding window of BufferLength size mapped on a virtual string of more than two gigabytes,
          so overflow is theoretically possible after continuous transmission for more than 25 years at 15 wpm ...
        - CW code is expected to be OK and has been checked, however please keep me informed if you find anything wrong  
        - if you want to make the calls blocking until Send command fully executed, just add  "waitpeq(0, |< busypin, 0) 'Wait for busypin to go low" after the Send
          command in the calling program
        - another way is to remove everyting related to the circular buffer and replace the SendOneChar call in PUB Send with KeyOneChar. This may save one COG if needed.  
}}
CON
  BufferLength = 20             ' increase at will, but OK for most of the cases
       
  On           = 1                                        
  Off          = 0
OBJ

  Sg: "PropellerSignalGenerator"
  
VAR
  long NextToSend, NextToFill   'pointers in the circular buffer
  long cog
  Long CWPin, CWPitch ,CWspeed, dotcycles,dashcycles,gapcycles,idlecycles, CWVolume
  Long KeyerBusyPin
  Long Stack[30]
  byte morsebyte
  byte TxBuffer[BufferLength]
  byte mybyte
  
PUB start(pin,pitch,speed,volume, busypin) : okay
                                       ' make parameters local copy avilable to PUBs and PRIs of this source file
  CWPin           := pin                                ' LF CW output pin
  CWPitch         := pitch                              ' CW pitch
  CWSpeed         := speed                              ' CW speed in WPM (approximate)
  KeyerBusyPin    := busypin                            ' Pin to indicate that keyer is busy (LED or synchro ...)
  CWVolume        := volume
                                                        ' compute CW dots, dashes and spaces durations
  dotcycles       := (2*clkfreq)/(3*CWSpeed)            ' CWspeed*1.5     ' dot duration in clock cycles
  dashcycles      := dotcycles * 3                      ' dat   "      "   "      "
  gapcycles       := dotcycles                          ' inter dot/dash in same charcter
  idlecycles      := dotcycles * 2                      ' inter character gap
  
  stop                                                  ' make sure keyer is STOPped

  ' init circular buffer pointers
  NextToFill := 0
  NextToSend := 0               

  sg.start(CWPin, 32,32)                                ' tell audio signal generator to start, output on CWPin ...
  sg.setParameters(sg#SINUS, 0, 0, 0)                   ' ..., sinus waveform, no frequency now, no damping and no duty cycle

  okay := cog := Cognew(KeyerLoop,@Stack) + 1           ' launch keyer on its own
      
PUB Stop   {{Stop keyer; frees a cog.}}
  sg.stop                      ' stop first audio signal generator
  dira[CWPin] := 0
  if cog
    cogstop(cog~ - 1)

PUB send(stringptr)  {{Send zero terminated string. Parameter: stringptr - pointer to zero terminated string to send.}}
  repeat strsize(stringptr)
    SendOneChar(byte[stringptr++])

Pub setvolume(vol)
  CWVolume := vol
  sg.setdamplevel(CWVolume)

Pub SendOneChar(bytechr) ' Insert bytechr in the circular buffer 
  repeat while (NextToFill- NextToSend) =>  BufferLength
  TxBuffer[NextToFill//BufferLength] := bytechr
  NextToFill++
         
pri KeyerLoop                                           ' loop on circular buffer to extract character to send if any
  if keyerbusypin > -1 AND keyerbusypin  < 32
    dira[KeyerBusyPin] := 1  
  repeat
    repeat while NextToSend == NextToFill               ' pointers equals: nothing to do
      outa[KeyerBusyPin] := 0
    outa[KeyerBusyPin] := 1      
    mybyte :=  TxBuffer[NextToSend//BufferLength]       ' extract character to send
    KeyOneChar(mybyte)                                  ' send it to morse code keyer
    NextToSend++                                        ' update circular buffer pointer

Pri KeyOneChar(charin) | StartBit, CurrentBit , i       ' get one ASCII character, convert it in Morse and send it
  morsebyte := cwtable[charin]                          'extract CW pattern
  StartBit := Off
  Repeat i from 7 to 0                                  ' read bit per bit from MSB to LSB
    CurrentBit := GetBitByte(@MorseByte,i)              ' the first bit ON is a flag
    if StartBit == Off                                  ' not yet ...
      if CurrentBit == 1                                ' if yes, startbit := 1 to tell 
        StartBit := On                                  ' that subsequent bits meaningful morse bits
        Next
    else
      sg.setfrequency(CWPitch)                          ' start sending tone    
      if CurrentBit == 0                                ' dot or dash?
        waitcnt(dotcycles + cnt)                        ' keep tone ON for a DOT duration
      else
        waitcnt(dashcycles + cnt)                       ' keep tone ON for a DASH duration
      sg.setfrequency(0)                                ' stoptone
      waitcnt(gapcycles + cnt)                          ' ... form GAP duration minimum  
  waitcnt(idlecycles + cnt)                             ' quiet for inter-character duration

Pri GetBitByte(variableAddr,bitpointer) | localcopy
  localcopy := byte[variableAddr]
  return ((localcopy & (1<<bitpointer)) >> bitpointer)
   
DAT
{
Each byte may represent an ASCII character equivalent in Morse code, when it exists.

A Morse code character is right-justified inside a byte, a bit zero represents a dot
and a bit one represents a dash. It is preceded with a one and the remaining
most significant bits are set to zero. 

So a "B" in Morse is _... (dash dash dash dot) and will be coded as %00011110
and an "E" (dot) shall be coded as %00000010.

We are limited to a series of seven consecutive dor or dashes.
If it's a problem, we can use 16 bits words.
}
CWTable byte  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        byte  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        'x!"x$x&'()x+,-./
        byte  0,%01101011,%01010010,0,%10001001,0,%00101000,%01011110,%00110110,%01101101,0,%00101010,%01110011,%01100001,%01010101,%00110010
        '0123456789:;x=x?                                                 
        byte  %000111111,%00101111,%00100111,%00100011,%00100001,%00100000,%00110000,%00111000,%00111100,%00111110,%01111000,%01101010,0,%00110001,0,%01001100
        '@ABCDEFGHIJKLMNO
        byte  %01011010,%00000101,%00011000,%00011010,%00001100,%00000010,%00010100,%00001110,%0010000,%00000100,%00010111,%00001101,%00010100,%00000111,%00000110,%00001111
        'PQRSTUVWXYZ[\
        byte  %00010110,%00011101,%00001010,%00001000,%00000011,%00001001,%00010001,%00001011,%00011001,%00011011,%00011100,0,0,0,0,0
        ''abcde  etc.
        byte  0,%00000101,%00011000,%00011010,%00001100,%00000010,%00010100,%00001110,%0010000,%00000100,%00010111,%00001101,%00010100,%00000111,%00000110,%00001111
        'pqrstuvwxyz[\
        byte  %00010110,%00011101,%00001010,%00001000,%00000011,%00001001,%00010001,%00001011,%00011001,%00011011,%00011100,0,0,0,0,0
          

{{   MIT License:
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

}}             
  