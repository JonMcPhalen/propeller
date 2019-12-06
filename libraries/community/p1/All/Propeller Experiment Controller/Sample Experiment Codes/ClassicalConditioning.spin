{{

┌────────────────────────────────────────────┐
│ Classical Conditioning                     │
│ Author: Christopher A Varnon               │
│ Created: 12-20-2012                        │
│ See end of file for terms of use.          │
└────────────────────────────────────────────┘

  The program will present an unconditioned stimulus and a conditioned stimulus for a specified number of trials.
  Several trial types may be used. If a trials of that type are not desired, set the number of trials to 0 to disable them.
  Inhibition trials occur first. Only the conditioned stimulus will be presented. A large number of inhibition trials may cause latent inhibition.
  That is to say that the subject may have difficulty learning a CS/US association if the condition stimulus was presented by itself many times previously.
  Acquisition trials occur next. Both the unconditioned stimulus and the condition stimulus will be presented.
  Extinction trials occur last. Only the condition stimulus will be presented.

  A wide variety of CS/US conditioning procedures can be created by changing the start and stop times of each stimulus within a trial.
  For example, if the US starts at 2 seconds into a trial and stops at 3 seconds into the trial, The CS can come before or after the US.
  To make the CS come before the US, set it to start 0 seconds into the trial (immediately) and stop 2 seconds into the trial.
  To make the CS come after the US, set it to start 3 seconds into the trial and stop 4 seconds into the trial.

  The user will need to specify the pins used for the CS, the US, the response device, the house lights, and the SD card.
  The user will also need to specify the start and stop times of each stimulus, the trial length, and the number of trials of each type.

  Comments and descriptions of the code are provided within brackets and following quotation marks.

}}

CON
  '' This block of code is called the CONSTANT block. Here constants are defined that will never change during the program.
  '' The constant block is useful for defining constants that will be used often in the program. It can make the program much more readable.

  '' The following two lines set the clock mode.
  '' This enables the propeller to run quickly and accurately.
  '' Every experiment program will need to set the clock mode like this.
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  '' The following four constants are the SD card pins.
  '' Replace these values with the appropriate pin numbers for your device.
  DO  = 0
  CLK = 1
  DI  = 2
  CLS = 3                                                                       ' Note this pin is called CLS instead of CS so that CS can be used to refer to conditioned stimulus.

  '' Replace the following values with whatever is desired for your experiment.
  '' By adjusting the start and stop times of the CS and US, a wide variety of procedures can be created.
  '' Note that underscores are used in place of commas.
  '' The underscores are unnecessary and do not change the program, they only make the numbers easier to read.
  TrialLength        = 10_000                                                   ' The duration of the trial. Should be long enough to accommodate both stimulus presentations and an inter-trial interval.
  CS_Start           = 1_000                                                    ' The time during a trial the CS starts.
  CS_Stop            = 3_000                                                    ' The time during a trial the CS ends.
  US_Start           = 2_000                                                    ' The time during a trial the US starts.
  US_Stop            = 3_000                                                    ' The time during a trial the US ends.

  InhibitionTrials   = 0                                                        ' The number of latent inhibition trials where only the CS is presented.
  AcquisitionTrials  = 20                                                       ' The number of acquisition trials where both CS and US are presented.
  ExtinctionTrials   = 0                                                        ' The number of extinction trials where only the CS is presented.

  '' Replace the following values with the pins connected to the devices.
  ResponsePin        = 6
  USPin              = 23
  CSPin              = 22
  HouseLightPin      = 16                                                       ' The house lights will activate only while the experiment is running. Leave the pin disconnected if house lights control is not needed.
  DiagnosticLEDPin   = 17                                                       ' The LED will turn on after the experiment is complete and it is safe to remove the SD card. Leave the pin disconnected if a diagnostic LED is not needed.

  '' Input Event States
  '' These states are named in the constant block to make the program more readable.
  Off     = 0                                                                   ' Off means that nothing is detected on an input.    Example: The rat is not pressing the lever.
  Onset   = 1                                                                   ' Onset means that the input was just activated.     Example: The rat just pressed the lever.
  On      = 2                                                                   ' On means that the input has been active a while.   Example: The rat pressed the lever recently and is still pressing it.
  Offset  = 3                                                                   ' Offset means that the input was just deactivated.  Example: The rat was pressing the lever, but it just stopped.

  '' Output Event States
  OutOn   = 1                                                                   ' The output is on.
  OutOff  = 3                                                                   ' The output is off.

