{{

┌────────────────────────────────────────────┐
│ Operant Discrimination                     │
│ Author: Christopher A Varnon               │
│ Created: 12-20-2012                        │
│ See end of file for terms of use.          │
└────────────────────────────────────────────┘

  This program provides a reinforcer for every response emitted in the presence of a discriminative stimulus (SD).
  Reinforcement is never provided in the presence of an S-Delta stimulus.
  Reinforcement is not provided if it is already available.

  The program randomly determines the order of the stimulus presentations.
  The program can also ensure that only a user-specified number of stimulus presentations of the same type can occur consecutively.
  For example, if the 5 stimulus presentations of each type are to be used, and a maximum of 3 consecutive stimulus presentations of the same type are allowed, the order will initially be randomly determined.
  Then, if the first four stimulus presentations are: 1. SD, 2. S-Delta, 3. S-Delta, 4, S-Delta; then the next stimulus presentation will always be SD so that 4 consecutive S-Delta presentations do not occur.
  Stimulus presentation 6 would then be randomly selected as normal.

  The user will need to specify the pins used for the response device, both stimuli, the reinforcement, the house lights, and the SD card.
  The user will also need to specify the duration of each stimulus presentation, the inter-stimulus interval, and the reinforcement.

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
  CS  = 3

  '' Replace the following values with whatever is desired for your experiment.
  '' Note that underscores are used in place of commas.
  '' The underscores are unnecessary and do not change the program, they only make the numbers easier to read.
  SDDuration            = 5_000                                                 ' The length of the SD presentation in milliseconds.
  S_DeltaDuration       = 5_000                                                 ' The length of the S-Delta presentation in milliseconds.
  TimeOut               = 500                                                   ' The length of the time out between stimulus presentations in milliseconds. Set to 0 if no time out is desired.
  StimulusPresentations = 10                                                    ' The number of times each stimulus is presented.
  ReinforcementLength   = 2_000                                                 ' The length of reinforcement in milliseconds.
  ConsecutiveLimit      = 3                                                     ' The maximum number of stimulus presentations of one type that can occur in a row.
                                                                                ' Until this number is reached, stimulus presentations will be determined randomly.
                                                                                ' After this number is reached, the next stimulus presentation will be intentionally selected to break the chain of the same stimulus presentation.
                                                                                ' Increase ConsecutiveLimit so that it exceeds the number of total stimulus presentations for a completely random selection.

  ' The session length is derived from the number and duration of the stimulus presentations, and the duration of the time out.
  SessionLength         = (SDDuration+S_DeltaDuration+(TimeOut*2))*StimulusPresentations

  '' Replace the following values with the pins connected to the devices.
  ResponsePin        = 6
  SDPin              = 18
  S_DeltaPin         = 19
  ReinforcementPin   = 23
  HouseLightPin      = 17                                                       ' The house lights will activate only while the experiment is running. Leave the pin disconnected if house lights control is not needed.
  DiagnosticLEDPin   = 16                                                       ' The LED will turn on after the experiment is complete and it is safe to remove the SD card. Leave the pin disconnected if a diagnostic LED is not needed.

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
  '' It is unlikely that an experiment will use the entire memory of the propeller chip.

  word ResponseName                                                             ' This variable will refer to the text description of the response event that will be saved to the data file.
  word SDName                                                                   ' This variable will refer to the text description of the SD event that will be saved to the data file.
  word S_DeltaName                                                              ' This variable will refer to the text description of the S-Delta event that will be saved to the data file.
  word ReinforcementName                                                        ' This variable will refer to the text description of the reinforcement event that will be saved to the data file.

  long Start                                                                    ' This variable will contain the starting time of the experiment. All other times will be compared to this time.
  long ReinforcementStart                                                       ' This variable will contain the starting time of each reinforcement. This is needed to know when to stop delivering the reinforcement.

  byte StimulusType                                                             ' This variable will refer to the type of stimulus presentation; 1 for SD presentations, 0 for S-Delta presentations.
  long StimulusStart                                                            ' This variable will note the time a stimulus presentation begins.
  byte ISI                                                                      ' This variable will note if a time out (an inter-stimulus interval) is occurring.

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
  SD            : "Experimental_Event"                                          ' Loads SD as an experimental event.
  S_Delta       : "Experimental_Event"                                          ' Loads S_Delta as an experimental event.
  Reinforcement : "Experimental_Event"                                          ' Loads reinforcement as an experimental event.
  HouseLight    : "Experimental_Event"                                          ' Loads houselight as an experimental event.

PUB Main
  '' The PUB or Public block is used to define code that can be used in a program or by other programs.
  '' The name listed after PUB is the name of the method.
  '' The program always starts with the first public method. Commonly this method is named "Main."
  '' The program will only run code in the first method unless it is explicitly told to go to another method.

  '' The statement "SetVariables" sets all the variables using a separate method. Scroll down to the SetVariables method to read the code.
  '' A separate method is not needed to set the variables, it can be done in the main method.
  '' However, dividing a program into sections can make it much easier to read.
  exp.startexperiment(DO,CLK,DI,CS)                                             ' Launches all the code in experimental functions related to timing and saving data. Also provides the SD card pins for saving data.
  SetVariables                                                                  ' Implements the setvariables method. Scroll down to read the code.
  houselight.turnon                                                             ' Turns on the house lights.
  start:=exp.time(0)                                                            ' Sets the variable 'start' to time(0) or the time since 0 - the present.
                                                                                ' In other words, the experiment started now.

  repeat until exp.time(start)>sessionlength                                    ' Repeats the indented code until time(start), or time since the experiment started, is greater than the session length.
                                                                                ' In other words, repeat until the session length has been reached.

    '' The next line of code is the basis for conducting experiments using experimental functions.
    '' When in a repeat loop, this code constantly checks the state of an input device.
    '' If anything has changed since the last time it checked, data is automatically recorded.
    '' In this way, the time of the onset and of the offset of every event can be recorded easily.
    exp.record(response.detect, response.ID, exp.time(start))                   ' Detect the state of the response device and record the state if it has changed.

    Contingencies                                                               ' Implements the contingencies method. Scroll down to read the code.

    '' This ends the main program loop. The loop will repeat until the session length is over, then drop down to the next line of code.

  '' The session has ended.
  if reinforcement.state==OutOn                                                 ' If the reinforcement is still occurring after the session ended.
    stopreinforcement                                                           ' Stop the reinforcement.
  if SD.state==OutOn                                                            ' If the SD is still occurring after the session ended.
    StopSD                                                                      ' Stop the SD.
  if S_Delta.state==OutOn                                                       ' If the S-Delta is still occurring after the session ended.
    StopS_Delta                                                                 ' Stop the S-Delta.

  houselight.turnoff                                                            ' Turns off the house lights.
  exp.stopexperiment                                                            ' Stop the experiment. This line is needed before saving data.

  exp.preparedataoutput                                                         ' Prepares a data.cvs file.
  exp.savedata(response.ID,responsename)                                        ' Sorts through memory for all occurrences of the response event and saves them to the data file.
  exp.savedata(SD.ID,SDname)                                                    ' Sorts through memory for all occurrences of the SD event and saves them to the data file.
  exp.savedata(S_Delta.ID,S_Deltaname)                                          ' Sorts through memory for all occurrences of the S-Delta event and saves them to the data file.
  exp.savedata(reinforcement.ID,reinforcementname)                              ' Sorts through memory for all occurrences of the reinforcement event and saves them to the data file.

  exp.shutdown                                                                  ' Closes all the experiment code.

  dira[DiagnosticLEDPin]:=1                                                     ' Makes the diagnostic LED an output.
  repeat                                                                        ' The program enters an infinite repeat loop to flash the LED.
    !outa[DiagnosticLEDPin]                                                     ' Changes the state of the LED.
    waitcnt(clkfreq/10*5+cnt)                                                   ' Waits .5 seconds.
  ' When the LED starts flashing, it is safe to remove the SD card.

PUB SetVariables
  '' Sets up the experiment variables and events.

  responsename:=string("Response")                                              ' This sets the variable responsename to a string. Think of string as a "string of letters."
  SDname:=string("SD")                                                          ' The name of the SD event.
  S_Deltaname:=string("S-Delta")                                                ' The Name of the S-Delta event.
  reinforcementname:=string("Reinforcement")                                    ' The name of the reinforcement event.

  exp.startrealrandom                                                           ' Activates the realrandom number generator to generate better random numbers.
  stimulustype:=exp.pseudorandom(ConsecutiveLimit)                              ' Randomly determines the first stimulus presentation.

  '' The following lines use experimental event code to prepare the events.
  response.declareinput(responsepin,exp.clockID)                                ' This declares that the experimental event 'response' described in the OBJ section is an input on the response pin.
  SD.declareoutput(SDpin,exp.clockID)                                           ' This declares that the experimental event 'SD' described in the OBJ section is an output on the SD pin.
  S_Delta.declareoutput(S_Deltapin,exp.clockID)                                 ' This declares that the experimental event 'S_Delta' described in the OBJ section is an output on the S_Delta pin.
  reinforcement.declareoutput(reinforcementpin,exp.clockID)                     ' This declares that the experimental event 'reinforcement' described in the OBJ section is an output on the reinforcement pin.
  houselight.declareoutput(houselightpin,exp.clockID)                           ' This declares that the experimental event 'houselight' described in the OBJ section is an output on the light pin.

PUB Contingencies
  '' The contingencies are implemented in a separate method to increase readability.
  '' Note that the contingencies method is run every program cycle, immediately after the response device is checked.

  if stimulustype==1 and ISI==0                                                 ' If it is an SD presentation and it is not currently an ISI.
    if SD.state==OutOff                                                         ' If the SD is off.
      stimulusstart:=exp.time(start)                                            ' Note the SD starts now.
      StartSD                                                                   ' Start the SD.
    if SD.State==OutOn and exp.time(stimulusstart)=>SDDuration                  ' If the SD is on and the duration for the stimulus has elapsed.
      StopSD                                                                    ' Stop the SD.
      ISI:=1                                                                    ' Note that an ISI is occurring.
      stimulusstart:=exp.time(start)                                            ' Note that the ISI starts now.
    if response.state==Onset and reinforcement.state==OutOff                    ' If the response device was just activated, and the reinforcement is off.
      StartReinforcement                                                        ' Reinforce. Scroll down to read the reinforce method code.

  if stimulustype==0 and ISI==0                                                 ' If it is an S-Delta presentation and it is not currently an ISI.
    if S_Delta.state==OutOff                                                    ' If the S-Delta is off.
      stimulusstart:=exp.time(start)                                            ' Note that the S-Delta starts now.
      StartS_Delta                                                              ' Start the S-Delta.
    if S_Delta.State==OutOn and exp.time(stimulusstart)=>S_DeltaDuration        ' If the S-Delta is on and the duration for the stimulus has elapsed.
      StopS_Delta                                                               ' Stop the S-Delta.
      ISI:=1                                                                    ' Note than an ISI is occurring.
      stimulusstart:=exp.time(start)                                            ' Note that the ISI starts now.

  if ISI==1 and exp.time(stimulusstart)=>TimeOut                                ' If it is currently a time out and the duration for the time out.
    SelectStimulusType                                                          ' Selects the next stimulus type. Scroll down to read the method.
    ISI:=0                                                                      ' Note the ISI is over.

  if reinforcement.state==OutOn and exp.time(reinforcementstart)=>reinforcementlength   ' If the reinforcement is on, and the reinforcement has been on for more than its maximum duration.
    Stopreinforcement                                                                   ' Stop the reinforcement. Scroll down to read the method.

PUB SelectStimulusType
  '' This method randomly selects a new stimulus type.
  '' If one stimulus type has already reached the maximum number of presentations, the opposite type will be selected.

  if SD.count==StimulusPresentations                                            ' If the SD has already been selected the maximum amount of times.
    stimulustype:=0                                                             ' The next stimulus presentation is an S_Delta.
  elseif S_Delta.count==StimulusPresentations                                   ' If the S-Delta has already been selected the maximum amount of times.
    stimulustype:=1                                                             ' The next stimulus presentation is an SD.
  else                                                                          ' In any other case.
    stimulustype:=exp.pseudorandom(ConsecutiveLimit)                            ' Randomly determine the next stimulus presentation.

PUB StartReinforcement
  '' This method provides reinforcement, and records the onset of reinforcement.

  exp.record(reinforcement.turnon, reinforcement.ID, exp.time(start))           ' Starts and records the reinforcement.
  reinforcementstart:=exp.time(start)                                           ' Notes that reinforcement started now.

PUB StopReinforcement
  '' This method ends the reinforcement, and records the offset of reinforcement.

  exp.record(reinforcement.turnoff, reinforcement.ID, exp.time(start))          ' Stops and records the reinforcement.

PUB StartSD
  '' This method provides reinforcement, and records the onset of reinforcement.

  exp.record(SD.turnon, SD.ID, exp.time(start))                                 ' Starts and records the SD.

PUB StopSD
  '' This method ends the reinforcement, and records the offset of reinforcement.

  exp.record(SD.turnoff, SD.ID, exp.time(start))                                ' Stops and records the SD.

PUB StartS_Delta
  '' This method provides reinforcement, and records the onset of reinforcement.

  exp.record(S_Delta.turnon, S_Delta.ID, exp.time(start))                       ' Starts and records the S-Delta.

PUB StopS_Delta
  '' This method ends the reinforcement, and records the offset of reinforcement.

  exp.record(S_Delta.turnoff, S_Delta.ID, exp.time(start))                      ' Stops and records the S-Delta.

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
