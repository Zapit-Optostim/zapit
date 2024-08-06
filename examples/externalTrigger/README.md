# What is external (hardware) triggering?
You can trigger DAQ events such as analog output waveforms based upon a software trigger. 
In this scenario, the waveform begins immediately after executing a line of code. 
This works perfectly well for many applications, but the precise onset time of the waveform is not defined. 
The waveform will start after a short lag (perhaps tens of ms), which will vary slightly from trial to trial. 
For many experimental scenarios this is OK, however you might want the stimulation to occur immediately following an external event. 
For example, licking of a spout. 
In this situation you can use an external hardware trigger. 
This is achieved as follows:
1. You connect a named trigger source (e.g. a lick port) to a trigger input (e.g. PFI0 on your DAQ).
2. Waveforms are sent to the DAQ but the DAQ is instructed to wait for a trigger on the defined trigger line (PFI0).
3. Once a trigger is received at PFI0 the waveforms are played near instantly with no delay or jitter. 

# Generating a TTL pulse
This example shows how to generate a TTL pulse that can be used to trigger something. 
Hook up port0 line0 on your named Device to a scope and set time interval to 100 ms per div.
Volt scale to 1 V per division or greater. 

Run the following command to set up digital ouput on port0 line 0.

```matlab
D = connectAuxDaq('Dev3'); % replace by your DAQ ID name
```

The variable `D` is an object (i.e. an instance of class) that represents the digital line of the DAQ. 
You can set this line to be high (+5V) and low (0V). 
Running the command `makeTTLpulse(D)` will make this line go low -> high -> low very briefly. 
You can see this on your scope. 
You might have to trigger the acquisition on the scopee to see the pulse easily. 
For demo purposes you can make a train of 5 pulses like this:

```matlab
for ii=1:5
    makeTTLpulse(D)
    pause(0.05)
end
```


If you hook up port0 line0 to PFI0 on your Zapit DAQ you will be able to trigger stimulation where `sendSamples` was set to be hardware triggered using `makeTTLpulse(D)`. 
A only single TTL pulse should be used.  

# When to use external triggering
External triggering is needed if you wish to initiate stimuli precisely following an event that generates (or can generate) a trigger pulse. 
This could be a piece of experimental aparatus that indicates a change of state in the world with a TTL pulse, or it could be a control PC that initiates a TTL pulse when it starts recording data. 
On the other hand, it would be reseaonable to simply use software tiggering if you, for example, want to present a 1 second photostimulus once every 1 minute. 
Zapit's `sendSamples` command allows stimuli to have a precise duration regardless of the trigger source. 
