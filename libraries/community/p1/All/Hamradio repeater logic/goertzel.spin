''***************************************
''*  Multi-frequency, real time audio   *
''*  ADC and Goertzel waveform analyzer *
''*  Author: Phil Pilgrim               *
''*  Copyright (c) 2009 Phil Pilgrim    *
''*  See end of file for terms of use.  *
''***************************************

CON

  SINE          = $e000
  MAX_BINS      = 16

VAR

  byte  cogno

PUB start(inp_pin, fb_pin, freq_count, freq_addr, count_addr, sampling_rate, goertzel_rate, goertzel_n) | i
' Sets up the Goertzel analyzer:
'   inp_pin is the sigma-delta audio input.
'   fb_pin is the sigma-delta feedback pin.
'   freq_count is the number of frequencies being analyzed.
'   freq_addr points to an array of longs containing the frequencies being analyzed.
'     During operation this array will be continuously refreshed with the Goertzel power coefficients
'     for the frequencies selected.
'   count_addr points to a long which will be incremented after each result is posted at freq_addr.
'     This can be used to synchronize the reading of results.
'   sampling_rate is the frequency (Hz) at which the ADC is sampled.
'   goertzel rate is the number of times per second to report results.
'   goertzel_n is the number of samples required to obtain each result. The higher this number is, the
'     narrower the passband of the consequent filters.

' This algorithm will seize up if an abusive combination of freq_count, sampling_rate, goertzel_rate, and
' goertzel_n is requested. This happens when the workload is too great for the rate(s) requested, causing a
' waitcnt target to get passed before the waitcnt occurs. If this happens (and it will be obvious when it
' does), pick less aggressive parameters and try again.

  stop
  dt       := clkfreq / sampling_rate                                                  
  interval := clkfreq / goertzel_rate - (goertzel_n + 1) * dt #> goertzel_n * 500
  nsamples := goertzel_n
  nbins    := freq_count
  bin_addr := freq_addr
  cnt_addr := count_addr
  ctra0    := %01001 << 26 |  fb_pin << 9 |  inp_pin      ' setup CTRA as ADC and set Pins Input and Feedback 
  dira0    := 1 << fb_pin                                 ' feedback pin en sortie

  repeat i from 0 to freq_count - 1
    coeffs[i] := 2 * cos($2000 * long[freq_addr][i] / sampling_rate)

  return cogno := cognew(@goertzel, 0) + 1

PUB stop

  if (cogno)
    cogstop(cogno - 1)
    cogno~    

PUB cos(x)

'' Cosine of the angle x: 0 to 360 degrees == $0000 to $2000

  return sin(x + $800)

PUB sin(x) : value

'' Sine of the angle x: 0 to 360 degrees == $0000 to $2000

  if (x & $fff == $800)
    value := $1_0000
  elseif (x & $800)
    value := word[SINE][-x & $7ff]
  else
    value := word[SINE][x & $7ff]
  if (x & $1000)
    value := -value

DAT
              org       0
              
goertzel      mov       dira,dira0              'Configure ctra for analog input.                      ' set feedback pin as output 
              mov       ctra,ctra0                                                                     ' set CTRA for ADC
              mov       frqa,#1                                                                        ' set increment to 1
              mov       bias,dt                 'Guess at adc bias level:
              shr       bias,#1                 '  dt / 2.
              mov       time,cnt                'Setup time for measurement interval.
              add       time,dt                 
              mov       pamp,phsa               'Initialize previous adc reading.

main_loop     movd      :zap_pq,#pqs            'MAIN LOOP: Once through for each set of conversions.
              movd      :zap_ppq,#ppqs          'Point to pq and ppq to zero.
              mov       qcnt,nbins

:zap_pq       mov       0-0,#0                  'Zero pq and ppq arrays.
:zap_ppq      mov       0-0,#0
              add       :zap_pq,_0x200
              add       :zap_ppq,_0x200
              djnz      qcnt,#:zap_pq

              mov       scnt,nsamples           'Initialize sample count.

:sample_lp                                      'SAMPLE LOOP: Once through for each audio sample.
              call      #sample                 'Get the next sound amplitude sample.
              mov       qcnt,nbins              'Initialize pointers for bins.
              movs      :get_coeff,#coeffs
              movs      :get_pq,#pqs
              movs      :get_ppq,#ppqs

:bin_lp                                         'BIN LOOP: Once through for each bin.

:get_coeff    mov       t0,0-0                  'Get Goertzel coefficient.
:get_pq       mov       pq,0-0                  'Get q(i-1)
              mov       t1,pq                   'Multiply them.
              call      #fmult
:get_ppq      sub       t0,0-0                  'Subtract q(i-2).
              add       t0,amp                  'Add current sample to get q(i).
              movd      :put_ppq,:get_ppq       'Copy get addresses
              movd      :put_pq,:get_pq         '  to put addresses.