VAR
  '' The VAR or Variable block is used to define variables that will change during the program.
  '' Variables are different from constants because variables can change, while constants cannot.
  '' The variables only be named in the variable space. They will be assigned values later.
  '' The size of a variable is also assigned in the VAR block.
  '' Byte variables can range from 0-255 and are best for values you know will be very small.
  '' Word variables are larger. They range from 0-65,535. Word variables can also be used to save the location of string (text) values in memory.
  '' Long variables are the largest and range from -2,147,483,648 to +2,147,483,647. Most variables experiments use will be longs.
  '' As there is limited space on the propeller chip, it is beneficial to use smaller sized variables when possible.
  '' It is unlikely that most experiments will use the entire memory of the propeller chip.

  word ResponseName                                                             ' This variable will refer to the text description of the response event that will be saved to the data file.
  word CSName                                                                   ' This variable will refer to the text description of the CS event that will be saved to the data file.
  word USName                                                                   ' This variable will refer to the text description of the US event that will be saved to the data file.

  long Start                                                                    ' This variable will contain the starting time of the experiment. All other times will be compared to this time.

  word Trial                                                                    ' This variable will be used note the current trial.

OBJ
  '' The OBJ or Object block is used to declare objects that will be used by the program.
  '' These objects allow the current program to use code from other files.
  '' This keeps programs organized and makes it easier to share common code between multiple programs.
  '' Additionally, using objects written by others saves time and allows access to complicated functions that may be difficult to create.
  '' The objects are given short reference names. These abbreviations will be used to refer to code in the objects.

  '' The Experimental Functions object is the master object for experiments. It is responsible for keeping precise time, as well as saving data.
  exp : "Experimental_Functions"                                                ' Loads experimental functions.

  '' The Experimental Event object works in tandem with Experimental Functions.
  '' Each Experimental Event object is dedicated to keeping track of a specific event, and passing this information along to Experimental Functions.
  '' Each event in an experiment such as key pecks, stimulus lights, tones, and reinforcement uses its own experimental event object.
  Response      : "Experimental_Event"                                          ' Loads response as an experimental event.
  CS            : "Experimental_Event"                                          ' Loads the CS as an experimental event.
  US            : "Experimental_Event"                                          ' Loads the US as an experimental event.
  HouseLight    : "Experimental_Event"                                          ' Loads houselight as an experimental event.

PUB Main
  '' The PUB or Public block is used to define code that can be used in a program or by other programs.
  '' The name listed after PUB is the name of the method.
  '' The program always starts with the first public method. Commonly this method is named "Main."
  '' The program will only run code in the first method unless it is explicitly told to go to another method.

  '' The statement "SetVariables" sets all the variables using a separate method. Scroll down to the SetVariables method to read the code.
  '' A separate method is not needed to set the variables, it can be done in the main method.
  '' However, dividing a program into sections can make it much easier to read.
  exp.startexperiment(DO,CLK,DI,CLS)                                            ' Launches all the code in experimental functions related to timing and saving data. Also provides the SD card pins for saving data.
  SetVariables                                                                  ' Implements the setvariables method. Scroll down to read the code.
  houselight.turnon                                                             ' Turns on the house lights.
  start:=exp.time(0)                                                            ' Sets the variable 'start' to time(0) or the time since 0 - the present.
                                                                                ' In other words, the experiment started now.

  repeat until exp.time(start)>(inhibitiontrials+acquisitiontrials+extinctiontrials)*(triallength)   ' Repeats the indented code until time(start), or time since the experiment started, is greater than the total duration of all trials.
                                                                                                     ' In other words, repeat until the all trials are complete.

    '' The next line of code is the basis for conducting experiments using experimental functions.
    '' When in a repeat loop, this code constantly checks the state of an input device.
    '' If anything has changed since the last time it checked, data is automatically recorded.
    '' In this way, the time of the onset and of the offset of every event can be recorded easily.
    exp.record(response.detect, response.ID, exp.time(start))                   ' Detect the state of the response device and record the state if it has changed.

    Contingencies                                                               ' Implements the contingencies method. Scroll down to read the code.

    '' This ends the main program loop. The loop will repeat until the session length is over, then drop down to the next line of code.

  '' The session has ended.
  if CS.state==OutOn                                                            ' If the CS is still occurring after the session ended.
    StopCS                                                                      ' Stop the CS.
  if US.state==OutOn                                                            ' If the US is still occurring after the session ended.
    StopUS                                                                      ' Stop the US.

  houselight.turnoff                                                            ' Turns off the house lights.
  exp.stopexperiment                                                            ' Stop the experiment. This line is needed before saving data.

  exp.preparedataoutput                                                         ' Prepares a data.cvs file.
  exp.savedata(response.ID,responsename)                                        ' Sorts through memory for all occurences of the response event and saves them to the data file.
  exp.savedata(CS.ID,CSname)                                                    ' Sorts through memory for all occurences of the CS event and saves them to the data file.
  exp.savedata(US.ID,USname)                                                    ' Sorts through memory for all occurences of the US event and saves them to the data file.

  exp.shutdown                                                                  ' Closes all the experiment code.

  dira[DiagnosticLEDPin]:=1                                                     ' Makes the diagnostic LED an output.
  repeat                                                                        ' The program enters an infinite repeat loop to keep the LED.
    !outa[DiagnosticLEDPin]                                                     ' Changes the state of the LED.
    waitcnt(clkfreq/10*5+cnt)                                                   ' Waits .5 seconds.
  ' When the LED starts flashing, it is safe to remove the SD card.

