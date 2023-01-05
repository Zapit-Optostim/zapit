# Change Log
Code was initially written by Maja Skretowska and Rob Campbell at the Sainsbury Wellcome Centre (UCL) in 2021/2022.
Early work was not well version controlled.
Proof of principle work was done by RC (e.g. 33b2f092ab0da50f6d4320a7a07c64ac436765a7) and this was developed into a functioning piece of code capable of running experiments by MS (45e81e44b49a24efbe6d30964430a3c8221712ec)
In Q3 2022 it became obvious the project worked well and a mature package was needed. 
RC started work on this (68b502c6ff718496d2ae618ffb2c623a5e06c1b7) and by Q4 2022 a fairly clear structure had emerged for the core package (2f760e4651e6e8c98661a5974a217fc0414a2539) although the form of the GUI is not clear yet. 

This document describes significant code changes. 
During early development (versions tagged with alpha in zapit.version) there will be little documentation here. 
Once the system matures this document will be strictly updated and the versioning will be incremented properly.
The project will adhere to [semantic versioning](http://semver.org) guidelines, meaning it has a version number denoted as `MAJOR.MINOR.PATCH`

* MAJOR version when you make incompatible API changes
* MINOR version when you add functionality in a backwards compatible manner
* PATCH version when you make backwards compatible bug fixes


2023/01/05 -- v0.4.0-alpha
 * All UI elements in scanner calibration tab working as expected.
 * Improvements to startup and GUI.
 * Bugfixes.
 * Simulated mode partially working
 * Fix trivial bug that was causing scanner calibration transform to behave erratically. 
 * Begin work on sample calibration, including several demo files in the development directory. 


2022/12/21 -- v0.3.0-alpha
 * Have a working model/view/controller system. 
 * Basic GUI working.
 * Refactored everything up to the scanner calibration stage to the MVC system and GUI. 
 * The program can now be started by running `start_zapit`.


2022/12/19 -- v0.2.0-alpha
 * Add a system (partially working) for converting the control signal voltage to mW.
 * Code all now uses mW instead of a voltage value when setting laser power.


2022/12/19 -- v0.1.3-alpha
 * Major refactoring
 * The stopOptoStim method implements a rampdown
 * Fix bugs that were causing waveforms to not be what were expected
 * Laser is disabled for a fixed number of ms when location switching. Before it was 1 sample.


2022/12/15 -- v0.1.2-alpha
Minor bug fixes


2022/12/15 -- v0.1.1-alpha
Software is now refactored and likely working as intended bar the laser power. The laser
power was originally being set via an Arduino and there was no facility to specify a power
in mW. We next need to add the ability to set power in mW. The Arduino was being use to
implement a ramp-down following stim offset. We will now implement this via the NI DAQ.
Development now switches to the Dev branch.



