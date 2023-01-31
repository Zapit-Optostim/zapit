# Hardware Classes

This module contains classes for interacting with the camera and the NI DAQ.

There are two classes for the DAQ. They are both wrappers for DAQmx:
* `vidriowrapper` is the code used in ScanImage. It was taken from ScanImage 2022 with kind permission of Vidrio Technologies. It supports DAQmx v19.0 to v21.8
* `dotNetWrapper` is a slightly more direct approach, exposing DAQmx using .NET. This is the default.

Both approaches work and seem to work equally well. The was initially written using Vidrio's wrapper
but was switched to .NET because there are a lot of warning messages at the CLI during the ramp-down
using Vidrio's wrapper. It also seemed easier to find USB-related properties with .NET. Both wrappers
are included just in case there is a need to switch to Vidrio in the future.

## Acknowledgements
Thanks to Vidrio Technologies for allowing the inclusion of their DAQmx wrapper in this project.