:put_ppq      mov       0-0,pq                  'q(i-2) := q(i-1)
:put_pq       mov       0-0,t0                  'q(i-1) := q(i)
              add       :get_coeff,#1           'Increment get addresses.
              add       :get_pq,#1
              add       :get_ppq,#1
              djnz      qcnt,#:bin_lp           'Back for next bin.

              djnz      scnt,#:sample_lp        'Back for next sample.

              add       time,interval           'Add delay to next sampling epoch.

compute       mov       qcnt,nbins              'Samples complete: begin final Goertzel computation for each bin.
              movs      :get_coeff,#coeffs
              movs      :get_pq,#pqs
              movs      :get_ppq,#ppqs
              mov       bptr,bin_addr
              

:bin_lp                                         'BINLOOP: Once through for each bin.
                                                
:get_coeff    mov       t0,0-0                  't0 := coeff
:get_pq       mov       pq,0-0
:get_ppq      mov       ppq,0-0

              neg       t1,pq
              call      #fmult                  '  * -pq == -coeff * pq
              add       t0,ppq                  '  + ppq == -coeff * pq + ppq
              mov       t1,ppq
              call      #fmult                  '  * ppq == ppq * ppq - coeff * pq * ppq
              mov       ppq,t0                  'Save to temp.
              mov       t0,pq                   't0 := pq
              mov       t1,pq
              call      #fmult                  '  * pq == pq * pq   
              add       t0,ppq                  '  + temp == pq * pq + ppq * ppq - coeff * pq * ppq
              wrlong    t0,bptr                 'Write result to hub.
              add       bptr,#4                 'Increment bin (hub) address.
              add       :get_coeff,#1           'Increment get addresses.
              add       :get_pq,#1
              add       :get_ppq,#1
              djnz      qcnt,#:bin_lp           'Back for next bin.

              add       nresults,#1             'Increment result count,
              wrlong    nresults,cnt_addr       '  and write to hub to indicate another result completed.
              waitcnt   time,dt                 'Wait for inter-sampling inteval to pass.
              mov       pamp,phsa               'Resample adc to establish new baseline.
              jmp       #main_loop              'Go bakc and do it again.

'-------[ sample ]-------------------------------------------------------------

'    Read the ADC (microphone) input.

sample        waitcnt   time,dt                 'Wait for adc value to be accumulated.
              mov       amp,phsa                'Read it.
              sub       amp,pamp                'Subtract the previous reading.
              add       pamp,amp                'pamp := pamp + amp - pamp == pamp
              sub       amp,bias                'Subtract the DC bias.
              shl       bias,#7                 'Compute running average of bias.
              add       bias,amp
              shr       bias,#7
              shl       amp,#2                  'Adjust amplitude.
sample_ret    ret
              
'-------[ fmult ]--------------------------------------------------------------             
                        
'    32 x 16.16 fixed-point signed multiply.

'    in:       t0 = 32-bit integer multiplicand
'              t1 = 32-bit fixed-point multiplier

'    out:      t0 = 32-bit product

fmult         abs     t0,t0 wc                  'Make sure both operands are positive,
              muxc    flags,#SIGN               ' and preserve signs in flags.
              abs     t1,t1 wc
        if_c  xor     flags,#SIGN
              mov     t2,#0                     'Initialize high long of product.
              mov     t3,#32                    'Need 32 adds and shifts.
              shr     t0,#1 wc                  'Seed the first carry.

:loop   if_c  add     t2,t1 wc                  'If multiplier was a one bit, add multiplicand.
              rcr     t2,#1 wc                  'Shift carry and 64-bit product right.
              rcr     t0,#1 wc
              djnz    t3,#:loop                 'Back for another bit.
               
              shr     t0,#16                     'Fractional product is middle 32 bits of the 64.
              shl     t2,#16
              or      t0,t2
              test    flags,#SIGN wc            'Is product negative?
              negc    t0,t0                     '  Yes: Negate it.
fmult_ret     ret

'-------[ Constants and variables ]-------------------------------------------- 

dira0         long      0-0
ctra0         long      0-0
nsamples      long      0-0
nbins         long      0-0
coeffs        long      0-0[MAX_BINS]
bin_addr      long      0-0
cnt_addr      long      0-0
dt            long      0-0
interval      long      0-0

nresults      long      0
_0x200        long      $200

pqs           res       MAX_BINS                        'q(i-1)
ppqs          res       MAX_BINS                        'q(i-2)
bptr          res       1
time          res       1
pamp          res       1
amp           res       1
qcnt          res       1
scnt          res       1
t0            res       1
t1            res       1
t2            res       1
t3            res       1
flags         res       1
q             res       1
pq            res       1
ppq           res       1
bias          res       1


CON

  SIGN          = 1
  
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