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
A tool for building cooridnate files for stimulation is provided. 
A simple API for integrating the stimulation into existing behavioral code is provided.


## Current status
* Expected API and feature freeze: end January 2022

## Requirements
* [Image Processing Toolbox](https://www.mathworks.com/help/images/index.html)
* [Image Acquisition Toolbox](https://www.mathworks.com/products/image-acquisition.html)
* [Curve Fittting Toolbox](https://www.mathworks.com/help/curvefit/)
* [DAQmx](https://www.ni.com/en-gb/support/downloads/drivers/download.ni-daqmx.html). Supported versions: 19.0 to 21.8
* To communicate with the camera you will need to install [Basler's instructions for the GenICam interface](https://www.baslerweb.com/en/downloads/document-downloads/using-pylon-gentl-producers-for-basler-cameras-with-matlab/).
Although the Zapit system is tested against this, the goal is that it is able to handle other drivers and cameras also.
If you can not get the above to work, try installing the `Image Acquisition Toolbox Support Package for OS Generic Video Interface`.
If you run into errors when setting up with a driver other than GenICam, please file an Issue.


## Install
Gather and install the above requirements then install Zapit in one of the following ways:
* *Via MATLAB*: Go to the **Apps** ribbon in MATLAB and click on **Get More Apps**. Search for Zapit and add it to MATLAB. You can also update Zapit via this route.
* *Via your browser*: Navigate to the [Zapit File Exchange page](https://uk.mathworks.com/matlabcentral/fileexchange/122142-zapit). Download. Unpack in a reasonable place. Add the Zapit `code` directory to your path. You need add only this directory, not it and all sub-directories.
* *Via Git*: Clone in your favourite Git client. Add the Zapit `zapit` directory (that which contains `start_zapit.m`) to your path. You need add only this directory, not it and all sub-directories.


### First time you run
Instructions for first time setup are found in [SETTING_UP.md](SETTING_UP.md).


### Start beam pointer and calibrate
Start the software
```
start_zapit
```

* The GUI appears with a live view of the sample. 
* Focus and turn on the laser. 
* Press "Calibrate Scanners" on the first tab. Check the calibration with other buttons.
* Press "Calibrate Sample" on the second tab. Place brain outline on bregma. Click the second coordinate. 
* Use the File menu to load or create then load a Sample Config file. 
* Test it wite the other buttons on the Calibrate Sample tab. 



### Using the API
The MATLAB workspace contains a variable called `hZP`. 
This is an API (Application Programming Interface) that allows controlling of almost all functions via the command line. 
The following code, for example, will send samples to the DAQ to stimulate one condition (e.g. one brain area bilaterally).

```
newTrial = struct('area', 1, 'LaserOn', 1); % first brain area on the list
hZP.sendSamples(newTrial)
```
It is now stimulating.
To stop it gracefully run:
```
hZP.stopOptoStim
```

Randomly stimulate each brain area once for 0.5 seconds before moving onto the next.
```
newTrial.LaserOn = 1;
newTrial.powerOption = 1;

numAreasToStim = length(hZP.stimConfig.stimLocations);
areas = randperm(numAreasToStim);

for ii=1:numAreasToStim
    newTrial.area = areas(ii);
    hZP.sendSamples(newTrial,true) % True for verbose
    pause(0.5)

    hZP.stopOptoStim
end

```

## Contributing
Contributions and collaborations are welcome.
Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for more information.


## Acknowledgements
Thanks to Vidrio Technologies for allowing the inclusion of their DAQmx wrapper in this project.


## Related Projects
* [AllenAtlasTopDown](https://github.com/raacampbell/AllenAtlasTopDown)

