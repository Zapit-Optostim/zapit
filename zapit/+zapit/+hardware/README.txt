# Hardware Classes

This module contains classes for interacting with the camera and the NI DAQ.

There are two classes for the DAQ. They are both wrappers for DAQmx:
* `vidriowrapper` is the code used in ScanImage. It was taken from ScanImage 2022 with kind permission of Vidrio Technologies. It supports DAQmx v19.0 to v21.8
* `dotNetWrapper` is a slightly more direct approach, exposing DAQmx using .NET. This is the default.

## NOTE!!!
Although both approaches work and seem to work equally well, Zapit was initially written
using Vidrio's wrapper but was switched to .NET because there are a lot of warning messages
at the CLI during the ramp-down using Vidrio's wrapper. It also seemed easier to find
USB-related properties with .NET. Both wrappers are included just in case there is a need
to switch to Vidrio in the future. **HOWEVER** `vidriowrapper` is no longer being actively
maintained. So there are new features starting from v0.13.0 that are in `dotNetWrapper` only.
The ability to present stimuli of a fixed duration is in this wrapper only. Likely the code
will error if `vidriowrapper` is selected. We leave it there for now anyway, in case it is
useful for educational purposes or in case we want to go back to it.

## Acknowledgements
Thanks to Vidrio Technologies for allowing the inclusion of their DAQmx wrapper in this project.
