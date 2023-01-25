# zapit
[![View zapit on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://uk.mathworks.com/matlabcentral/fileexchange/122142-zapit)

This software runs a scanning opto-stim system used to automatically point a beam at a series of brain areas.
Code was initially written by Maja Skretowska and Rob Campbell at the Sainsbury Wellcome Centre (UCL) in 2021/2022.
The [Change Log](CHANGELOG.md) describes the project history and recent changes.

## How it works
A narrow collimated beam enters the scan head and is focused on the sample using a single scan lens.
The scan lens doubles as an objective and the sample is imaged onto a camera in order to visualise where the beam is pointing.
The software registered the scanners to the camera, allowing the user to place the beam in any desired location by clicking there on the live image feed.
The software also registers stereotaxic coordinates into the camera space, allowing the user to point the beam to coordinates defined with respect to bregma. 
A tool for building coordinate files for stimulation is provided. 
A simple API for integrating the stimulation into existing behavioral code is provided.


## Requirements
* [Image Processing Toolbox](https://www.mathworks.com/help/images/index.html)
* [Image Acquisition Toolbox](https://www.mathworks.com/products/image-acquisition.html)
* [Curve Fittting Toolbox](https://www.mathworks.com/help/curvefit/)
* [DAQmx](https://www.ni.com/en-gb/support/downloads/drivers/download.ni-daqmx.html). Supported versions: 19.0 to 21.8
* To communicate with the camera you will need to install [Basler's instructions for the GenICam interface](https://www.baslerweb.com/en/downloads/document-downloads/using-pylon-gentl-producers-for-basler-cameras-with-matlab/).
Although the Zapit system is tested against this, the goal is that it is able to handle other drivers and cameras also.
If you can not get the above to work, try installing the `Image Acquisition Toolbox Support Package for OS Generic Video Interface`.
If you run into errors when setting up with a driver other than GenICam, please file an Issue.


## Install & Usage
For install and user instructions please see the [documentation pages](https://zapit.gitbook.io/user-guide/).


## Contributing
Contributions and collaborations are welcome.
Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for more information.


## Acknowledgements
Thanks to Vidrio Technologies for allowing the inclusion of their DAQmx wrapper in this project.


## Related Projects
* [AllenAtlasTopDown](https://github.com/Zapit-Optostim/AllenAtlasTopDown)

