# zapit
This software runs a scanning opto-stim system used to automatically point a beam at a series of brain areas.
Code was initially written by Maja Skretowska and Rob Campbell at the Sainsbury Wellcome Centre (UCL) in 2021/2022.

The code runs a simple galvo-based photo-stimulator.
A narrow collimated beam enters the scan head and is focused on the sample using a single scan lens.
The scan lens doubles as an objective, as the sample is imaged onto a camera in order to visualise where the beam is pointing.


## Requirements
* [Image Processing Toolbox](https://uk.mathworks.com/help/images/index.html)
* [Image Acquisition Toolbox](https://uk.mathworks.com/products/image-acquisition.html)
* [The free version of ScanImage](https://vidriotechnologies.com/) because Zapit uses its DAQmx wrapper (but see [here](https://github.com/BaselLaserMouse/zapit/issues/14)).
* To communicate with the camera you will need to install [Basler's instructions for the GenICam interface](https://www.baslerweb.com/en/downloads/document-downloads/using-pylon-gentl-producers-for-basler-cameras-with-matlab/).
Although the Zapit system is tested against this, the goal is that it is able to handle other drivers and cameras also.
If you can not get the above to work, try installing the `Image Acquisition Toolbox Support Package for OS Generic Video Interface`.
If you run into errors when setting up with a driver other than GenICam, please file an Issue.


## Install
Gather the requirements then add to your path:
* The Zapit `code` directory. You need add only this directory, not it and all sub-directories.
* The ScanImage directory. You need add only this directory, not it and all sub-directories.


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

```
P = zapit.pointer;

% find transformation of pixel coords into voltage for scan mirrors
P.logPoints;

```
You can now click on the image and the beam should go to that location.


### Calibrate to mouse skull
Now you can tell the system where is Bregma and another reference location
```
P.getAreaCoordinates
```

### Generate the parameters for switching the beam
Here we are switching at 40 Hz with a laser amplitude of 0.36
```
P.makeChanSamples(40, 0.36);
```

### Set up NI task for the stimulation
```
P.createNewTask %% TODO - should run this in sendSamples
```


### Let's run it
For one brain area

```
newTrial.area = 4; % first brain area on the list
newTrial.LaserOn = 1;
newTrial.powerOption = 1; % if 1 send 2 mW, if 2 send 4 mW (mean)

P.sendSamples(newTrial)
```


```
P.cam.src.Gain = 1;

%%
x = randi(6, 300, 1);
t = 0.5 + rand(1,300)*5.5;


%%
% loop 100 times
for ii = 1:300
    {'ii' 'x' 't' }
    [ii x(ii) t(ii) ]
    %
    P.sendSamples(x(ii), 1);
    pause(t(ii));
    P.hTask.stop;
    P.sendSamples(x(ii), 0);
    pause(t(ii));
    P.hTask.stop;
end

%%
% get order of inactivated areas
save('runningtest4', 'x', 't', 'P');

```


