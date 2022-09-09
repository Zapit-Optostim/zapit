# zapit
Zaps brains with lasers



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
