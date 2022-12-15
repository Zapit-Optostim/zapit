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