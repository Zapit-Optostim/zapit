# zapit
[![View zapit on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://uk.mathworks.com/matlabcentral/fileexchange/122142-zapit)

This software runs a scanning opto-stim system used to automatically point a beam at a series of brain areas.
Code was initially written by Maja Skretowska and Rob Campbell at the Sainsbury Wellcome Centre (UCL) in 2021/2022.

The code runs a simple galvo-based photo-stimulator.
A narrow collimated beam enters the scan head and is focused on the sample using a single scan lens.
The scan lens doubles as an objective, as the sample is imaged onto a camera in order to visualise where the beam is pointing.
The [Change Log](CHANGELOG.md) describes the project history and recent changes.

## Status as of December 2022
* The project is currently under heavy development but has basic functionality and in theory could be used to run experiments right now.
* Expected API freeze: end January 2022


## Requirements
* [Image Processing Toolbox](https://www.mathworks.com/help/images/index.html)
* [Image Acquisition Toolbox](https://www.mathworks.com/products/image-acquisition.html)
* [Curve Fittting Toolbox](https://www.mathworks.com/help/curvefit/)
* [The free version of ScanImage](https://vidriotechnologies.com/) because Zapit uses its DAQmx wrapper (but see [here](https://github.com/BaselLaserMouse/zapit/issues/14)). You need add to the path the base ScanImage directory. No need to add to path with all sub-directories.
* To communicate with the camera you will need to install [Basler's instructions for the GenICam interface](https://www.baslerweb.com/en/downloads/document-downloads/using-pylon-gentl-producers-for-basler-cameras-with-matlab/).
Although the Zapit system is tested against this, the goal is that it is able to handle other drivers and cameras also.
If you can not get the above to work, try installing the `Image Acquisition Toolbox Support Package for OS Generic Video Interface`.
If you run into errors when setting up with a driver other than GenICam, please file an Issue.


## Install
Gather and install the above requirements then install Zapit in one of the following ways:
* *Via MATLAB*: Go to the **Apps** ribbon in MATLAB and click on **Get More Apps**. Search for Zapit and add it to MATLAB. You can also update Zapit via this route.
* *Via your browser*: Navigate to the [Zapit File Exchange page](https://uk.mathworks.com/matlabcentral/fileexchange/122142-zapit). Download. Unpack in a reasonable place. Add the Zapit `code` directory to your path. You need add only this directory, not it and all sub-directories.
* *Via Git*: Clone in your favourite Git client. Add the Zapit `code` directory to your path. You need add only this directory, not it and all sub-directories.


### First time you run
You will need to ensure the system can talk to the camera:
```
>> D = zapit.testCamera
1  -  videoinput('winvideo', 1, 'Y800_1024x768')
2  -  videoinput('winvideo', 1, 'Y800_1280x960')
3  -  videoinput('winvideo', 1, 'Y800_1600x1200')
4  -  videoinput('winvideo', 1, 'Y800_160x120')
5  -  videoinput('winvideo', 1, 'Y800_1928x1208')
6  -  videoinput('winvideo', 1, 'Y800_320x240')
7  -  videoinput('winvideo', 1, 'Y800_40x30')
8  -  videoinput('winvideo', 1, 'Y800_640x480')
9  -  videoinput('winvideo', 1, 'Y800_720x480')
10  -  videoinput('winvideo', 1, 'Y800_720x576')
11  -  videoinput('winvideo', 1, 'Y800_800x600')
12  -  videoinput('winvideo', 1, 'Y800_80x60')

Enter device number and press return:
```

Choose the resolution you would like.
You can select it again in future without the interactive selector by doing:


```
>>D = zapit.testCamera(3)
Available interfaces:
1  -  videoinput('winvideo', 1, 'Y800_1024x768')
2  -  videoinput('winvideo', 1, 'Y800_1280x960')
3  -  videoinput('winvideo', 1, 'Y800_1600x1200')
4  -  videoinput('winvideo', 1, 'Y800_160x120')
5  -  videoinput('winvideo', 1, 'Y800_1928x1208')
6  -  videoinput('winvideo', 1, 'Y800_320x240')
7  -  videoinput('winvideo', 1, 'Y800_40x30')
8  -  videoinput('winvideo', 1, 'Y800_640x480')
9  -  videoinput('winvideo', 1, 'Y800_720x480')
10  -  videoinput('winvideo', 1, 'Y800_720x576')
11  -  videoinput('winvideo', 1, 'Y800_800x600')
12  -  videoinput('winvideo', 1, 'Y800_80x60')

Connecting to number 3

D =

  testCamera with properties:

          cam: [1×1 zapit.camera]
    lastFrame: []

```

This connects to the camera and brings up a live feed.
You can change camera settings as follows:

```
>> D.cam.stopVideo
>> D.cam.src.Exposure

ans =

  int32

   -4

>> D.cam.src.Exposure=-10;
>> D.cam.startVideo
```

Closing the figure will also disconnect from the camera, as will `delete(D)`



### Start beam pointer and calibrate

Start the software and select a config file.
```
P = zapit.pointer;
```

Now you need to determine the transform between pixel coordinates and the scan mirrors.
```
P.calibrateScanners;
```

You can now click on the image and the beam should go to that location.


### Calibrate to mouse skull
Now you can tell the system where is Bregma and another reference location.
This method call populates the `chanSamples` property.
% TODO -- this no longer works <<---- [11/01/23]
```
P.calibrateSample
```

### Generate the parameters for switching the beam
Prepare the waveforms that will be used for each brain area (stimulation site).
Here we are stimulating with laser power at the sample of 10 mW.
```
P.stimConfig.laserPowerInMW = 10;
```

### Let's run it!
The following code will send samples to the DAQ to stimulate one brain area bilaterally.

```
newTrial.area = 1; % first brain area on the list
newTrial.LaserOn = 1;
newTrial.powerOption = 1; % if 1 send 2 mW, if 2 send 4 mW (mean)

P.sendSamples(newTrial)
```
To stop it gracefully run:
```
P.stopOptoStim
```

Randomly stimulate each brain area once for 0.5 seconds before moving onto the next.
```
newTrial.LaserOn = 1;
newTrial.powerOption = 1;

numAreasToStim = size(P.chanSamples.scan,3);
areas = randperm(numAreasToStim);

for ii=1:numAreasToStim
    newTrial.area = areas(ii);
    P.sendSamples(newTrial,true) % True for verbose
    pause(0.5)

    % TODO -- we have a better stop method coming that will also deal with the laser rampdown
    P.DAQ.stop
    P.DAQ.setLaserPowerControlVoltage(0)
end

```

## Contributing
Contributions and collaborations are welcome.
Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for more information.

