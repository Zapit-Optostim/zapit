# Creating a TTL pulse

Hook up port0 line0 on your named Device to a scope and set time interval to 100 ms per div.
Volt scale to 1 V per division or greater. 
Run the following short example


```matlab
D = connectAuxDaq('Dev3'); % replace by your DAQ ID name
flipLine(D)

pause(2)

for ii=1:10
    flipLine(D)
end
```


If you hook up port0 lineo to PFI0 on your Zapit DAQ you will be able to trigger stimulation where `sendSamples` was set to be hardware triggered. 
