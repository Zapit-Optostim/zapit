# zapit
This software runs a scanning opto-stim system used to automatically point a beam at a series of brain areas.


## Install
The hardware has been tested with a Basler camera.
To communicate with the camera you will need to install the `Image Acquisition Toolbox Support Package for OS Generic Video Interface`.

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
laserObject = beamPointer;

% find transformation of pixel coords into voltage for scan mirrors
pointLog = laserObject.logPoints;
[tform, laserObject] = laserObject.runAffineTransform(pointLog);
```



### Legacy (?) Example
```
bp = beamPointer;
OUT = bp.logPoints(7) %scales laser to location in image##
bp.cam.src.Gain =1
load('C:\Maja\pulsepal_beta\fsm-behaviour-maja\scanner\areas1.mat')
bp.getAreaCoordinates(template)
bp.makeChanSamples(40, 0.36);
bp.createNewTask
bp.cam.src.Gain = 1;

%%
x = randi(6, 300, 1);
t = 0.5 + rand(1,300)*5.5;


%%
% loop 100 times
for ii = 1:300
    {'ii' 'x' 't' }
    [ii x(ii) t(ii) ]
    %
    bp.sendSamples(x(ii), 1);
    pause(t(ii));
    bp.hTask.stop;
    bp.sendSamples(x(ii), 0);
    pause(t(ii));
    bp.hTask.stop;
end

%%
% get order of inactivated areas
save('runningtest4', 'x', 't', 'bp');

```


