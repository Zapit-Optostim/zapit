# Camera class


## Usage examples

### Setting the ROI
```
>> C.ROI  % Show the full sensor size

ans =

           0           0        1936        1216

% Crop the stream (the camera is stopped and restarted if needed)
>> C.ROI = [300,100,1400,1000];

% Reset to full size
>> C.resetROI
```