PUB SetVariables
  '' Sets up the experiment variables and events.

  responsename:=string("Response")                                              ' This sets the variable responsename to a string. Think of string as a "string of letters."
  CSname:=string("CS")                                                          ' The name of the CS.
  USname:=string("US")                                                          ' The name of the US.
  trial:=1                                                                      ' Note that the experiment starts with trial 1.

  '' The next lines use experimental event code to prepare the events.
  response.declareinput(responsepin,exp.clockID)                                ' This declares that the experimental event 'response' described in the OBJ section is an input on the response pin.
  CS.declareoutput(CSpin,exp.clockID)                                           ' This declares that the experimental event 'CS' described in the OBJ section is an output on the CS pin.
  US.declareoutput(USpin,exp.clockID)                                           ' This declares that the experimental event 'US' described in the OBJ section is an output on the US pin.
  houselight.declareoutput(houselightpin,exp.clockID)                           ' This declares that the experimental event 'houselight' described in the OBJ section is an output on the light pin.

PUB Contingencies
  '' The contingencies are implemented in a separate method to increase readability.
  '' Note that the contingencies method is run every program cycle, immediately after the response device is checked.

  if trial=<inhibitiontrials                                                    ' If it is a latent inhibition trial.
    CSPresentation                                                              ' Then only present the CS.

  elseif trial=<inhibitiontrials+acquisitiontrials                              ' If it is an acquisition trial.
    CSPresentation                                                              ' Present the CS.
    USPresentation                                                              ' Present the US.

  else                                                                          ' If it is an extinction trial.
    CSPresentation                                                              ' Present the CS.

  if exp.time(start)=>triallength*trial                                         ' If the current time is greater than the trial length times the current number of trials.
    trial:=trial+1                                                              ' Then it must be a new trial. Increment trial.

PUB CSPresentation
  '' Presents and removes the CS.

  if CS.state==OutOff and exp.time(start)=>CS_start+(triallength*(trial-1)) and exp.time(start)=<CS_stop+(triallength*(trial-1))    ' If the CS is off and the time is between the start and stop time.
    StartCS
  if CS.state==OutOn and exp.time(start)=>CS_stop+(triallength*(trial-1))                                                           ' If the CS is off and the time is between the start and stop time.
    StopCS

PUB USPresentation
  '' Presents and removes the US.

  if US.state==OutOff and exp.time(start)=>US_start+(triallength*(trial-1)) and exp.time(start)=<US_stop+(triallength*(trial-1))    ' If the US is off and the time is between the start and stop time.
    StartUS
  if US.state==OutOn and exp.time(start)=>US_stop+(triallength*(trial-1))                                                           ' If the US is off and the time is between the start and stop time.
    StopUS

PUB StartCS
  '' Turns on the CS, and records that the CS started.
  exp.record(CS.turnon, CS.ID, exp.time(start))

PUB StopCS
  '' Turns off the CS, and records that the CS stopped.
  exp.record(CS.turnoff, CS.ID, exp.time(start))

PUB StartUS
  '' Turns on the US, and records that the CS started.
  exp.record(US.turnon, US.ID, exp.time(start))

PUB StopUS
  '' Turns off the US, and records that the CS stopped.
  exp.record(US.turnoff, US.ID, exp.time(start))

DAT
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
