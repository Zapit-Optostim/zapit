# Change Log
Code was initially written by Maja Skretowska and Rob Campbell at the Sainsbury Wellcome Centre (UCL) in 2021/2022.
Early work was not version controlled.
Proof of principle was done by RC and this was developed into a functioning piece of code capable of running experiments by MS.
This in turn was converted into a polished project with a GUI by RC.

### Versioning Approach
The project largely adheres to [semantic versioning](http://semver.org) guidelines, meaning it has a version number denoted as `MAJOR.MINOR.PATCH`

* The MAJOR version is incremented when there are incompatible API changes, or changes in functionality which might carry important caveats. You should review the nature of a MAJOR verison change before upgrading a production system. An example of a MAJOR change might be that the API commands running the experiments change. 
* The MINOR version is incremented when functionality is added in a backwards compatible manner. This might mean significant new features that do not break existing functionality, or it might mean existing features are significantly improved. For example, addition of a rat atlas, or improviments in the way stimulus conditions are overlaid in the main GUI. 
* The PATCH version is incremented when there are backwards compatible bug fixes. It may also be incremented by the addition of new example code snippets, or by code changes which result in no functionality change. 

### Upgrade Notifications
The Zapit main window will print a notification in the title bar when a new version is available.


## Version History

### Beta Versions

2023/01/XX -- v0.9.0
 * Galvo waveforms are shaped to make them quieter: they are no almost inaudible even with the the galvo enclosure open.
 * Reset ROI disabled if field is full. Last ROI is re-applied on startup.
 * Laser rampdown time appears as a spinner in the stim config editor.
 * Update GUI with more buttons and tool-tips. Tidied it.
 * Validated that Zapit can correctly set laser power in mW. Tweaks so this works a little better. More work needed for calibration to be optimized and easy.
 * Button states are now linked via a listener.
 * Laser power calibration spinner removed. We use just the slider.
 * Add a current exposure setting for the camera.
 * Paint brain area onto brain.
 * Write trial log file if user has defined an experiment directory.
 * Standalone start of the stim config editor with zapit.stimConfigEditor


2023/01/19 -- v0.8.0-beta
 * Settings file updates with calibrate sample spinboxes
 * Switch to 1E5 samples/s and one cycle buffered. In stress test this went 1000 trials without a hitch.
 * Add settings and verify.
 * Bugfixes, including GUI locking up when stim config saved or loaded by the new tool.
 * Minimal DAQ examples with .NET and Vidrio.


### Alpha Versions

2023/01/16 -- v0.7.0-alpha
 * Substantial refactoring and renaming.
 * New format for stim config files.
 * UI elements that do not work in simulated mode are disabled.
 * A lot of documentation changes.
 * Functions to monitor for new version (partially working)
 * Update README


2023/01/12 -- v0.6.0-alpha
 * Move relevant methods into zapit.stimConfig
 * zapit.stimConfig.makeChanSamples is now turned into a getter of chanSamples
 * Recent files updates when files are missing. The list is cached and re-appears on reload.
 * Move vidrio wrapper into the project (thanks to Vidrio for granting permission).
 * Make a GUI to build stim config files. This is the last version that will use the existing stim config format!


2023/01/12 -- v0.5.1-alpha
 * Add the atlas_data.mat file to the code directory.


2023/01/12 -- v0.5.0-alpha
 * Convert the working units of everything from pixels to mm.
 * Sample calibration achieved by placing and scaling/rotating a brain outline.
 * Add ability to draw brain outline on sample with the beam.
 * stimConfig loading and recents menu works.
 * Add ability to do test presentations of the stimuli via the GUI.
 * Create an example showing how to use the API to present stimuli for fixed time periods.
 * Various bugfixes.


2023/01/05 -- v0.4.0-alpha
 * All UI elements in scanner calibration tab working as expected.
 * Improvements to startup and GUI.
 * Bugfixes.
 * Simulated mode partially working
 * Fix trivial bug that was causing scanner calibration transform to behave erratically. 
 * Begin work on sample calibration, including several demo files in the development directory. 


2022/12/21 -- v0.3.0-alpha
 * Have a working model/view/controller system. 
 * Basic GUI working.
 * Refactored everything up to the scanner calibration stage to the MVC system and GUI. 
 * The program can now be started by running `start_zapit`.


2022/12/19 -- v0.2.0-alpha
 * Add a system (partially working) for converting the control signal voltage to mW.
 * Code all now uses mW instead of a voltage value when setting laser power.


2022/12/19 -- v0.1.3-alpha
 * Major refactoring
 * The stopOptoStim method implements a rampdown
 * Fix bugs that were causing waveforms to not be what were expected
 * Laser is disabled for a fixed number of ms when location switching. Before it was 1 sample.


2022/12/15 -- v0.1.2-alpha
Minor bug fixes


2022/12/15 -- v0.1.1-alpha
Software is now refactored and likely working as intended bar the laser power. The laser
power was originally being set via an Arduino and there was no facility to specify a power
in mW. We next need to add the ability to set power in mW. The Arduino was being use to
implement a ramp-down following stim offset. We will now implement this via the NI DAQ.
Development now switches to the Dev branch.



