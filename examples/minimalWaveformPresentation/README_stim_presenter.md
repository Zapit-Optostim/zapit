# Stim Presenter Examples

Classes in this folder demonstrate how to present photostimulation waveforms using NI DAQmx.
These examples are aimed at developers wishing to implement this aspect of the code in a different programming language.


For Python you do not need to do this as there is a [Zapit to Python bridge](https://github.com/Zapit-Optostim/zapit-Python-Bridge) that uses shared memory. 
This way you can `pip install zapit-python-bridge` and communicate with Zapit directly.
There is little to be achieved by reimplementing the stimulus presentation code in Python as the MATLAB GUI needs to be running on the same machine anyway.

