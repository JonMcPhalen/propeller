# Automobile ignition system simulator

By: yarisboy

Language: Spin

Created: Jul 7, 2011

Modified: June 17, 2013

The system uses the SpinStudio Propeller board system to generate a tachometer signal that has an RPM value proportional to the position of a pot. The pot voltage is converted to a count by MCP3208.spin. The ignition pulse is generated by Synth.spin. The PST is used to give the experimenter monitor information about the RPM and frequency the system is generating. It's a good tool for building speedometers, tachometers and such. the output is amplified to a 0-12 volt square wave for compatibility with common automotive tachometers.

http://www.youtube.com/watch?v=WagjDZzVKQ8